defmodule GuildmastersLedger do
  @moduledoc """
  Guildmaster's Ledger - Autonomous AI Heroes Game

  This is the main entry point for the Guildmaster's Ledger application,
  implementing a LitRPG game where players act as Guild Masters managing
  autonomous AI heroes that execute complex multi-step quests.

  ## Architecture

  - **Domain Layer**: Guild master domain with HTN planning
  - **Hero Layer**: Autonomous hero execution with goal processing
  - **Quest Layer**: Dynamic quest generation and management
  - **Persistence Layer**: Bitemporal PostgreSQL for world state
  - **Client Layer**: Godot 3D visualization (future)

  ## Key Components

  - `GuildmastersLedger.Domain.GuildMaster`: HTN domain for guild operations
  - `GuildmastersLedger.Hero.Server`: Autonomous hero GenServer
  - `GuildmastersLedger.Quest.Board`: Quest generation and management
  - `GuildmastersLedger.World.State`: Bitemporal world persistence
  """

  @doc """
  Returns the application version.
  """
  def version do
    {:ok, vsn} = :application.get_key(:guildmasters_ledger, :vsn)
    to_string(vsn)
  end
end
