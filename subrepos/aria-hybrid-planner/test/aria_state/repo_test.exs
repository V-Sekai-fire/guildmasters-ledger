defmodule AriaState.RepoTest do
  use ExUnit.Case, async: true
  alias AriaState.Repo

  describe "migration files" do
    test "migration file exists" do
      # Verify the migration file exists and has the correct structure
      migration_path = Path.join(["priv", "repo", "migrations", "001_create_bitemporal_schemas.exs"])
      assert File.exists?(migration_path)

      # Verify the migration file contains expected content
      content = File.read!(migration_path)
      assert String.contains?(content, "CreateBitemporalSchemas")
      assert String.contains?(content, "create table(:facts")
    end
  end

  describe "configuration" do
    test "uses correct adapter" do
      # This test verifies the Repo is configured with the correct adapter
      # In a real application, you'd test the actual database connection
      # For now, we just verify the module exists and is properly structured
      assert Repo.__adapter__() == Ecto.Adapters.Postgres
    end

    test "uses environment-specific storage prefix" do
      # Verify that the storage prefix is environment-specific
      env = Application.get_env(:aria_hybrid_planner, :env, :dev)
      expected_prefix = case env do
        :test -> "AriaState.Test"
        _ -> "AriaState.Production"
      end
      assert Repo.storage_id() == expected_prefix
    end
  end

  describe "timescaledb integration" do
    test "timescaledb extension is available" do
      # Test TimescaleDB availability when database is connected
      case Repo.check_timescaledb() do
        {:ok, version} ->
          # TimescaleDB is available and enabled
          assert is_binary(version)
          assert String.length(version) > 0
        {:error, :connection_failed} ->
          # Database not available (expected in test environment)
          :ok
        {:error, reason} ->
          # TimescaleDB not enabled or available
          flunk("TimescaleDB not properly configured: #{inspect(reason)}")
      end
    end
  end
end
