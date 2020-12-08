defmodule Pigeon.Rooms.Room do
  use GenServer
  alias Pigeon.Message

  def start_link(init_args) do
    IO.puts("Starting room with args #{inspect(init_args)}")
    state = build_state(init_args)
    IO.puts(inspect(state))
    {_, name, _} = init_args
    {:ok, pid} = GenServer.start_link(__MODULE__, state, name: name)
    GenServer.cast(pid, {:start_backups})
    {:ok, pid}
  end

  def create_room(user, name, type) do
    {:ok, pid} =
      Swarm.register_name(name, Pigeon.Room.Supervisor, :register, [{user, name, type}])

    Swarm.join(:rooms, pid)
    {:ok, pid}
  end

  @impl true
  def init(state) do
    IO.puts("INIT room")

    {:ok, state}
  end

  defp build_state({owner, name, :group}) do
    %{users: [owner], messages: [], type: :group, admins: [owner], name: name}
  end

  defp build_state({{user_1, user_2}, name, type}) do
    IO.puts("Build state")
    %{users: [user_1, user_2], messages: [], type: type, admins: [], name: name}
  end

  def create_message(pid, text, ttl, sender) do
    GenServer.call(
      {:via, :swarm, pid},
      {:create_message, %{text: text, ttl: ttl, sender: sender}}
    )
  end

  def list_messages(pid) do
    GenServer.call({:via, :swarm, pid}, {:list_messages})
  end

  def update_message(pid, message_id, text, sender) do
    GenServer.call(
      {:via, :swarm, pid},
      {:update_message, message_id, %{text: text, sender: sender}}
    )
  end

  def delete_message(pid, message_id) do
    GenServer.cast(pid, {:delete_message, message_id})
  end

  def delete_message(pid, message_id, sender) do
    GenServer.call({:via, :swarm, pid}, {:delete_message, {message_id, sender}})
  end

  def add_user(pid, admin, user) do
    GenServer.call({:via, :swarm, pid}, {:add_user, admin, user})
  end

  def join_room(pid, user) do
    GenServer.call({:via, :swarm, pid}, {:join_room, user})
  end

  def remove_user(pid, {user, sender}) do
    GenServer.call({:via, :swarm, pid}, {:remove_user, user, sender})
  end

  def get_user_info(pid, user) do
    GenServer.call({:via, :swarm, pid}, {:get_user_info, user})
  end

  def upgrade_user(pid, {user, sender}) do
    GenServer.call({:via, :swarm, pid}, {:upgrade_user, user, sender})
  end

  @impl true
  def handle_cast({:start_backups}, state) do
    IO.puts("Start Backup")

    names = backups_names(state)

    backup =
      names |> Enum.find(fn back -> Swarm.whereis_name(back) != :undefined end)

    IO.puts(inspect(backup))

    to_return =
      if backup == nil do
        for backup_name <- names do
          {:ok, pid} =
            Swarm.register_name(backup_name, Pigeon.RoomState.Supervisor, :register, [
              {backup_name, state}
            ])

          IO.puts(inspect(pid))
          Swarm.join(:backups, pid)
        end

        state
      else
        Pigeon.RoomState.get_state(backup)
      end

    IO.puts(inspect(to_return))

    {:noreply, to_return}
  end

  @impl true
  def handle_call({:list_messages}, _from, state) do
    {:reply, state.messages, state}
  end

  @impl true
  def handle_call({:get_user_info, user}, _from, state) do
    cond do
      Enum.member?(state.admins, user) -> {:reply, {:ok, "admin"}, state}
      Enum.member?(state.users, user) -> {:reply, {:ok, "user"}, state}
      true -> {:reply, {:error, :not_found}, state}
    end
  end

  defp update_backup(to_reply) do
    {_, _, state} = to_reply
    for backup <- backups_names(state) do
      Pigeon.RoomState.set_state(backup, state)
    end
    to_reply
  end

  @impl true
  def handle_call({:join_room, user}, _from, state) do
    users = [user | state.users]

    to_reply =
      if Pigeon.Rooms.Join.can_join(state.type, users) do
        {:reply, "Ha sido agregado a la sala", %{state | users: users}}
      else
        {:reply, "No ha sido agregado a la sala", state}
      end

    update_backup(to_reply)
  end

  @impl true
  def handle_call({:add_user, admin, user}, _from, state) do
    users = [user | state.users]

    if is_admin?(admin, state.admins) && Pigeon.Rooms.Join.can_join(state.type, users) do
      {:reply, "Ha sido agregado a la sala", %{state | users: users}}
    else
      {:reply, "No ha sido agregado a la sala", state}
    end
  end

  @impl true
  def handle_call({:create_message, %{text: text, ttl: ttl, sender: sender}}, _from, state) do
    IO.puts("Creating message on room #{inspect(self())}")
    new_message = Message.build(text, sender)

    Pigeon.Rooms.MessageCleaner.schedule_clean(state.type, self(), new_message.id, ttl)

    for user <- state.users do
      Pigeon.UserRegistry.broadcast_message(user, text)
    end

    to_reply = {:reply, {:ok, new_message}, %{state | messages: [new_message | state.messages]}}
    update_backup(to_reply)
  end

  @impl true
  def handle_call({:update_message, id, %{text: text, sender: sender}}, _from, state) do
    new_messages =
      Enum.map(state.messages, fn message ->
        if message.id == id, do: Message.set_text(message, text), else: message

        if message.id == id && message.sender_pid == sender,
          do: Message.set_text(message, text),
          else: message
      end)

    to_reply = {:reply, {:ok}, %{state | messages: new_messages}}
    update_backup(to_reply)
  end

  @impl true
  def handle_call({:delete_message, {message_id, sender}}, _from, state) do
    index = Enum.find_index(state.messages, fn message -> message.id == message_id end)
    message = Enum.at(state.messages, index)

    to_reply =
      case message do
        %Message{sender_pid: ^sender} -> delete_message_by_index(state, index)
        nil -> {:reply, {:error, :not_found}, state}
        _ -> as_admin(sender, state, fn -> delete_message_by_index(state, index) end)
      end

    update_backup(to_reply)
  end

  @impl true
  def handle_call({:upgrade_user, user, sender}, _from, state) do
    as_admin(sender, state, fn ->
      newAdmins = [user | state.admins]

      IO.puts(inspect(newAdmins))

      to_reply = {:reply, {:ok}, %{state | admins: newAdmins}}
      update_backup(to_reply)
    end)
  end

  @impl true
  def handle_call({:remove_user, user, sender}, _from, state) do
    as_admin(sender, state, fn ->
      newUsers = Enum.reject(state.users, fn u -> u == user end)
      newAdmins = Enum.reject(state.admins, fn u -> u == user end)

      IO.puts(inspect(newUsers))
      IO.puts(inspect(newAdmins))
      to_reply = {:reply, {:ok}, %{state | users: newUsers, admins: newAdmins}}
      update_backup(to_reply)
    end)
  end

  @impl true
  def handle_cast({:delete_message, message_id}, state) do
    new_messages = Enum.filter(state.messages, &(&1.id != message_id))
    {:noreply, %{state | messages: new_messages}}
  end

  @impl true
  def handle_info({:delete_message, message_id}, state) do
    IO.puts("Deleting #{message_id}")

    delete_message(self(), message_id)
    {:noreply, state}
  end

  defp is_admin?(who, admins), do: Enum.member?(admins, who)

  defp as_admin(user, state, action) do
    if is_admin?(user, state.users) do
      action.()
    else
      {:reply, {:error, :forbidden}, state}
    end
  end

  defp delete_message_by_index(state, index) do
    {:reply, {:ok}, %{state | messages: List.delete_at(state.messages, index)}}
  end

  defp backups_names(state) do
    [state.name]
    |> Stream.cycle
    |> Stream.zip(1..2)
    |> Enum.map(fn {name, index} -> :"backups:#{name}:#{index}" end)
  end
end
