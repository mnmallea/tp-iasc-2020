defmodule Pigeon.SocketHandler do
  @behaviour :cowboy_websocket

  def init(request, _state) do
    IO.puts("INIT")
    username = request.path |> String.split("/") |> Enum.at(2) |> String.to_atom()
    {:cowboy_websocket, request, %{username: username}}
  end

  def websocket_init(state) do
    pid = Pigeon.User.login(state.username, self())
    {:ok, Map.put(state, :user_pid, pid)}
  end

  # Messages from browser
  def websocket_handle({:text, message}, state) do
    IO.puts("WS handle #{inspect(message)}")
    [command | args] = String.split(message, " ")
    res = apply(Pigeon.User, String.to_atom(command), [state.user_pid | args])
    IO.puts("Done")
    {:reply, {:text, inspect(res)}, state}
  end

  def websocket_handle(message, state) do
    IO.puts("Unknown message: #{inspect(message)}")
    {:ok, state}
  end

  # Format and forward elixir messages to client
  def websocket_info(message, state) do
    message |> inspect |> IO.puts()
    {:reply, {:text, inspect(message)}, state}
  end
end
