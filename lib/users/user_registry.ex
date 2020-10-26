defmodule Pigeon.UserRegistry do
    use GenServer, Node
    
    def start_link(user) do
        GenServer.start_link(__MODULE__, [], name: user)
    end

    @impl true
    def init(state) do
        {:ok, state}
    end

    @impl true
    def handle_call({:add_to_registry, node}, _from, state) do
        {:reply, [node | state], [node | state]}
    end

    @impl true
    def handle_call({:show_connections}, _from, state) do
        {:reply, state, state}
    end

    @impl true  
    def handle_cast({:broadcast_message, message}, state) do
        for node <- state do
            Pigeon.Network.spawn_task(Pigeon.User, :print_message, node, [message])
        end
        {:noreply, state}
    end
    
    def add_to_registry({user, node}) do
        GenServer.call(user, {:add_to_registry, node})
    end

    def show_connections({user, node}) do
        connections = GenServer.call(user, {:show_connections})
        Pigeon.Network.spawn_task(Pigeon.User, :print_message, node, [connections])
    end

    def broadcast_message(user, message) do
        GenServer.cast(user, {:broadcast_message, message})
    end
end