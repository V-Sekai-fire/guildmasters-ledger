# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

import Config

# Configure Ecto repositories
config :aria_hybrid_planner, ecto_repos: [AriaState.Repo]

# Configure AriaState.Repo for PostgreSQL (using Unix socket)
config :aria_hybrid_planner, AriaState.Repo,
  username: "fire",
  database: "aria_test",
  socket_dir: "/var/run/postgresql",
  pool: Ecto.Adapters.SQL.Sandbox

# Shared configuration for all apps
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id, :app]

# Suppress Porcelain goon executable warning
config :porcelain, goon_warn_if_missing: false

# Import environment specific config files
import_config "#{config_env()}.exs"
