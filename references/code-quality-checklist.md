# Code Quality Checklist

Use this checklist when reviewing code or before submitting for review.

## Correctness

- [ ] Code does what the spec requires
- [ ] All requirements are met
- [ ] No off-by-one errors
- [ ] Handles null/undefined inputs
- [ ] Error cases are handled
- [ ] Doesn't introduce regressions

## Clarity

- [ ] Variable names are descriptive
- [ ] Function names are clear (verb + noun)
- [ ] Complex logic is commented (WHY, not WHAT)
- [ ] No magic numbers (use constants)
- [ ] No unnecessary abstraction
- [ ] Single responsibility per function

## Testing

- [ ] All happy paths are tested
- [ ] Edge cases are covered
- [ ] Error cases are tested
- [ ] Tests are independent (no shared state)
- [ ] Tests clearly document behavior
- [ ] Test coverage >= 80%

## Performance

- [ ] No obvious inefficiencies
- [ ] No N+1 queries
- [ ] No unnecessary allocations
- [ ] Loops are optimized
- [ ] No blocking on I/O
- [ ] Caching used where appropriate

## Security

- [ ] No hardcoded secrets
- [ ] Input is validated
- [ ] SQL/command injection risks addressed
- [ ] XSS prevention in place (if web)
- [ ] CSRF tokens (if form-based)
- [ ] Sensitive data not logged
- [ ] No timing attacks
- [ ] Dependencies are up-to-date

## Style & Consistency

- [ ] Follows repo conventions
- [ ] Consistent naming patterns
- [ ] Consistent code structure
- [ ] Proper indentation/formatting
- [ ] Linter passes
- [ ] No dead code

## Documentation

- [ ] README updated (if needed)
- [ ] Function documentation complete
- [ ] Complex algorithms explained
- [ ] Setup instructions clear (if needed)
- [ ] Examples provided (if needed)
- [ ] Deprecations noted

## Dependencies

- [ ] New dependencies justified
- [ ] No circular dependencies
- [ ] Minimal external dependencies
- [ ] Dependencies are maintained
- [ ] License compatibility checked
- [ ] Size impact acceptable

## Before Shipping

- [ ] All tests pass
- [ ] No console.log/debug statements
- [ ] No commented-out code blocks
- [ ] No temporary variables
- [ ] CHANGELOG updated
- [ ] Version bumped (if needed)
- [ ] Deployment plan documented
