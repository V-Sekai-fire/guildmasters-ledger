# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

import Config

# Configure logger to be less verbose during tests
config :logger,
  level: :warning,
  compile_time_purge_matching: [
    [level_lower_than: :warning]
  ]

# Configure ExUnit for minimal output
config :ex_unit,
  capture_log: true,
  assert_receive_timeout: 100

# Configure test environment for AriaState
config :aria_hybrid_planner,
  env: :test

# Configure AriaState.Repo for PostgreSQL in tests (using Unix socket authentication)
config :aria_hybrid_planner, AriaState.Repo,
  username: "fire",
  database: "aria_test",
  socket_dir: "/var/run/postgresql",
  pool: Ecto.Adapters.SQL.Sandbox
