defmodule Pigeon.Rooms.GroupRoom do
  use GenServer
  alias Pigeon.Message

  def start_link(_args) do
    GenServer.start_link(__MODULE__, %{users: [], messages: []})
  end

  def create_message(pid, text) do
    GenServer.cast(pid, {:create_message, %{text: text}})
  end

  def list_messages(pid) do
    GenServer.call(pid, {:list_messages})
  end

  def update_message(pid, message_id, text) do
    GenServer.cast(pid, {:update_message, message_id, %{text: text}})
  end

  def delete_message(pid, message_id) do
    GenServer.cast(pid, {:delete_message, message_id})
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_call({:list_messages}, _from, state) do
    {:reply, state.messages, state}
  end

  @impl true
  def handle_cast({:create_message, %{text: text}}, state) do
    new_message = Message.build(text)
    {:noreply, %{state | messages: [new_message | state.messages]}}
  end

  @impl true
  def handle_cast({:delete_message, message_id}, state) do
    new_messages = Enum.filter(state.messages, &(&1.id != message_id))
    {:noreply, %{state | messages: new_messages}}
  end

  @impl true
  def handle_cast({:update_message, id, %{text: text}}, state) do
    new_messages =
      Enum.map(state.messages, fn message ->
        if message.id == id, do: Message.set_text(message, text), else: message
      end)

    {:noreply, %{state | messages: new_messages}}
  end
end
