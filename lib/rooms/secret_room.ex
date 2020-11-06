defmodule Pigeon.Rooms.SecretRoom do
    def create_room(user, name) do
      Pigeon.Rooms.Room.create_room(user, name, :secret)
    end
end