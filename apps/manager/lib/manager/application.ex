defmodule Manager.Application do
  @moduledoc false

  use Application

  @spec start(any, any) :: {:error, any} | {:ok, pid}
  def start(_type, _args) do
    children = []

    opts = [strategy: :one_for_one, name: Manager.Supervisor]
    Supervisor.start_link(children, opts)
  end

end
