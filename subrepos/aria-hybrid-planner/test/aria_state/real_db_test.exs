defmodule AriaState.RealDbTest do
  use ExUnit.Case, async: false
  alias AriaState.{BitemporalStore}

  @moduletag :real_db

  setup_all do
    # Start the repo for real database tests
    start_supervised!(AriaState.Repo)
    :ok
  end

  describe "real database operations" do
    test "can connect to database and perform basic operations" do
      # This test will fail if database is not available
      now = DateTime.utc_now()
      unique_id = :erlang.unique_integer([:positive])

      # Try to store a fact (this will fail if database is not running)
      aria_state = AriaState.new()
      |> AriaState.set_fact("test_connection", "db_test_#{unique_id}", %{"status" => "working"})

      facts = BitemporalStore.from_aria_state(aria_state, now)

      assert length(facts) == 1

      fact = List.first(facts)

      case BitemporalStore.store_fact(
        fact.predicate,
        fact.subject,
        fact.fact_value,
        fact.valid_from,
        fact.valid_to,
        fact.recorded_at
      ) do
      {:ok, stored_fact} ->
        # If we get here, database is working!
        assert stored_fact.predicate == "test_connection"
        assert stored_fact.subject == "db_test_#{unique_id}"
        assert stored_fact.fact_value == %{"status" => "working"}

        # Try to retrieve it
        {:ok, retrieved_value} = BitemporalStore.get_current_fact("test_connection", "db_test_#{unique_id}")
        assert retrieved_value == %{"status" => "working"}

      {:error, error} ->
        flunk("Database not available or not properly configured: #{inspect(error)}")
      end
    end

    test "database is accessible" do
      # Check that we can connect to the database
      case AriaState.Repo.query("SELECT 1 as test") do
        {:ok, _result} ->
          IO.puts("✅ Database is accessible")
        {:error, error} ->
          flunk("Database not accessible: #{inspect(error)}")
      end
    end
  end
end
