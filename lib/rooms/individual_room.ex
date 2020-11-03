defmodule Pigeon.Rooms.IndividualRoom do
    def create_room(user, name) do
      Pigeon.Rooms.Room.create_room(user, name, :chat)
    end
end