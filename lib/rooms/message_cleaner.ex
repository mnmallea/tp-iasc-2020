defmodule Pigeon.Rooms.MessageCleaner do    
    def schedule_clean(:group, _pid_room, _message_id, _time) do
    end

    def schedule_clean(:chat, _pid_room, _message_id, _time) do
    end

    def schedule_clean(:secret, pid_room, message_id, _time) do
        Process.send_after(pid_room, {:delete_message, message_id}, 10000)
    end
end