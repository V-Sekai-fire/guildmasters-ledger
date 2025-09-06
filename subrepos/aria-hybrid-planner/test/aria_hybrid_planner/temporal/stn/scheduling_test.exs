defmodule AriaHybridPlanner.Temporal.STN.SchedulingTest do
  use ExUnit.Case, async: true

  alias AriaHybridPlanner.Temporal.STN
  alias AriaHybridPlanner.Temporal.STN.Scheduling

  describe "get_intervals/1" do
    test "returns empty list for STN with no intervals" do
      stn = STN.new()
      intervals = Scheduling.get_intervals(stn)
      assert intervals == []
    end

    test "returns intervals when STN has time points" do
      stn = STN.new()
      stn = STN.add_time_point(stn, "task1_start")
      stn = STN.add_time_point(stn, "task1_end")
      stn = STN.add_constraint(stn, "task1_start", "task1_end", {0, 60})

      intervals = Scheduling.get_intervals(stn)
      assert length(intervals) == 1

      interval = hd(intervals)
      assert interval.id == "task1"
      assert interval.start_time == 0
      # The end time calculation may vary based on STN implementation
      assert is_number(interval.end_time)
      assert interval.end_time > 0
      assert interval.metadata == %{}
    end
  end

  describe "get_overlapping_intervals/3" do
    test "returns empty list when no intervals overlap" do
      stn = STN.new()
      stn = STN.add_time_point(stn, "task1_start")
      stn = STN.add_time_point(stn, "task1_end")
      stn = STN.add_constraint(stn, "task1_start", "task1_end", {0, 60})

      overlapping = Scheduling.get_overlapping_intervals(stn, 100, 200)
      assert overlapping == []
    end

    test "returns overlapping intervals" do
      stn = STN.new()
      stn = STN.add_time_point(stn, "task1_start")
      stn = STN.add_time_point(stn, "task1_end")
      stn = STN.add_constraint(stn, "task1_start", "task1_end", {0, 60})

      overlapping = Scheduling.get_overlapping_intervals(stn, 30, 90)
      assert length(overlapping) == 1

      interval = hd(overlapping)
      assert interval.id == "task1"
    end
  end

  describe "find_free_slots/4" do
    test "returns free slots when available" do
      stn = STN.new()
      stn = STN.add_time_point(stn, "task1_start")
      stn = STN.add_time_point(stn, "task1_end")
      stn = STN.add_constraint(stn, "task1_start", "task1_end", {20, 80})

      slots = Scheduling.find_free_slots(stn, 30, 0, 100)
      assert length(slots) >= 1

      # Check that we have at least one slot with the correct duration
      slot = hd(slots)
      assert slot.end_time - slot.start_time == 30
      assert slot.start_time >= 0
      assert slot.end_time <= 100
    end
  end

  describe "check_interval_conflicts/3" do
    test "returns empty list when no conflicts" do
      stn = STN.new()
      stn = STN.add_time_point(stn, "task1_start")
      stn = STN.add_time_point(stn, "task1_end")
      stn = STN.add_constraint(stn, "task1_start", "task1_end", {0, 60})

      conflicts = Scheduling.check_interval_conflicts(stn, 100, 160)
      assert conflicts == []
    end

    test "returns conflicting intervals" do
      stn = STN.new()
      stn = STN.add_time_point(stn, "task1_start")
      stn = STN.add_time_point(stn, "task1_end")
      stn = STN.add_constraint(stn, "task1_start", "task1_end", {0, 60})

      conflicts = Scheduling.check_interval_conflicts(stn, 30, 90)
      assert length(conflicts) == 1

      conflict = hd(conflicts)
      assert conflict.id == "task1"
    end
  end

  describe "find_next_available_slot/3" do
    test "returns error when no slot available" do
      stn = STN.new()
      stn = STN.add_time_point(stn, "task1_start")
      stn = STN.add_time_point(stn, "task1_end")
      stn = STN.add_constraint(stn, "task1_start", "task1_end", {0, 2_592_000_000})

      result = Scheduling.find_next_available_slot(stn, 3600, 0)
      assert result == {:error, :no_available_slot}
    end

    test "returns available slot when found" do
      stn = STN.new()
      stn = STN.add_time_point(stn, "task1_start")
      stn = STN.add_time_point(stn, "task1_end")
      stn = STN.add_constraint(stn, "task1_start", "task1_end", {100, 200})

      result = Scheduling.find_next_available_slot(stn, 50, 0)
      assert {:ok, start_time, end_time} = result
      assert end_time - start_time == 50
      assert start_time >= 0
    end
  end
end
