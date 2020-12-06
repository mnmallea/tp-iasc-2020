defmodule Pigeon.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    topologies =  [
      topology: [
        strategy: Elixir.Cluster.Strategy.Epmd,
        config: [
          hosts: [:"server1@localhost", :"server2@localhost", :"server2@localhost"]
        ]
      ]
    ]
    
    
    children = [
      {Cluster.Supervisor, [topologies, [name: Pigeon.ClusterSupervisor]]},
      Pigeon.UserRegistry.Supervisor,
      Pigeon.Room.Supervisor
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: PigeonAppSupervirsor)
  end
end
