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

  def join_room(pid, {user, sender}) do
    GenServer.call(pid, {:join_room, user, sender})
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

    for user <- Map.keys(state.users) do
      Pigeon.UserRegistry.broadcast_message(user, text)
    end

    {:reply, {:ok, new_message}, %{state | messages: [new_message | state.messages]}}
  end

  @impl true
  def handle_call({:delete_message, message_id, _sender}, _from, state) do
    new_messages = Enum.filter(state.messages, &(&1.id != message_id))
    {:reply, {:ok}, %{state | messages: new_messages}}
  end

  @impl true
  def handle_call({:update_message, id, %{text: text}, _sender}, _from, state) do
    new_messages =
      Enum.map(state.messages, fn message ->
        if message.id == id, do: Message.set_text(message, text), else: message
      end)

    {:reply, {:ok}, %{state | messages: new_messages}}
  end

  @impl true
  def handle_call({:join_room, user, sender}, _from, state) do
    if is_admin?(sender, state.users) do
      {:reply, {:ok}, %{state | users: add_user(state.users, user)}}
    else
      {:reply, {:error, :unauthorized}, state}
    end
  end

  @impl true
  def handle_call({:upgrade_user, user, sender}, _from, state) do
    if is_admin?(sender, state.users) do
      {_, new_users} =
        Map.get_and_update(state.users, user, fn current ->
          {current, %{current | role: "admin"}}
        end)

      {:reply, {:ok}, %{state | users: new_users}}
    else
      {:reply, {:error, :unauthorized}, state}
    end
  end

  defp as_admin(user, state, action) do
    if is_admin?(user, state.users) do
      action.()
    else
      { :reply, {:error, :unauthorized }, state}
    end
  end

  defp add_user(users, new_user_pid, role \\ "user") do
    Map.put_new(users, new_user_pid, %{role: role})
  end

  defp is_admin?(who, users), do: users[who].role == "admin"
end
