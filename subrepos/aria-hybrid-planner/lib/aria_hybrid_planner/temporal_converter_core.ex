# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaCore.TemporalConverter do
  @moduledoc """
  AriaCore.TemporalConverter provides the core temporal conversion API.
  
  This module delegates to AriaHybridPlanner.TemporalConverter for the actual
  implementation while providing the AriaCore namespace that tests expect.
  """

  # Delegate all functions to the actual implementation
  defdelegate convert_durative_action(durative_action), to: AriaHybridPlanner.TemporalConverter
  defdelegate extract_simple_action(durative_action), to: AriaHybridPlanner.TemporalConverter
  defdelegate build_method_decomposition(durative_action), to: AriaHybridPlanner.TemporalConverter
  defdelegate validate_conversion(original, converted), to: AriaHybridPlanner.TemporalConverter
  defdelegate is_legacy_durative_action?(action_spec), to: AriaHybridPlanner.TemporalConverter
  defdelegate convert_batch(legacy_actions), to: AriaHybridPlanner.TemporalConverter
end
