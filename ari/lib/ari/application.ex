defmodule Ari.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      AriWeb.Telemetry,
      Ari.Repo,
      {DNSCluster, query: Application.get_env(:ari, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Ari.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Ari.Finch},
      {Ari.Accounts, []},
      # Start a worker by calling: Ari.Worker.start_link(arg)
      # {Ari.Worker, arg},
      # Start to serve requests, typically the last entry
      AriWeb.Endpoint
    ]


    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Ari.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    AriWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
