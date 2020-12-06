defmodule Pigeon.UserRegistry do
  use GenServer

  def start_link(user) do
    GenServer.start_link(__MODULE__, [], name: user)
  end

  # def child_spec({user}) do
  #   %{id: name, start: {__MODULE__, :start_link, [user]}, type: :worker}
  # end

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
    result = Pigeon.Rooms.Room.join_room(room, me)
    {:reply, result, state}
  end

  @impl true
  def handle_call({:add_user, {me, other, room}}, _from, state) do
    result = Pigeon.Rooms.Room.add_user(room, me, other)
    {:reply, result, state}
  end

  @impl true
  def handle_cast({:show_connections, node}, state) do
    GenServer.cast(node, {:print_message, state})
    {:noreply, state}
  end

  @impl true
  def handle_cast({:broadcast_message, message}, state) do 
    for {pid, _} <- state do
      GenServer.cast(pid, {:print_message, message})
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

  def broadcast_message(user, message) do
    GenServer.cast(user, {:broadcast_message, message})
  end
end
