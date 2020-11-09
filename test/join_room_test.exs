defmodule Pigeon.JoinRoomTest do
    use ExUnit.Case, async: true
    alias Pigeon.Rooms.Room
    alias Pigeon.User
  
    test "join 3 people to group room", _ do
        {:ok, user1} = User.start_link(:user1)
        {:ok, user2} = User.start_link(:user2)
        {:ok, user3} = User.start_link(:user3)

        room = Room.create_room(user1, :group_room, :group)

        message1 = Room.join_room(room, user1)
        message2 = Room.join_room(room, user2)
        message3 = Room.join_room(room, user3)

        assert message1 == "Ha sido agregado a la sala"
        assert message2 == "Ha sido agregado a la sala"
        assert message3 == "Ha sido agregado a la sala"
    end


    test "join 3 people to individual room; Third person shouldn't be added",_ do
        {:ok, user1} = User.start_link(:user1)
        {:ok, user2} = User.start_link(:user2)
        {:ok, user3} = User.start_link(:user3)

        room = Room.create_room(user1, :chat_room, :chat)

        message1 = Room.join_room(room, user1)
        message2 = Room.join_room(room, user2)
        message3 = Room.join_room(room, user3)

        assert message1 == "Ha sido agregado a la sala"
        assert message2 == "Ha sido agregado a la sala"
        assert message3 == "No ha sido agregado a la sala"
    end

    test "join 3 people to secret room; Third person shouldn't be added", _ do
        {:ok, user1} = User.start_link(:user1)
        {:ok, user2} = User.start_link(:user2)
        {:ok, user3} = User.start_link(:user3)

        room = Room.create_room(user1, :secret_room, :secret)

        message1 = Room.join_room(room, user1)
        message2 = Room.join_room(room, user2)
        message3 = Room.join_room(room, user3)

        assert message1 == "Ha sido agregado a la sala"
        assert message2 == "Ha sido agregado a la sala"
        assert message3 == "No ha sido agregado a la sala"
    end
  end
  