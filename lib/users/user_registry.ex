defmodule Pigeon.UserRegistry do
  use GenServer
  alias Pigeon.Rooms.Room

  def start_link(user) do
    {:ok, pid} = GenServer.start_link(__MODULE__, [], name: user)
  end

  def create_user(user) do
    {:ok, pid} = Swarm.register_name(user, Pigeon.UserRegistry.Supervisor, :register, [user])
    Swarm.join(:users, pid)
    {:ok, pid}
  end

  def broadcast_message(user, message, room_name) do
    GenServer.cast({:via, :swarm, user}, {:broadcast_message, message, room_name})
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
  def handle_call({:join_group_room, {me, room}}, _from, state) do
    result = Room.join_room(room, me)
    {:reply, result, state}
  end

  @impl true
  def handle_call({:add_user, {me, other, room}}, _from, state) do
    result = Room.add_user(room, me, other)
    {:reply, result, state}
  end

  @impl true
  def handle_call({:list_messages, room}, _from, state) do
    {:reply, Room.list_messages(room), state}
  end

  @impl true
  def handle_cast({:show_connections, node}, state) do
    GenServer.cast(node, {:print_message, state})
    {:noreply, state}
  end

  @impl true
  def handle_cast({:broadcast_message, message, room_name}, state) do
    IO.puts("[#{inspect(self)}:user_registry] Broadcasting message #{inspect(message)}")

    for {pid, _} <- state do
      GenServer.cast(pid, {:on_message, message, room_name})
    end

    {:noreply, state}
  end

  @impl true
  def handle_cast({:create_group_room, {me, name}}, state) do
    Pigeon.Rooms.GroupRoom.create_room(me, name)
    {:noreply, state}
  end

  @impl true
  def handle_cast({:create_chat, {me, name}}, state) do
    Pigeon.Rooms.IndividualRoom.create_room(me, name)
    {:noreply, state}
  end

  @impl true
  def handle_cast({:create_secret_room, {me, name}}, state) do
    Pigeon.Rooms.SecretRoom.create_room(me, name)
    {:noreply, state}
  end

  @impl true
  def handle_cast({:send_message, {room, text, ttl, me}}, state) do
    Pigeon.Rooms.Room.create_message(room, text, ttl, me)
    {:noreply, state}
  end

  @impl true
  def handle_call({:update_message, {room, id, text, me}}, _from, state) do
    {:reply, res, _} = Pigeon.Rooms.Room.update_message(room, id, text, me)
    {:reply, res, state}
  end

  @impl true
  def handle_call({:delete_message, {room, id, me}}, _from, state) do
    {:reply, res, _} = Pigeon.Rooms.Room.delete_message(room, id, me)
    {:reply, res, state}
  end

  @impl true
  def handle_call({:remove_user, {room, user, me}}, _from, state) do
    {:reply, res, _} = Pigeon.Rooms.Room.remove_user(room, {user, me})
    {:reply, res, state}
  end

  @impl true
  def handle_call({:get_user_info, {room, user}}, _from, state) do
    {:reply, res, _} = Pigeon.Rooms.Room.get_user_info(room, user)
    {:reply, res, state}
  end

  @impl true
  def handle_call({:upgrade_user, {room, user, me}}, _from, state) do
    {:reply, res, _} = Pigeon.Rooms.Room.upgrade_user(room, {user, me})
    {:reply, res, state}
  end
end