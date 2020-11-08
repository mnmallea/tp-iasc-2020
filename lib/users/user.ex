defmodule Pigeon.User do
  use GenServer, Node

  def start_link(name) do
    GenServer.start_link(__MODULE__, name, name: name)
  end

  def login(user_name) do
    {:ok, pid} = start_link(user_name)
    message = GenServer.call(pid, {:login, user_name})
    IO.puts(message)
    pid
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_call({:login, user}, _from, state) do
    GenServer.call({state, :server@localhost}, {:add_to_registry, {state, Node.self()}})
    {:reply, "Login satisfactorio", user}
  end

  @impl true
  def handle_cast({:show_connections}, state) do
    GenServer.cast({state, :server@localhost}, {:show_connections, {state, Node.self()}})
    {:noreply, state}
  end

  @impl true
  def handle_cast({:create_group_room, name}, state) do
    GenServer.cast({state, :server@localhost}, {:create_group_room, {state, name}})
    {:noreply, state}
  end

  @impl true
  def handle_cast({:add_user, name}, state) do
    GenServer.cast({state, :server@localhost}, {:join_group_room, {state, name}})
    {:noreply, state}
  end

  @impl true
  def handle_cast({:send_message_to_room, {room, text}}, state) do
    GenServer.cast(room, {:send_message, {room, text}})
    {:noreply, state}
  end

  @impl true
  def handle_call({:add_user_to_room, {room, user}}, _from, state) do
    {:reply, Pigeon.Rooms.GroupRoom.add_user(room, user), state}
  end

  @impl true
  def handle_cast({:print_message, message}, state) do
    IO.inspect(message)
    {:noreply, state}
  end

  def show_connections(pid) do
    GenServer.cast(pid, {:show_connections})
  end

  def create_group_room(pid, name) do
    GenServer.cast(pid, {:create_group_room, name})
  end

  def add_user(pid, name) do
    GenServer.cast(pid, {:add_user, name})
  end

  def send_message_to_room(pid, room, text) do
    GenServer.cast(pid, {:send_message_to_room, {room, text}})
  end

  def add_user_to_room(this, user, room) do
    GenServer.call(this, :add_user_to_room, {user, room})
  end
end
