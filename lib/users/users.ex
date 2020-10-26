defmodule Pigeon.User do
    use GenServer, Node
    
    def start_link() do
        GenServer.start_link(__MODULE__, [])
    end

    @impl true
    def init(state) do
        {:ok, state}
    end
    
    @impl true
    def handle_call({:login, user}, _from, state) do
        Pigeon.Network.spawn_task(Pigeon.UserRegistry, :add_to_registry, :server@localhost, [{user, Node.self()}])
        {:reply, "Login satisfactorio", state}
    end

    @impl true
    def handle_call({:show_connections, user}, _from, state) do
        Pigeon.Network.spawn_task(Pigeon.UserRegistry, :show_connections, :server@localhost, [user])
        {:reply, state, state}
    end
    
    def login(pid, user) do
        GenServer.call(pid, {:login, user})
    end

    def show_connections(pid, user) do
        GenServer.call(pid, {:show_connections, user})
    end

    def print_message(message) do
        IO.puts message
    end
end