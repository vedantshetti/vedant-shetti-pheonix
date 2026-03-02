defmodule TodoerPhoenix.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      TodoerPhoenixWeb.Telemetry,
      TodoerPhoenix.Repo,
      {DNSCluster, query: Application.get_env(:todoer_phoenix, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: TodoerPhoenix.PubSub},
      TodoerPhoenixWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: TodoerPhoenix.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    TodoerPhoenixWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
