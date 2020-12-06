defmodule Pigeon.Rooms.IndividualRoom do
  def create_room(user_1, user_2) do
    room_name = [user_1, user_2] |> Enum.sort() |> Enum.join("_") |> String.to_atom()
    Pigeon.Rooms.Room.create_room({user_1, user_2}, room_name, :chat)
  end
end
