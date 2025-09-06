defmodule GuildmastersLedger.Benchmark do
  @moduledoc """
  Benchmarking module for comparing PostgreSQL and FoundationDB performance
  for high-concurrency game state operations.
  """

  alias GuildmastersLedger.Persistence

  @doc """
  Runs comprehensive benchmarks comparing PostgreSQL and FoundationDB
  for game-specific workloads simulating 1000+ concurrent heroes.
  """
  def run_comprehensive_benchmark do
    IO.puts("Starting comprehensive benchmark...")

    # Setup test data
    heroes = generate_heroes(1000)

    # PostgreSQL benchmark
    IO.puts("Running PostgreSQL benchmark...")
    postgres_results = benchmark_postgres(heroes)

    # FoundationDB benchmark
    IO.puts("Running FoundationDB benchmark...")
    fdb_results = benchmark_foundationdb(heroes)

    # Compare results
    compare_results(postgres_results, fdb_results)
  end

  @doc """
  Benchmarks PostgreSQL performance with hero state operations.
  """
  def benchmark_postgres(heroes) do
    Benchee.run(
      %{
        "postgres_hero_updates" => fn ->
          Enum.each(heroes, fn hero ->
            # Simulate hero status updates
            Persistence.set_fact("hero_status", hero.id, "active")
            Persistence.set_fact("hero_location", hero.id, hero.location)
            Persistence.get_fact("hero_status", hero.id)
          end)
        end,
        "postgres_concurrent_reads" => fn ->
          Enum.each(heroes, fn hero ->
            Persistence.get_fact("hero_status", hero.id)
            Persistence.get_fact("hero_location", hero.id)
          end)
        end
      },
      time: 10,
      memory_time: 2,
      parallel: 10
    )
  end

  @doc """
  Benchmarks FoundationDB performance with hero state operations.
  """
  def benchmark_foundationdb(heroes) do
    # Use EctoFoundationDB adapter for benchmarking
    # This simulates the same operations as PostgreSQL but with FDB backend

    Benchee.run(
      %{
        "fdb_hero_updates" => fn ->
          Enum.each(heroes, fn hero ->
            # Simulate hero status updates using FDB
            set_fdb_fact("hero_status", hero.id, "active")
            set_fdb_fact("hero_location", hero.id, hero.location)
            get_fdb_fact("hero_status", hero.id)
          end)
        end,
        "fdb_concurrent_reads" => fn ->
          Enum.each(heroes, fn hero ->
            get_fdb_fact("hero_status", hero.id)
            get_fdb_fact("hero_location", hero.id)
          end)
        end
      },
      time: 10,
      memory_time: 2,
      parallel: 10
    )
  end

  # FoundationDB simulation functions (would use actual FDB in production)
  defp get_fdb_fact(predicate, subject) do
    # Simulate FDB key lookup
    # In real implementation: EctoFoundationDB.Repo.get/2
    :timer.sleep(1) # Simulate network latency
    "active" # Mock response
  end

  defp set_fdb_fact(predicate, subject, value) do
    # Simulate FDB key-value set
    # In real implementation: EctoFoundationDB.Repo.insert/2
    :timer.sleep(1) # Simulate network latency
    :ok
  end

  @doc """
  Compares benchmark results and determines if FoundationDB meets requirements.
  """
  def compare_results(postgres_results, fdb_results) do
    IO.puts("\n=== Benchmark Results Comparison ===")

    postgres_ips = get_ips(postgres_results)
    fdb_ips = fdb_results.average.ips

    improvement = (fdb_ips / postgres_ips) * 100

    IO.puts("PostgreSQL IPS: #{postgres_ips}")
    IO.puts("FoundationDB IPS: #{fdb_ips}")
    IO.puts("Improvement: #{improvement}%")

    # Check success criteria
    meets_latency = fdb_ips >= 10000  # 10,000+ ops/second
    meets_improvement = improvement >= 200  # 2x improvement

    if meets_latency and meets_improvement do
      IO.puts("✅ SUCCESS: FoundationDB meets all performance requirements")
      :go
    else
      IO.puts("❌ REVIEW: FoundationDB does not meet requirements")
      :review
    end
  end

  defp generate_heroes(count) do
    Enum.map(1..count, fn i ->
      %{
        id: "hero_#{i}",
        location: "location_#{rem(i, 10)}",
        status: "active"
      }
    end)
  end

  defp get_ips(results) do
    # Extract IPS from Benchee results
    results
    |> Map.values()
    |> Enum.map(& &1.average.ips)
    |> Enum.sum()
    |> Kernel./(length(Map.keys(results)))
  end
end
