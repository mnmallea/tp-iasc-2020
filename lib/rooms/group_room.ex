defmodule Pigeon.Rooms.GroupRoom do
  use GenServer
  alias Pigeon.Message

  def start_link(%{owner: owner, name: name}) do
    GenServer.start_link(__MODULE__, %{users: %{owner => %{role: "admin"}}, messages: []},
      name: name
    )
  end

  def create_room(user, name) do
    {:ok, pid} = start_link(%{owner: user, name: name})
    pid
  end

  def create_message(pid, {text, sender}) do
    GenServer.call(pid, {:create_message, %{text: text}, sender})
  end

  def list_messages(pid) do
    GenServer.call(pid, {:list_messages})
  end

  def update_message(pid, {message_id, text, sender}) do
    GenServer.call(pid, {:update_message, message_id, %{text: text}, sender})
  end

  def delete_message(pid, {message_id, sender}) do
    GenServer.call(pid, {:delete_message, message_id, sender})
  end

  def add_user(pid, {user, sender}) do
    GenServer.call(pid, {:add_user, user, sender})
  end

  def remove_user(pid, {user, sender}) do
    GenServer.call(pid, {:remove_user, user, sender})
  end

  def get_user_info(pid, user) do
    GenServer.call(pid, {:get_user_info, user})
  end

  def upgrade_user(pid, {user, sender}) do
    GenServer.call(pid, {:upgrade_user, user, sender})
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_call({:get_user_info, user}, _from, state) do
    case state.users[user] do
      nil -> {:reply, {:error, :not_found}, state}
      user_data -> {:reply, {:ok, user_data}, state}
    end
  end

  @impl true
  def handle_call({:list_messages}, _from, state) do
    {:reply, state.messages, state}
  end

  @impl true
  def handle_call({:create_message, %{text: text}, sender}, _from, state) do
    new_message = Message.build(text, sender)
    broadcast_message(state, new_message)
    {:reply, {:ok, new_message}, %{state | messages: [new_message | state.messages]}}
  end

  @impl true
  def handle_call({:delete_message, message_id, sender}, _from, state) do
    index = Enum.find_index(state.messages, fn message -> message.id == message_id end)
    message = Enum.at(state.messages, index)

    case message do
      %Message{sender_pid: ^sender} -> delete_message_by_index(state, index)
      nil -> {:reply, {:error, :not_found}, state}
      _ -> as_admin(sender, state, fn -> delete_message_by_index(state, index) end)
    end
  end

  @impl true
  def handle_call({:update_message, id, %{text: text}, sender}, _from, state) do
    new_messages =
      Enum.map(state.messages, fn message ->
        if message.id == id && message.sender_pid == sender,
          do: Message.set_text(message, text),
          else: message
      end)

    {:reply, {:ok}, %{state | messages: new_messages}}
  end

  @impl true
  def handle_call({:add_user, user, sender}, _from, state) do
    as_admin(sender, state, fn ->
      {:reply, {:ok}, %{state | users: put_user(state.users, user)}}
    end)
  end

  @impl true
  def handle_call({:upgrade_user, user, sender}, _from, state) do
    as_admin(sender, state, fn ->
      {_, new_users} =
        Map.get_and_update(state.users, user, fn current ->
          {current, %{current | role: "admin"}}
        end)

      {:reply, {:ok}, %{state | users: new_users}}
    end)
  end

  @impl true
  def handle_call({:remove_user, user, sender}, _from, state) do
    as_admin(sender, state, fn ->
      {_, new_users} = Map.pop(state.users, user)
      {:reply, {:ok}, %{state | users: new_users}}
    end)
  end

  defp broadcast_message(_state, _message) do
    # for user <- Map.keys(state.users) do
    #   Pigeon.UserRegistry.broadcast_message(user, message)
    # end
  end

  defp as_admin(user, state, action) do
    if is_admin?(user, state.users) do
      action.()
    else
      {:reply, {:error, :forbidden}, state}
    end
  end

  defp put_user(users, new_user_pid, role \\ "user") do
    Map.put_new(users, new_user_pid, %{role: role})
  end

  defp is_admin?(who, users), do: users[who].role == "admin"

  defp delete_message_by_index(state, index) do
    {:reply, {:ok}, %{state | messages: List.delete_at(state.messages, index)}}
  end
end
