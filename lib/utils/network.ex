defmodule Pigeon.Network do
  def spawn_task(module, fun, recipient, args) do
    recipient
    |> remote_supervisor()
    |> Task.Supervisor.async(module, fun, args)
    |> Task.await()
  end

  def remote_supervisor(recipient) do
    {Pigeon.TaskSupervisor, recipient}
  end
end
