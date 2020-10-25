defmodule Pigeon.GroupRoomTest do
  use ExUnit.Case, async: true

  setup do
    {:ok, room} = Pigeon.Rooms.GroupRoom.start_link(nil)
    %{room: room}
  end

  test 'creates a message', %{room: room} do
    message_text = 'Welcome to Pigeon'
    Pigeon.Rooms.GroupRoom.create_message(room, message_text)

    [received_message] = Pigeon.Rooms.GroupRoom.list_messages(room)

    assert message_text == received_message
  end
end
