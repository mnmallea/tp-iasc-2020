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
    {status, message} = GroupRoom.create_message(room, {message_text, owner})

    assert status == :ok
    assert message

    [received_message] = GroupRoom.list_messages(room)

    assert message_text == received_message.text
    assert received_message.id
  end

  test "creates and update a message", %{room: room, owner: owner} do
    old_text = "old message text"
    new_text = "new message text"
    GroupRoom.create_message(room, {old_text, owner})
    [%Message{id: created_id}] = GroupRoom.list_messages(room)
    GroupRoom.update_message(room, {created_id, new_text, owner})
    [%Message{text: received_text}] = GroupRoom.list_messages(room)

    assert new_text == received_text
  end

  test "creates and deletes a message", %{room: room, owner: sender} do
    message_text = "some message"
    {:ok, _} = GroupRoom.create_message(room, {message_text, sender})
    [%Message{id: created_id}] = GroupRoom.list_messages(room)

    {:ok} = GroupRoom.delete_message(room, {created_id, sender})

    messages = GroupRoom.list_messages(room)

    assert Enum.empty?(messages)
  end

  test "admin can add and remove new participants to room", %{room: room, owner: admin} do
    {:ok, other_user} = User.start_link(:other)
    assert {:ok} = GroupRoom.add_user(room, {other_user, admin})
    assert {:ok, _} = GroupRoom.get_user_info(room, other_user)
    assert {:ok} = GroupRoom.remove_user(room, {other_user, admin})
    assert {:error, :not_found} = GroupRoom.get_user_info(room, other_user)
  end

  test "admin can give admin rights to other user in room", %{room: room, owner: owner} do
    {:ok, other_user} = User.start_link(:other_2)
    {:ok} = GroupRoom.add_user(room, {other_user, owner})
    {:ok} = GroupRoom.upgrade_user(room, {other_user, owner})

    {:ok, user_info} = GroupRoom.get_user_info(room, other_user)

    assert user_info.role == "admin"
  end

  test "admin can delete other user messages", %{room: room, owner: admin} do
    {:ok, other_user} = User.start_link(:other_3)
    {:ok, message} = GroupRoom.create_message(room, {"hola", other_user})

    {:ok} = GroupRoom.delete_message(room, {message.id, admin})
  end

  test "a normal user can not delete other user messages", %{room: room, owner: admin} do
    {:ok, other_user} = User.start_link(:other_4)
    {:ok} = GroupRoom.add_user(room, {other_user, admin})
    {:ok, message} = GroupRoom.create_message(room, {"hola", admin})

    {:error, :forbidden} = GroupRoom.delete_message(room, {message.id, other_user})
  end
end
