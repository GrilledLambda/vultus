defmodule Vultus.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      Vultus.Repo,
      # Start the Telemetry supervisor
      VultusWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Vultus.PubSub},
      # Start the Endpoint (http/https)
      VultusWeb.Endpoint,
      VultusWeb.Presence
      # Start a worker by calling: Vultus.Worker.start_link(arg)
      # {Vultus.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Vultus.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    VultusWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
