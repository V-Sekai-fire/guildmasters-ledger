# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaState.Repo do
  @moduledoc """
  Ecto Repository for AriaState bitemporal data.

  This repository handles all database operations for the bitemporal 6NF
  schemas, providing ACID transactions and multi-tenancy support.

  ## Configuration

  The repository uses a test-specific storage prefix to isolate test data
  from production data in the database.
  """

  use Ecto.Repo,
    otp_app: :aria_hybrid_planner,
    adapter: Ecto.Adapters.Postgres



  @doc """
  Returns the storage ID prefix for this repository.

  This ensures test data is isolated from production data in the database.
  """
  def storage_id() do
    case Application.get_env(:aria_hybrid_planner, :env) do
      :test -> "AriaState.Test"
      _ -> "AriaState.Production"
    end
  end

  @doc """
  Checks if TimescaleDB extension is available and enabled.

  Returns {:ok, version} if TimescaleDB is available, {:error, reason} otherwise.
  """
  def check_timescaledb() do
    try do
      case __MODULE__.query("SELECT extversion FROM pg_extension WHERE extname = 'timescaledb'") do
        {:ok, %{rows: [[version]]}} -> {:ok, version}
        {:ok, %{rows: []}} -> {:error, :not_enabled}
        {:error, _} -> {:error, :not_available}
      end
    rescue
      _ -> {:error, :connection_failed}
    end
  end
end
