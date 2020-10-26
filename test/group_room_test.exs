defmodule Pigeon.GroupRoomTest do
  use ExUnit.Case, async: true
  alias Pigeon.Rooms.GroupRoom
  alias Pigeon.Message

  setup do
    {:ok, room} = GroupRoom.start_link(nil)
    %{room: room}
  end

  test "creates a message", %{room: room} do
    message_text = "Welcome to Pigeon"
    GroupRoom.create_message(room, message_text)

    [received_message] = GroupRoom.list_messages(room)

    assert message_text == received_message.text
    assert received_message.id
  end

  test "creates and update a message", %{room: room} do
    old_text = "old message text"
    new_text = "new message text"
    GroupRoom.create_message(room, old_text)
    [%Message{id: created_id}] = GroupRoom.list_messages(room)
    GroupRoom.update_message(room, created_id, new_text)
    [%Message{text: received_text}] = GroupRoom.list_messages(room)

    assert new_text == received_text
  end

  test "creates and deletes a message", %{room: room} do
    message_text = "some message"
    GroupRoom.create_message(room, message_text)
    [%Message{id: created_id}] = GroupRoom.list_messages(room)

    GroupRoom.delete_message(room, created_id)

    messages = GroupRoom.list_messages(room)

    assert Enum.empty?(messages)
  end
end
