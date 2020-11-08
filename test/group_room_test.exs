defmodule Pigeon.GroupRoomTest do
  use ExUnit.Case, async: true
  alias Pigeon.Rooms.GroupRoom
  alias Pigeon.Message
  alias Pigeon.User

  setup do
    {:ok, user_pid} = User.start_link(:tincho)
    {:ok, room} = GroupRoom.start_link(%{owner: user_pid, name: :sala_1})
    %{room: room, owner: user_pid}
  end

  test "creates a message", %{room: room, owner: owner} do
    message_text = "Welcome to Pigeon"
    { status } = User.send_message_to_room(room, owner, message_text)

    assert status == :ok

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

  test "owner can add new participants to room", %{room: room, owner: owner} do
    other_user = User.start_link(:other)
    {status} = User.add_user_to_room(owner, room, other_user)
    assert status == :ok
  end
end
