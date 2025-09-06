defmodule GuildmastersLedger.Application do
  @moduledoc """
  Guildmaster's Ledger Application

  This module defines the supervision tree for the Guildmaster's Ledger application.
  It starts the core services needed for autonomous AI hero management.
  """

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Core services will be added here as they are implemented
      # GuildmastersLedger.Quest.Board,
      # GuildmastersLedger.World.State,
    ]

    opts = [strategy: :one_for_one, name: GuildmastersLedger.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
