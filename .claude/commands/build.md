---
description: Build code incrementally, one task slice at a time
---

# /build [task-name]

Build the next task from the plan.

**Phase: BUILD**

When invoked with a task name:

1. Find the task in `PLAN.md`
2. Understand requirements, context, and dependencies
3. Plan the implementation (TDD: tests first)
4. Implement incrementally
5. Commit with clear messages
6. Verify with tests passing

For hands-off execution with `build auto`:
- Generate plan from spec
- Execute each task autonomously
- Pause on failures or risky decisions
- Every step is test-driven

Reference the `incremental-implementation` and `test-driven-development` skills.
