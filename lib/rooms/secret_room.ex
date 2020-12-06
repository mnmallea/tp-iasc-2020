defmodule Pigeon.Rooms.SecretRoom do
  def create_room(user_1, user_2) do
    room_name = [user_1, user_2] |> Enum.sort() |> Enum.join("_")
    Pigeon.Rooms.Room.create_room({user_1, user_2}, String.to_atom("#{room_name}_private"), :secret)
  end
end
