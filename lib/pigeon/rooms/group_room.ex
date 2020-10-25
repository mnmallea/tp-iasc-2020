defmodule Pigeon.Rooms.GroupRoom do
  use GenServer

  def start_link(_args) do
    GenServer.start_link(__MODULE__, %{users: [], messages: []})
  end

  def create_message(pid, text) do
    GenServer.cast(pid, {:create_message, %{ text: text } })
  end

  def list_messages(pid) do
    GenServer.call(pid, {:list_messages})
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
    {:noreply, %{state | messages:  [text | state.messages]}}
  end
end
