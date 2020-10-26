defmodule Pigeon.User do
  use GenServer, Node

  def login(user) do
    {:ok, pid} = GenServer.start_link(__MODULE__, :ok)
    message = GenServer.call(pid, {:login, user})
    IO.puts(message)
    pid
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_call({:login, user}, _from, _) do
    Pigeon.Network.spawn_task(Pigeon.UserRegistry, :add_to_registry, :server@localhost, [
      {user, Node.self()}
    ])

    {:reply, "Login satisfactorio", user}
  end

  @impl true
  def handle_cast({:show_connections}, state) do
    Pigeon.Network.spawn_task(Pigeon.UserRegistry, :show_connections, :server@localhost, [
      {state, Node.self()}
    ])

    {:noreply, state}
  end

  def show_connections(pid) do
    GenServer.cast(pid, {:show_connections})
  end

  def print_message(message) do
    IO.inspect(message)
  end
end
