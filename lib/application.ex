defmodule Pigeon.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    topologies = [
      topology: [
        strategy: Elixir.Cluster.Strategy.Gossip
      ]
    ]

    port = System.get_env("PORT")

    children = [
      {Cluster.Supervisor, [topologies, [name: Pigeon.ClusterSupervisor]]},
      Pigeon.UserRegistry.Supervisor,
      Pigeon.Room.Supervisor,
      Plug.Cowboy.child_spec(
        scheme: :http,
        plug: Pigeon.Router,
        options: [
          dispatch: dispatch(),
          port: (port && String.to_integer(port)) || 4000
        ]
      )
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: PigeonAppSupervirsor)
  end

  defp dispatch do
    [
      {:_,
       [
         {"/ws/[...]", Pigeon.SocketHandler, []},
         {:_, Plug.Cowboy.Handler, {Pigeon.Router, []}}
       ]}
    ]
  end
end
