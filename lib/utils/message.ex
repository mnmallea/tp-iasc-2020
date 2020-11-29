defmodule Pigeon.Message do
  @enforce_keys [:id, :text, :sender_pid]
  defstruct [:id, :text, :sender_pid]

  alias __MODULE__, as: Message

  def build(text, sender_pid) do
    %Message{id: UUID.uuid1(), text: text, sender_pid: sender_pid}
  end

  def set_text(message, text) do
    %Message{message | text: text}
  end
end
