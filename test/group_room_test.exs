defmodule Pigeon.GroupRoomTest do
  use ExUnit.Case, async: true
  alias Pigeon.Rooms.GroupRoom

  setup do
    {:ok, room} = GroupRoom.start_link(nil)
    %{room: room}
  end

  test 'creates a message', %{room: room} do
    message_text = 'Welcome to Pigeon'
    GroupRoom.create_message(room, message_text)

    [received_message] = GroupRoom.list_messages(room)

    assert message_text == received_message
  end
end
