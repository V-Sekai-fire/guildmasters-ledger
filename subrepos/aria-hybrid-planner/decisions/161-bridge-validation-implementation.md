# ADR-161: Bridge Validation Implementation

<!-- @adr_serial R25W010BFF3 -->

**Status:** Active (Paused)  
**Date:** 2025-06-23  
**Priority:** HIGH

## Context

The Timeline bridge management functions lack proper validation logic, causing test failures where expected validation errors are not raised. Specifically, the `add_bridge/2` function doesn't validate for duplicate bridge IDs, and other validation scenarios are not properly handled.

### Failing Tests

1. **Timeline.TimelineBridgeTest** - "add_bridge/2 validates bridge placement"

   ```
   Expected exception ArgumentError but nothing was raised
   code: assert_raise ArgumentError, ~r/Bridge with ID 'decision_1' already exists/, fn ->
   ```

### Root Cause Analysis

**Current Implementation Issues:**

- `add_bridge/2` doesn't check for existing bridge IDs before adding
- `validate_bridge_placement/2` exists but isn't called by `add_bridge/2`
- Validation logic is present but not integrated into the main workflow
- Error handling is inconsistent across bridge operations

**Expected Behavior:**

- `add_bridge/2` should raise `ArgumentError` for duplicate bridge IDs
- Bridge placement validation should be enforced automatically
- Consistent error handling across all bridge operations

## Decision

**Implement comprehensive bridge validation with automatic enforcement in all bridge operations.**

We'll integrate existing validation logic into bridge management functions and add missing validation scenarios.

### Rationale

1. **Data Integrity**: Prevent invalid bridge states from being created
2. **Error Prevention**: Catch validation issues early rather than during execution
3. **API Consistency**: All bridge operations should have consistent validation
4. **Test Compliance**: Implementation should match test expectations
5. **Debugging Support**: Clear error messages help identify issues quickly

## Implementation Approach

The implementation will integrate existing validation logic into bridge management functions and add missing validation scenarios to ensure data integrity and consistent error handling.

### Key Implementation Areas

1. **Core Validation Integration**: Update bridge functions to call validation before state changes
2. **Validation Logic Enhancement**: Enhance duplicate ID validation and boundary checks
3. **Integration Points**: Ensure validation across all bridge operations
4. **Error Handling**: Standardize error messages and exception types

### Expected Outcomes

- Bridge validation will be automatically enforced in all operations
- Clear error messages will help identify validation issues
- Consistent API behavior across all bridge functions
- Prevention of invalid bridge states

## Consequences

### Positive

- **Data Integrity**: Invalid bridge states are prevented
- **Better Error Messages**: Clear feedback when validation fails
- **Consistent API**: All bridge operations have uniform validation
- **Easier Debugging**: Validation failures provide specific error context

### Negative

- **Performance Impact**: Additional validation checks on every operation
- **Breaking Changes**: Previously accepted invalid states now raise errors
- **Complexity**: More code paths to test and maintain

## Related ADRs

- **ADR-158**: Comprehensive Timeline Test Suite Validation (parent issue)
- **ADR-160**: Timeline Bridge Storage Architecture (related bridge functionality)

## Implementation Notes

### Validation Rules to Implement

1. **Duplicate ID Prevention**

   ```elixir
   def add_bridge(timeline, bridge) do
     case validate_bridge_placement(timeline, bridge) do
       :ok -> do_add_bridge(timeline, bridge)
       {:error, reason} -> raise ArgumentError, reason
     end
   end
   ```

2. **Bridge Placement Validation**
   - Bridge ID must be unique within timeline
   - Bridge position cannot be at interval start or end boundaries
   - Bridge type must be valid
   - Bridge position must be a valid DateTime

3. **Error Message Standards**

   ```elixir
   "Bridge with ID '#{bridge.id}' already exists"
   "Bridge cannot be placed at interval boundary"
   "Invalid bridge type: #{bridge.type}"
   ```

### Integration Strategy

- Modify existing functions to call validation before state changes
- Use pattern matching on validation results to handle errors
- Maintain backward compatibility where possible
- Add comprehensive test coverage for all validation scenarios
