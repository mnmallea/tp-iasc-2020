defmodule Pigeon.Rooms.MessageCleaner do    
    def schedule_clean(:group, _pid_room, _message_id, _time) do
    end

    def schedule_clean(:chat, _pid_room, _message_id, _time) do
    end

    def schedule_clean(:secret, pid_room, message_id, time) do
        if time > 0 do
            Process.send_after(pid_room, {:delete_message, message_id}, time)
        end
    end
end