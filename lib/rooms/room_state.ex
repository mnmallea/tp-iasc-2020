defmodule Pigeon.RoomState do
  import Pigeon.SwarmUtils
  use Agent

  def start_link({name, state}) do
    {:ok, pid} = Agent.start_link(fn -> state end, name: name)
    {:ok, pid}
  end

  def init(state) do
    {:ok, state}
  end

  def get_state(name) do
    Agent.get(via_swarm(name), fn state -> state end)
  end

  def set_state(name, state) do
    Agent.update(via_swarm(name), fn _ -> state end)
  end
end
