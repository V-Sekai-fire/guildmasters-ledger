# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

import Config

# Production configuration
config :logger, level: :info

# Configure production environment for AriaState
config :aria_hybrid_planner,
  env: :prod
