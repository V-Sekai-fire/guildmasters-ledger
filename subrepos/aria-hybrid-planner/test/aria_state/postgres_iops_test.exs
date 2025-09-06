defmodule AriaState.PostgresIopsTest do
  @moduledoc """
  PostgreSQL IOPS (Input/Output Operations Per Second) Performance Test.

  This test measures database performance for:
  - Write IOPS (insert operations per second)
  - Read IOPS (query operations per second)
  - Mixed workload performance
  - Bitemporal query performance
  - Time travel query performance
  """
  use ExUnit.Case, async: false
  alias AriaState.BitemporalStore

  @moduletag :performance

  setup do
    # Start the repo for performance tests
    case AriaState.Repo.start_link() do
      {:ok, _} -> :ok
      {:error, {:already_started, _}} -> :ok
      error -> error
    end

    # Verify TimescaleDB hypertable is available
    verify_hypertable()

    # Clean up any existing test data
    cleanup_test_data()

    :ok
  end

  defp cleanup_test_data() do
    # Clean up test data that might be left from previous runs
    try do
      AriaState.Repo.query("DELETE FROM facts WHERE predicate LIKE 'mixed_test_%' OR predicate LIKE 'performance_test_%' OR predicate LIKE 'read_test_%' OR predicate LIKE 'temporal_test_%'")
    rescue
      _ -> :ok  # Ignore cleanup errors
    end
  end

  defp verify_hypertable() do
    # Check if we're in mock mode (no database connection)
    test_mode = Application.get_env(:aria_hybrid_planner, :test_mode)

    if test_mode == :mock do
      IO.puts("🔄 TimescaleDB Hypertable: Skipping verification (mock database mode)")
      IO.puts("💡 To test hypertables: Run './scripts/setup_database.sh' with PostgreSQL + TimescaleDB")
    else
      # Verify that the facts table is a TimescaleDB hypertable
      try do
        case AriaState.Repo.query("SELECT hypertable_name FROM timescaledb_information.hypertables WHERE hypertable_name = 'facts'") do
          {:ok, %{rows: [[_hypertable_name]]}} ->
            IO.puts("✅ TimescaleDB Hypertable: facts table is properly configured as a hypertable")
          {:ok, %{rows: []}} ->
            IO.puts("⚠️  TimescaleDB Hypertable: facts table is NOT a hypertable (regular PostgreSQL table)")
            IO.puts("🔧 Run './scripts/setup_database.sh' to enable TimescaleDB optimizations")
          {:error, error} ->
            IO.puts("❌ TimescaleDB Hypertable: Could not verify hypertable status - #{inspect(error)}")
            IO.puts("🔧 Ensure TimescaleDB is installed and migrations have run")
        end
      rescue
        error ->
          IO.puts("❌ TimescaleDB Hypertable: Database connection failed - #{inspect(error)}")
          IO.puts("🔧 Start PostgreSQL service and run './scripts/setup_database.sh'")
      end
    end
  end

  describe "PostgreSQL IOPS performance" do
    test "write IOPS - basic fact insertion" do
      run_write_iops_test()
    end

    test "read IOPS - fact retrieval" do
      run_read_iops_test()
    end

    test "mixed workload IOPS" do
      run_mixed_iops_test()
    end

    test "bitemporal query IOPS" do
      run_bitemporal_iops_test()
    end
  end

  defp run_write_iops_test() do
    IO.puts("📊 Running Write IOPS Test...")

    # Prepare test data
    base_time = DateTime.utc_now()
    operations = 100
    unique_id = :erlang.unique_integer([:positive])

    # Generate test facts
    facts = Enum.map(1..operations, fn i ->
      %{
        predicate: "performance_test_#{unique_id}",
        subject: "entity_#{i}_#{unique_id}",
        fact_value: %{"value" => "value_#{i}", "index" => i},
        valid_from: base_time,
        valid_to: nil,
        recorded_at: base_time,
        recorded_to: nil
      }
    end)

    # Measure write performance
    {time_us, results} = :timer.tc(fn ->
      Enum.map(facts, fn fact ->
        BitemporalStore.store_fact(
          fact.predicate,
          fact.subject,
          fact.fact_value,
          fact.valid_from,
          fact.valid_to,
          fact.recorded_at
        )
      end)
    end)

    # Calculate IOPS
    time_seconds = time_us / 1_000_000
    successful_ops = Enum.count(results, fn
      {:ok, _} -> true
      _ -> false
    end)

    write_iops = successful_ops / time_seconds

    IO.puts("✅ Write Performance Results:")
    IO.puts("   Operations: #{operations}")
    IO.puts("   Successful: #{successful_ops}")
    IO.puts("   Time: #{Float.round(time_seconds, 3)}s")
    IO.puts("   Write IOPS: #{Float.round(write_iops, 2)}")

    # Assert reasonable performance
    assert successful_ops == operations
    assert write_iops > 0
  end

  defp run_read_iops_test() do
    IO.puts("📊 Running Read IOPS Test...")

    operations = 100
    base_time = DateTime.utc_now()
    unique_id = :erlang.unique_integer([:positive])

    # First, insert test data
    Enum.each(1..operations, fn i ->
      {:ok, _} = BitemporalStore.store_fact(
        "read_test_#{unique_id}",
        "entity_#{i}_#{unique_id}",
        %{"value" => "value_#{i}", "index" => i},
        base_time,
        nil,
        base_time
      )
    end)

    # Measure read performance
    {time_us, results} = :timer.tc(fn ->
      Enum.map(1..operations, fn i ->
        BitemporalStore.get_current_fact("read_test_#{unique_id}", "entity_#{i}_#{unique_id}")
      end)
    end)

    # Calculate IOPS
    time_seconds = time_us / 1_000_000
    successful_reads = Enum.count(results, fn
      {:ok, _} -> true
      _ -> false
    end)

    read_iops = successful_reads / time_seconds

    IO.puts("✅ Read Performance Results:")
    IO.puts("   Operations: #{operations}")
    IO.puts("   Successful: #{successful_reads}")
    IO.puts("   Time: #{Float.round(time_seconds, 3)}s")
    IO.puts("   Read IOPS: #{Float.round(read_iops, 2)}")

    # Assert reasonable performance
    assert successful_reads == operations
    assert read_iops > 0
  end

  defp run_mixed_iops_test() do
    IO.puts("📊 Running Mixed Workload IOPS Test...")

    operations = 50
    base_time = DateTime.utc_now()
    _unique_id = :erlang.unique_integer([:positive])

    # Mixed read/write operations
    {time_us, results} = :timer.tc(fn ->
      Enum.map(1..operations, fn i ->
        # Use unique identifiers for each operation to avoid conflicts
        op_unique_id = :erlang.unique_integer([:positive])

        # Write operation
        write_result = BitemporalStore.store_fact(
          "mixed_test_#{op_unique_id}",
          "entity_#{i}_#{op_unique_id}",
          %{"value" => "value_#{i}", "index" => i},
          base_time,
          nil,
          base_time
        )

        # Read operation
        read_result = BitemporalStore.get_current_fact("mixed_test_#{op_unique_id}", "entity_#{i}_#{op_unique_id}")

        {write_result, read_result}
      end)
    end)

    # Calculate mixed IOPS (2 operations per iteration)
    time_seconds = time_us / 1_000_000
    total_operations = operations * 2

    successful_ops = Enum.count(results, fn {write, read} ->
      case {write, read} do
        {{:ok, _}, {:ok, _}} -> true
        _ -> false
      end
    end)

    mixed_iops = successful_ops / time_seconds

    IO.puts("✅ Mixed Workload Performance Results:")
    IO.puts("   Total Operations: #{total_operations}")
    IO.puts("   Successful: #{successful_ops}")
    IO.puts("   Time: #{Float.round(time_seconds, 3)}s")
    IO.puts("   Mixed IOPS: #{Float.round(mixed_iops, 2)}")

    assert successful_ops == operations
    assert mixed_iops > 0
  end

  defp run_bitemporal_iops_test() do
    IO.puts("📊 Running Bitemporal Query IOPS Test...")

    operations = 30
    base_time = DateTime.utc_now()
    unique_id = :erlang.unique_integer([:positive])

    # Create historical data with multiple versions
    Enum.each(1..operations, fn i ->
      # Current version
      {:ok, _} = BitemporalStore.store_fact(
        "temporal_test_#{unique_id}",
        "entity_#{i}_#{unique_id}",
        %{"value" => "current_value", "version" => "current"},
        base_time,
        nil,
        base_time
      )

      # Historical version
      past_time = DateTime.add(base_time, -(i * 3600), :second)
      {:ok, _} = BitemporalStore.store_fact(
        "temporal_test_#{unique_id}",
        "entity_#{i}_#{unique_id}",
        %{"value" => "past_value_#{i}", "version" => "past"},
        past_time,
        base_time,
        past_time
      )
    end)

    # Measure bitemporal query performance
    {time_us, results} = :timer.tc(fn ->
      Enum.map(1..operations, fn i ->
        past_time = DateTime.add(base_time, -(i * 3600), :second)
        BitemporalStore.get_facts_at_time("temporal_test_#{unique_id}", "entity_#{i}_#{unique_id}", past_time)
      end)
    end)

    # Calculate IOPS
    time_seconds = time_us / 1_000_000
    successful_queries = Enum.count(results, fn
      results when is_list(results) -> true
      _ -> false
    end)

    bitemporal_iops = successful_queries / time_seconds

    IO.puts("✅ Bitemporal Query Performance Results:")
    IO.puts("   Queries: #{operations}")
    IO.puts("   Successful: #{successful_queries}")
    IO.puts("   Time: #{Float.round(time_seconds, 3)}s")
    IO.puts("   Bitemporal IOPS: #{Float.round(bitemporal_iops, 2)}")

    assert successful_queries == operations
    assert bitemporal_iops > 0
  end
end
