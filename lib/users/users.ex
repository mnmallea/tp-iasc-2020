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

  @impl true
  def handle_cast({:create_group_room, name}, state) do
    Pigeon.Network.spawn_task(Pigeon.UserRegistry, :create_group_room, :server@localhost, [{state, name}])

    {:noreply, state}
  end

  @impl true
  def handle_cast({:join_room, name}, state) do
    Pigeon.Network.spawn_task(Pigeon.UserRegistry, :join_group_room, :server@localhost, [{state, name}])

    {:noreply, state}
  end

  @impl true
  def handle_cast({:send_message_to_room, {room, text}}, state) do
    Pigeon.Network.spawn_task(Pigeon.UserRegistry, :send_message, :server@localhost, [{room, text}])

    {:noreply, state}
  end

  def show_connections(pid) do
    GenServer.cast(pid, {:show_connections})
  end

  def print_message(message) do
    IO.inspect(message)
  end

  def create_group_room(pid, name) do
    GenServer.cast(pid, {:create_group_room, name})
  end
  
  def join_room(pid, name) do
    GenServer.cast(pid, {:join_room, name})
  end

  def send_message_to_room(pid, room, text) do
    GenServer.cast(pid, {:send_message_to_room, {room, text}})
  end
end
