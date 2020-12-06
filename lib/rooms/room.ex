defmodule Pigeon.Rooms.Room do
    use GenServer
    alias Pigeon.Message

    @impl true
    def init(state) do
        {:ok, state}
    end

    def create_room(user, name, type) do
        {:ok, pid} = GenServer.start_link(__MODULE__, %{users: [], messages: [], type: type, admins: [user]}, name: name)
        
        Pigeon.Rooms.Room.join_room(pid, user)
        pid
      end

    def create_message(pid, text, ttl, sender) do
        GenServer.call(pid, {:create_message, %{text: text, ttl: ttl, sender: sender}})
    end

    def list_messages(pid) do
        GenServer.call(pid, {:list_messages})
    end

    def update_message(pid, message_id, text, sender) do
        GenServer.call(pid, {:update_message, message_id, %{text: text, sender: sender}})
    end

    def delete_message(pid, message_id, sender) do
        GenServer.call(pid, {:delete_message, {message_id, sender}})
    end

    def add_user(pid, admin, user) do
        GenServer.call(pid, {:add_user, admin, user})
    end

    def join_room(pid, user) do
        GenServer.call(pid, {:join_room, user})
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

    @impl true
    def handle_call({:join_room, user}, _from, state) do
        users = [user | state.users]

        if Pigeon.Rooms.Join.can_join(state.type, users) do
            {:reply, "Ha sido agregado a la sala", %{state | users: users}}
        else
            {:reply, "No ha sido agregado a la sala", state}
        end
    end

    @impl true
    def handle_call({:add_user, admin,user}, _from, state) do
        users = [user | state.users]

        if is_admin?(admin, state.admins) && Pigeon.Rooms.Join.can_join(state.type, users) do
            {:reply, "Ha sido agregado a la sala", %{state | users: users}}
        else
            {:reply, "No ha sido agregado a la sala", state}
        end
    end

    @impl true
    def handle_call({:create_message, %{text: text, ttl: ttl, sender: sender}}, _from, state) do
        new_message = Message.build(text, sender)

        Pigeon.Rooms.MessageCleaner.schedule_clean(state.type, self(), new_message.id, ttl)
    
        for user <- state.users do
            Pigeon.UserRegistry.broadcast_message(user, text)
        end
    
        {:reply, {:ok, new_message} ,%{state | messages: [new_message | state.messages]}}
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

        {:noreply, %{state | messages: new_messages}}
        {:reply, {:ok}, %{state | messages: new_messages}}
    end

    @impl true
    def handle_call({:delete_message, {message_id, sender}}, _from, state) do
        index = Enum.find_index(state.messages, fn message -> message.id == message_id end)
        message = Enum.at(state.messages, index)

        case message do
            %Message{sender_pid: ^sender} -> delete_message_by_index(state, index)
            nil -> {:reply, {:error, :not_found}, state}
            _ -> as_admin(sender, state, fn -> delete_message_by_index(state, index) end)
        end
    end

    @impl true
    def handle_call({:upgrade_user, user, sender}, _from, state) do
      as_admin(sender, state, fn ->
        newAdmins = [user | state.admins]

        IO.puts(inspect(newAdmins))

        {:reply, {:ok}, %{state | admins: newAdmins}}
      end)
    end
  
    @impl true
    def handle_call({:remove_user, user, sender}, _from, state) do
      as_admin(sender, state, fn ->
        newUsers = Enum.reject(state.users, fn u -> u == user end)
        newAdmins = Enum.reject(state.admins, fn u -> u == user end)

        IO.puts(inspect(newUsers))
        IO.puts(inspect(newAdmins))
        {:reply, {:ok}, %{state | users: newUsers, admins: newAdmins}}
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
  end