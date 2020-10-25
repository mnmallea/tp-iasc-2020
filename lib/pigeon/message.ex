defmodule Pigeon.Message do
  @enforce_keys [:id, :text]
  defstruct [:id, :text]

  alias __MODULE__, as: Message

  def build(text) do
    %Message{id: UUID.uuid1(), text: text}
  end

  def set_text(message, text) do
    %Message{message | text: text}
  end
end
