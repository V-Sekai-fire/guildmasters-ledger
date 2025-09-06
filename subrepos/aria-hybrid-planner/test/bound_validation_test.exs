# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaMinizincStn.BoundValidationTest do
  use ExUnit.Case

  describe "constraint bound validation" do
    test "rejects constraints exceeding max reasonable bound" do
      # Create STN with constraint values exceeding the 1_000_000_000 bound
      stn = %{
        time_points: MapSet.new(["A", "B"]),
        constraints: %{
          # Exceeds @max_reasonable_bound
          {"A", "B"} => {1, 2_000_000_000}
        },
        consistent: nil,
        metadata: %{}
      }

      {:error, reason} = AriaMinizincStn.solve_stn(stn)

      assert reason =~ "exceeding maximum bound 1000000000"
      assert reason =~ "Constraint from A to B"
    end

    test "rejects constraints with negative values exceeding bound" do
      stn = %{
        time_points: MapSet.new(["A", "B"]),
        constraints: %{
          # Negative value exceeds bound
          {"A", "B"} => {-2_000_000_000, 5}
        },
        consistent: nil,
        metadata: %{}
      }

      {:error, reason} = AriaMinizincStn.solve_stn(stn)

      assert reason =~ "exceeding maximum bound 1000000000"
      assert reason =~ "Constraint from A to B"
    end

    test "accepts constraints within reasonable bounds" do
      stn = %{
        time_points: MapSet.new(["A", "B"]),
        constraints: %{
          # Within bounds
          {"A", "B"} => {1, 500_000_000}
        },
        consistent: nil,
        metadata: %{}
      }

      {:ok, result} = AriaMinizincStn.solve_stn(stn)

      assert result.consistent == true
    end

    test "accepts constraints at the boundary" do
      stn = %{
        time_points: MapSet.new(["A", "B"]),
        constraints: %{
          # Exactly at bounds
          {"A", "B"} => {-1_000_000_000, 1_000_000_000}
        },
        consistent: nil,
        metadata: %{}
      }

      {:ok, result} = AriaMinizincStn.solve_stn(stn)

      assert result.consistent == true
    end

    test "handles infinity values correctly" do
      stn = %{
        time_points: MapSet.new(["A", "B", "C"]),
        constraints: %{
          {"A", "B"} => {1, 5},
          # Should be accepted
          {"B", "C"} => {:neg_infinity, :infinity}
        },
        consistent: nil,
        metadata: %{}
      }

      {:ok, result} = AriaMinizincStn.solve_stn(stn)

      assert result.consistent == true
    end

    test "provides early return without calling MiniZinc" do
      # This test verifies that validation happens before MiniZinc execution
      stn = %{
        time_points: MapSet.new(["A", "B"]),
        constraints: %{
          # Way beyond bounds
          {"A", "B"} => {1, 5_000_000_000}
        },
        consistent: nil,
        metadata: %{}
      }

      # Should return error immediately without attempting MiniZinc solving
      start_time = System.monotonic_time(:millisecond)
      {:error, reason} = AriaMinizincStn.solve_stn(stn)
      end_time = System.monotonic_time(:millisecond)

      # Should be very fast since it doesn't call MiniZinc
      # Less than 100ms
      assert end_time - start_time < 100
      assert reason =~ "exceeding maximum bound"
    end
  end
end
