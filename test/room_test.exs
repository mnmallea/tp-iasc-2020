defmodule Pigeon.GroupRoomTest do
  use ExUnit.Case, async: true
  alias Pigeon.Message
  alias Pigeon.Rooms.Room
  alias Pigeon.User

  setup do
    {:ok, user_pid} = User.start_link(:tincho)
    room = Room.create_room(user_pid, :iasc, :group)
    %{room: room}
  end

  test "creates a message", %{room: room} do
    message_text = "Welcome to Pigeon"
    Room.create_message(room, message_text, 0)

    [received_message] = Room.list_messages(room)

    assert message_text == received_message.text
    assert received_message.id
  end

  test "creates and update a message", %{room: room} do
    old_text = "old message text"
    new_text = "new message text"
    Room.create_message(room, old_text, 0)
    [%Message{id: created_id}] = Room.list_messages(room)
    Room.update_message(room, created_id, new_text)
    [%Message{text: received_text}] = Room.list_messages(room)

    assert new_text == received_text
  end

  test "creates and deletes a message", %{room: room} do
    message_text = "some message"
    Room.create_message(room, message_text, 0)
    [%Message{id: created_id}] = Room.list_messages(room)

    Room.delete_message(room, created_id)

    messages = Room.list_messages(room)

    assert Enum.empty?(messages)
  end
end
