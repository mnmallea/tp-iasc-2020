defmodule Pigeon.Rooms.GroupRoom do
  def create_room(user, name) do
    Pigeon.Rooms.Room.create_room(user, name, :group)
  end
end
