defmodule Pigeon.Rooms.Room do
    use GenServer
    alias Pigeon.Message

    @impl true
    def init(state) do
        {:ok, state}
    end

    def create_room(user, name, type) do
        {:ok, pid} = GenServer.start_link(__MODULE__, %{users: [], messages: [], type: type}, name: name)
        
        Pigeon.Rooms.Room.join_room(pid, user)
        pid
      end

    def create_message(pid, text, ttl) do
        GenServer.cast(pid, {:create_message, %{text: text, ttl: ttl}})
    end

    def list_messages(pid) do
        GenServer.call(pid, {:list_messages})
    end

    def update_message(pid, message_id, text) do
        GenServer.cast(pid, {:update_message, message_id, %{text: text}})
    end

    def delete_message(pid, message_id) do
        GenServer.cast(pid, {:delete_message, message_id})
    end

    def join_room(pid, user) do
        GenServer.call(pid, {:join_room, user})
    end

    @impl true
    def handle_call({:list_messages}, _from, state) do
        {:reply, state.messages, state}
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
    def handle_cast({:create_message, %{text: text, ttl: ttl}}, state) do
        new_message = Message.build(text)

        Pigeon.Rooms.MessageCleaner.schedule_clean(state.type, self(), new_message.id, ttl)
    
        for user <- state.users do
            Pigeon.UserRegistry.broadcast_message(user, text)
        end
    
        {:noreply, %{state | messages: [new_message | state.messages]}}
    end

    @impl true
    def handle_cast({:delete_message, message_id}, state) do
        new_messages = Enum.filter(state.messages, &(&1.id != message_id))
        {:noreply, %{state | messages: new_messages}}
    end

    @impl true
    def handle_cast({:update_message, id, %{text: text}}, state) do
        new_messages =
            Enum.map(state.messages, fn message ->
            if message.id == id, do: Message.set_text(message, text), else: message
            end)
    
        {:noreply, %{state | messages: new_messages}}
    end

    @impl true
    def handle_info({:delete_message, message_id}, state) do
        IO.puts("Deleting #{message_id}")
        
        delete_message(self(), message_id)
        {:noreply, state}
    end
  end