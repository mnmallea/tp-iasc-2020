defmodule Pigeon.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      {Task.Supervisor, name: Pigeon.TaskSupervisor}
    ]

    opts = [strategy: :one_for_one, name: Pigeon.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
