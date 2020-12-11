defmodule Pigeon.UserRegistry.Supervisor do
  use DynamicSupervisor

  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def register(state) do
    {:ok, pid} = DynamicSupervisor.start_child(__MODULE__, {Pigeon.UserRegistry, state})
  end
end