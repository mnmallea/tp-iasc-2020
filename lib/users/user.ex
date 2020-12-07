defmodule Pigeon.User do
  use GenServer
  import Pigeon.SwarmUtils

  def start_link(state) do
    GenServer.start_link(__MODULE__, state)
  end

  def login(user_name, socket_pid) do
    {:ok, pid} = start_link(%{name: user_name, socket_pid: socket_pid})
    message = GenServer.call(pid, {:login, user_name})
    pid
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_call({:login, user}, _from, state) do
    GenServer.call(via_swarm(user), {:add_to_registry, {self(), Node.self()}})
    {:reply, "Login satisfactorio", state}
  end

  @impl true
  def handle_call({:join_room, name}, _from, state) do
    result = GenServer.call(via_swarm(state.name), {:join_group_room, {state.name, name}})
    {:reply, result, state}
  end

  @impl true
  def handle_call({:add_user, user, name}, _from, state) do
    result = GenServer.call(via_swarm(state.name), {:add_user, {state.name, user, name}})
    {:reply, result, state}
  end

  @impl true
  def handle_call({:add_user, user, name}, _from, state) do
    result = GenServer.call(via_swarm(state.name), {:add_user, {state.name, user, name}})
    {:reply, result, state}
  end

  @impl true
  def handle_cast({:show_connections}, state) do
    GenServer.cast(via_swarm(state.name), {:show_connections, {state.name, Node.self()}})
    {:noreply, state}
  end

  @impl true
  def handle_cast({:create_group_room, name}, state) do
    GenServer.cast(via_swarm(state.name), {:create_group_room, {state.name, name}})
    {:noreply, state}
  end

  @impl true
  def handle_cast({:create_chat, name}, state) do
    GenServer.cast(via_swarm(state.name), {:create_chat, {state.name, name}})
    {:noreply, state}
  end

  @impl true
  def handle_cast({:create_secret_room, name}, state) do
    GenServer.cast(via_swarm(state.name), {:create_secret_room, {state.name, name}})
    {:noreply, state}
  end

  @impl true
  def handle_cast({:send_message_to_room, {room, text, ttl}}, state) do
    GenServer.cast(via_swarm(state.name), {:send_message, {room, text, ttl, state.name}})
    {:noreply, state}
  end

  @impl true
  def handle_cast({:on_message, message}, state) do
    IO.puts(inspect(message))
    Process.send(state.socket_pid, message, [])
    {:noreply, state}
  end

  def show_connections(pid) do
    GenServer.cast(pid, {:show_connections})
  end

  def create_group_room(pid, name) do
    GenServer.cast(pid, {:create_group_room, as_atom(name)})
  end

  def create_chat(pid, name) do
    GenServer.cast(pid, {:create_chat, as_atom(name)})
  end

  def create_secret_room(pid, name) do
    GenServer.cast(pid, {:create_secret_room, as_atom(name)})
  end

  def join_room(pid, name) do
    GenServer.call(pid, {:join_room, as_atom(name)})
  end

  def add_user(pid, user, name) do
    GenServer.call(pid, {:add_user, as_atom(user), as_atom(name)})
  end

  def send_message_to_room(pid, room, text, ttl) do
    GenServer.cast(pid, {:send_message_to_room, {as_atom(room), text, ttl}})
  end

  def send_message_to_room(pid, room, text) do
    GenServer.cast(pid, {:send_message_to_room, {as_atom(room), text, -1}})
  end

  defp as_atom(atom) when is_atom(atom), do: atom
  defp as_atom(string) when is_bitstring(string), do: String.to_atom(string)
end
