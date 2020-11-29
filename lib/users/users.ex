defmodule Pigeon.User do
  use GenServer, Node

  def start_link(name) do
    GenServer.start_link(__MODULE__, name, name: name)
  end

  def login(user_name) do
    {:ok, pid} = start_link(user_name)
    message = GenServer.call(pid, {:login, user_name})
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
  def handle_call({:join_room, name}, _from, state) do
    result = GenServer.call({state, :server@localhost}, {:join_group_room, {state, name}})
    {:reply, result, state}
  end

  @impl true
  def handle_call({:add_user, user, name}, _from, state) do
    result = GenServer.call({state, :server@localhost}, {:add_user, {state, user, name}})
    {:reply, result, state}
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
  def handle_cast({:create_chat, name}, state) do
    GenServer.cast({state, :server@localhost}, {:create_chat, {state, name}})
    {:noreply, state}
  end

  @impl true
  def handle_cast({:create_secret_room, name}, state) do
    GenServer.cast({state, :server@localhost}, {:create_secret_room, {state, name}})
    {:noreply, state}
  end

  @impl true
  def handle_cast({:send_message_to_room, {room, text, ttl}}, state) do
    GenServer.cast({state, :server@localhost}, {:send_message, {room, text, ttl, state}})
    {:noreply, state}
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

  def create_chat(pid, name) do
    GenServer.cast(pid, {:create_chat, name})
  end

  def create_secret_room(pid, name) do
    GenServer.cast(pid, {:create_secret_room, name})
  end

  def join_room(pid, name) do
    GenServer.call(pid, {:join_room, name})
  end

  def add_user(pid, user, name) do
    GenServer.call(pid, {:add_user, user, name})
  end

  def send_message_to_room(pid, room, text, ttl) do
    GenServer.cast(pid, {:send_message_to_room, {room, text, ttl}})
  end

  def send_message_to_room(pid, room, text) do
    GenServer.cast(pid, {:send_message_to_room, {room, text, -1}})
  end
end
