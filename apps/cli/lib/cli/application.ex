defmodule Cli.Application do
  @moduledoc false

  use Application

  alias Manager

  @spec start(any, any) :: {:error, any} | {:ok, pid}
  def start(_type, _args) do
    children = [Manager]

    opts = [strategy: :one_for_one, name: Cli.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
