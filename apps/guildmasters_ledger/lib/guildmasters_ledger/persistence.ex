defmodule GuildmastersLedger.Persistence do
  @moduledoc """
  Persistence behaviour for Guildmaster's Ledger

  This behaviour defines the interface for persisting game state facts
  using the HTN planning system's get_fact/set_fact API.

  The implementation uses traditional Ecto schemas instead of EAV pattern,
  with predicate routing to map planner operations to appropriate schema operations.
  """

  @type predicate :: String.t()
  @type subject :: String.t()
  @type value :: term()

  @doc """
  Retrieves a fact value for the given predicate and subject.

  Returns the value if found, nil otherwise.
  """
  @callback get_fact(predicate, subject) :: value | nil

  @doc """
  Sets a fact value for the given predicate and subject.

  Returns :ok on success, {:error, reason} on failure.
  """
  @callback set_fact(predicate, subject, value) :: :ok | {:error, term()}

  @doc """
  Initializes the persistence layer.

  This should set up any necessary database connections, migrations, etc.
  """
  @callback init() :: :ok | {:error, term()}

  @doc """
  Cleans up the persistence layer.

  This should close connections, etc.
  """
  @callback cleanup() :: :ok | {:error, term()}
end
