# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

# Check if we can connect to the database
database_available? = try do
  # Try to check database connection
  case AriaState.Repo.query("SELECT 1") do
    {:ok, _} -> true
    _ -> false
  end
rescue
  _ -> false
end

# Set test mode based on database availability
test_mode = if database_available?, do: :real_database, else: :mock
Application.put_env(:aria_hybrid_planner, :test_mode, test_mode)

IO.puts("🔬 Test Mode: #{if database_available?, do: "REAL DATABASE CONNECTED", else: "MOCKED DATABASE (Database not available)"}")

ExUnit.start(
  capture_log: true,
  max_failures: 1,
  trace: false,
  formatters: [ExUnit.CLIFormatter]
)
