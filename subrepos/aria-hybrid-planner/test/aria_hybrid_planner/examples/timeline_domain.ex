# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaHybridPlanner.Examples.TimelineDomain do
  @moduledoc """
  Test domain for Timeline capability testing.
  
  Provides entity, agent, and capability management actions following the
  R25W1398085 unified durative action specification. This domain eliminates
  hard-coded entity creation from tests by providing reusable domain actions.
  """
  
  use AriaCore.Domain
  require Logger

  @type entity_id :: String.t()
  @type agent_id :: String.t()
  @type capability :: atom()

  # Medical scenario entities
  @action true
  @spec register_medical_team(AriaState.t(), []) :: {:ok, AriaState.t()} | {:error, atom()}
  def register_medical_team(state, []) do
    state
    |> register_entity(["cardiac_surgeon", "agent", [:cardiac_surgery, :decision_making, :medical_expertise, :leadership]])
    |> register_entity(["anesthesiologist", "agent", [:anesthesia_management, :patient_monitoring, :emergency_response]])
    |> register_entity(["surgical_nurse", "agent", [:surgical_assistance, :sterile_technique, :equipment_management]])
    |> register_entity(["operating_room", "entity", [:sterile_environment, :heart_lung_machine, :monitors, :surgical_tools]])
    {:ok, state}
  end

  # Vehicle fleet entities
  @action true
  @spec register_vehicle_fleet(AriaState.t(), []) :: {:ok, AriaState.t()} | {:error, atom()}
  def register_vehicle_fleet(state, []) do
    state
    |> register_entity(["delivery_truck", "entity", [:cargo_capacity]])
    |> register_entity(["passenger_car", "entity", [:passenger_capacity]])
    {:ok, state}
  end

  # Manufacturing scenario entities
  @action true
  @spec register_manufacturing_setup(AriaState.t(), []) :: {:ok, AriaState.t()} | {:error, atom()}
  def register_manufacturing_setup(state, []) do
    state
    |> register_entity(["operator1", "agent", [:machine_operation, :safety_protocols]])
    |> register_entity(["operator2", "agent", [:machine_operation, :safety_protocols, :maintenance]])
    |> register_entity(["cnc_machine", "entity", [:precision_cutting]])
    |> register_entity(["industrial_robot", "agent", [:welding, :decision_making, :movement]])
    {:ok, state}
  end

  # Software development team entities
  @action true
  @spec register_software_team(AriaState.t(), []) :: {:ok, AriaState.t()} | {:error, atom()}
  def register_software_team(state, []) do
    state
    |> register_entity(["project_manager", "agent", [:planning, :coordination, :decision_making]])
    |> register_entity(["developer", "agent", [:coding, :problem_solving, :technical_analysis]])
    |> register_entity(["tester", "agent", [:testing, :quality_assurance, :bug_detection]])
    {:ok, state}
  end

  # Aviation scenario entities
  @action true
  @spec register_aviation_setup(AriaState.t(), []) :: {:ok, AriaState.t()} | {:error, atom()}
  def register_aviation_setup(state, []) do
    state
    |> register_entity(["pilot", "agent", [:flying, :navigation, :decision_making]])
    {:ok, state}
  end

  # IoT device entities
  @action true
  @spec register_iot_devices(AriaState.t(), []) :: {:ok, AriaState.t()} | {:error, atom()}
  def register_iot_devices(state, []) do
    state
    |> register_entity(["smart_device", "entity", []])
    |> register_entity(["smart_sensor", "entity", []])
    {:ok, state}
  end

  # Facility management entities
  @action true
  @spec register_facility_setup(AriaState.t(), []) :: {:ok, AriaState.t()} | {:error, atom()}
  def register_facility_setup(state, []) do
    state
    |> register_entity(["manager1", "agent", [:facility_management]])
    |> register_entity(["manager2", "agent", [:facility_management]])
    |> register_entity(["conference_room", "entity", [:meeting_space, :presentation_equipment]])
    {:ok, state}
  end

  # Construction scenario entities
  @action true
  @spec register_construction_team(AriaState.t(), []) :: {:ok, AriaState.t()} | {:error, atom()}
  def register_construction_team(state, []) do
    state
    |> register_entity(["architect", "agent", [:design, :planning, :approval, :decision_making]])
    |> register_entity(["engineer", "agent", [:engineering_analysis, :calculations, :technical_review]])
    |> register_entity(["contractor", "agent", [:construction, :project_management, :resource_coordination]])
    {:ok, state}
  end

  # Capability management actions
  @action true
  @spec enable_autonomous_capabilities(AriaState.t(), [entity_id()]) :: {:ok, AriaState.t()} | {:error, atom()}
  def enable_autonomous_capabilities(state, [entity_id]) do
    current_capabilities = AriaState.RelationalState.get_fact(state, "capabilities", entity_id) || []
    new_capabilities = [:autonomous_driving, :navigation, :decision_making | current_capabilities] |> Enum.uniq()
    
    state
    |> AriaState.RelationalState.set_fact("capabilities", entity_id, new_capabilities)
    |> AriaState.RelationalState.set_fact("type", entity_id, "agent")
    {:ok, state}
  end

  @action true
  @spec disable_autonomous_capabilities(AriaState.t(), [entity_id()]) :: {:ok, AriaState.t()} | {:error, atom()}
  def disable_autonomous_capabilities(state, [entity_id]) do
    current_capabilities = AriaState.RelationalState.get_fact(state, "capabilities", entity_id) || []
    new_capabilities = current_capabilities -- [:autonomous_driving, :navigation, :decision_making]
    
    new_type = if Enum.any?(new_capabilities, &(&1 in [:decision_making, :autonomous_operation])) do
      "agent"
    else
      "entity"
    end
    
    state
    |> AriaState.RelationalState.set_fact("capabilities", entity_id, new_capabilities)
    |> AriaState.RelationalState.set_fact("type", entity_id, new_type)
    {:ok, state}
  end

  @action true
  @spec add_communication_capability(AriaState.t(), [entity_id()]) :: {:ok, AriaState.t()} | {:error, atom()}
  def add_communication_capability(state, [entity_id]) do
    current_capabilities = AriaState.RelationalState.get_fact(state, "capabilities", entity_id) || []
    new_capabilities = [:communication, :data_transmission | current_capabilities] |> Enum.uniq()
    
    state
    |> AriaState.RelationalState.set_fact("capabilities", entity_id, new_capabilities)
    |> AriaState.RelationalState.set_fact("type", entity_id, "agent")
    {:ok, state}
  end

  @action true
  @spec add_ai_capabilities(AriaState.t(), [entity_id()]) :: {:ok, AriaState.t()} | {:error, atom()}
  def add_ai_capabilities(state, [entity_id]) do
    current_capabilities = AriaState.RelationalState.get_fact(state, "capabilities", entity_id) || []
    new_capabilities = [:decision_making, :autonomous_operation | current_capabilities] |> Enum.uniq()
    
    state
    |> AriaState.RelationalState.set_fact("capabilities", entity_id, new_capabilities)
    |> AriaState.RelationalState.set_fact("type", entity_id, "agent")
    {:ok, state}
  end

  @action true
  @spec transfer_entity_ownership(AriaState.t(), [entity_id() | agent_id()]) :: {:ok, AriaState.t()} | {:error, atom()}
  def transfer_entity_ownership(state, [entity_id, new_owner_id]) do
    state
    |> AriaState.RelationalState.set_fact("owner_agent_id", entity_id, new_owner_id)
    {:ok, state}
  end

  @action true
  @spec remove_entity_ownership(AriaState.t(), [entity_id()]) :: {:ok, AriaState.t()} | {:error, atom()}
  def remove_entity_ownership(state, [entity_id]) do
    state
    |> AriaState.RelationalState.set_fact("owner_agent_id", entity_id, nil)
    {:ok, state}
  end

  @action true
  @spec set_entity_property(AriaState.t(), [entity_id() | String.t() | term()]) :: {:ok, AriaState.t()} | {:error, atom()}
  def set_entity_property(state, [entity_id, property_key, value]) do
    state
    |> AriaState.RelationalState.set_fact(property_key, entity_id, value)
    {:ok, state}
  end

  # Helper function for entity registration
  defp register_entity(state, [entity_id, type, capabilities]) do
    state
    |> AriaState.RelationalState.set_fact("type", entity_id, type)
    |> AriaState.RelationalState.set_fact("capabilities", entity_id, capabilities)
    |> AriaState.RelationalState.set_fact("status", entity_id, "available")
  end

  # Additional domain actions needed by tests
  @action true
  @spec register_manufacturing_team(AriaState.t(), []) :: {:ok, AriaState.t()} | {:error, atom()}
  def register_manufacturing_team(state, []) do
    register_manufacturing_setup(state, [])
  end

  @action true
  @spec register_basic_entities(AriaState.t(), []) :: {:ok, AriaState.t()} | {:error, atom()}
  def register_basic_entities(state, []) do
    state
    |> register_entity(["basic_entity_1", "entity", []])
    |> register_entity(["basic_entity_2", "entity", []])
    {:ok, state}
  end

  @action true
  @spec register_medical_facilities(AriaState.t(), []) :: {:ok, AriaState.t()} | {:error, atom()}
  def register_medical_facilities(state, []) do
    state
    |> register_entity(["surgery_room_1", "entity", [:sterile_environment, :surgical_equipment]])
    |> register_entity(["surgery_room_2", "entity", [:sterile_environment, :surgical_equipment]])
    {:ok, state}
  end

  @action true
  @spec set_entity_status(AriaState.t(), [entity_id() | String.t()]) :: {:ok, AriaState.t()} | {:error, atom()}
  def set_entity_status(state, [entity_id, status]) do
    state
    |> AriaState.RelationalState.set_fact("status", entity_id, status)
    {:ok, state}
  end

  @action true
  @spec assign_surgeon_to_room(AriaState.t(), [agent_id() | entity_id()]) :: {:ok, AriaState.t()} | {:error, atom()}
  def assign_surgeon_to_room(state, [surgeon_id, room_id]) do
    state
    |> AriaState.RelationalState.set_fact("assigned_room", surgeon_id, room_id)
    {:ok, state}
  end

  # Domain actions with temporal specifications following R25W1398085
  @action duration: "PT4H", requires_entities: [
    %{type: "agent", capabilities: [:cardiac_surgery, :medical_expertise]},
    %{type: "entity", capabilities: [:sterile_environment, :surgical_equipment]}
  ]
  @spec perform_surgery(AriaState.t(), [String.t() | String.t()]) :: {:ok, AriaState.t()} | {:error, atom()}
  def perform_surgery(state, [patient_id, surgery_type]) do
    state
    |> AriaState.RelationalState.set_fact("surgery_status", patient_id, "completed")
    |> AriaState.RelationalState.set_fact("surgery_type", patient_id, surgery_type)
    {:ok, state}
  end

  @action start: "2025-06-22T10:00:00-07:00", duration: "PT4H", requires_entities: [
    %{type: "agent", capabilities: [:cardiac_surgery]},
    %{type: "entity", capabilities: [:sterile_environment]}
  ]
  @spec scheduled_surgery(AriaState.t(), [String.t() | String.t() | String.t()]) :: {:ok, AriaState.t()} | {:error, atom()}
  def scheduled_surgery(state, [patient_id, start_time, duration]) do
    state
    |> AriaState.RelationalState.set_fact("surgery_status", patient_id, "scheduled")
    |> AriaState.RelationalState.set_fact("scheduled_start", patient_id, start_time)
    |> AriaState.RelationalState.set_fact("scheduled_duration", patient_id, duration)
    {:ok, state}
  end

  @action duration: "PT2H", requires_entities: [
    %{type: "agent", capabilities: [:coordination]},
    %{type: "entity", capabilities: [:sterile_environment]}
  ]
  @spec coordinate_medical_procedure(AriaState.t(), [entity_id()]) :: {:ok, AriaState.t()} | {:error, atom()}
  def coordinate_medical_procedure(state, [room_id]) do
    state
    |> AriaState.RelationalState.set_fact("coordination_status", room_id, "coordinated")
    {:ok, state}
  end

  @action duration: "PT8H", requires_entities: [
    %{type: "agent", capabilities: [:machine_operation]},
    %{type: "entity", capabilities: [:precision_cutting]}
  ]
  @spec coordinate_manufacturing_process(AriaState.t(), [entity_id()]) :: {:ok, AriaState.t()} | {:error, atom()}
  def coordinate_manufacturing_process(state, [line_id]) do
    state
    |> AriaState.RelationalState.set_fact("manufacturing_status", line_id, "coordinated")
    {:ok, state}
  end

  @spec create_domain(map()) :: AriaCore.Domain.t()
  def create_domain(opts \\ %{}) do
    domain = AriaCore.Domain.new()
    domain = AriaCore.Domain.set_verify_goals(domain, Map.get(opts, :verify_goals, true))
    domain = AriaCore.Domain.enable_solution_tree(domain, true)
    domain
  end
end
