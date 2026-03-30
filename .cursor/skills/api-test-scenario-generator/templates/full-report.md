# API Test Scenarios: {{METHOD}} {{ENDPOINT}}

Generated on: {{DATE}}

## Overview

{{OVERVIEW}}

## Test Scenarios

{{SCENARIO_TABLE}}

{{DEPENDENCY_GRAPH_SECTION}}

## Notes

- **Priority**: `High (H) > Medium (M) > Low (L)` and is assigned by the generator as a starting point based on risk and business impact
- **Recommended Test Level**: Use the testing pyramid as a heuristic, not a fixed quota
- **HTTP Status**: Expected response code for each scenario

## Testing Pyramid Guidelines

- **Unit Tests**: Fast validation, boundary cases, and pure business-rule checks
- **Integration Tests**: API contracts, authentication, RBAC, persistence, and service interactions
- **E2E Tests**: A small set of critical cross-system journeys only

## Warnings and Assumptions

{{WARNINGS_SECTION}}

## Implementation Tips

{{IMPLEMENTATION_TIPS}}
