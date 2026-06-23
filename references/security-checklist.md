# Security Checklist

Use this when reviewing security-sensitive code or before shipping.

## Input Validation

- [ ] User input is validated before use
- [ ] Validation is on the server side
- [ ] File uploads have size limits
- [ ] File uploads are virus-scanned
- [ ] API inputs are validated
- [ ] No trusting client-side validation

## Authentication & Authorization

- [ ] Password hashing algorithm is modern (bcrypt, argon2)
- [ ] Default credentials are changed
- [ ] Sessions have reasonable timeouts
- [ ] CSRF tokens on state-changing forms
- [ ] Access control is enforced
- [ ] Privilege escalation not possible
- [ ] API keys are rotated regularly

## Data Protection

- [ ] Sensitive data encrypted at rest
- [ ] Secrets not in source code
- [ ] Secrets use environment variables
- [ ] Database passwords rotated
- [ ] API keys rotated regularly
- [ ] SSL/TLS for all connections
- [ ] Certificate validation enabled

## Common Vulnerabilities

- [ ] No SQL injection risks (use parameterized queries)
- [ ] No command injection (avoid shell execution)
- [ ] No XXE attacks (validate XML)
- [ ] No path traversal (validate file paths)
- [ ] No SSRF (validate URLs)
- [ ] No deserialization attacks
- [ ] No race conditions
- [ ] No timing attacks

## Web Security (if applicable)

- [ ] Content-Security-Policy header set
- [ ] X-Content-Type-Options set (nosniff)
- [ ] X-Frame-Options set (DENY or SAMEORIGIN)
- [ ] Strict-Transport-Security enabled (HTTPS only)
- [ ] XSS protection enabled
- [ ] CORS properly configured
- [ ] Cookies have HttpOnly flag
- [ ] Cookies have Secure flag
- [ ] SameSite cookie policy set

## Logging & Monitoring

- [ ] No sensitive data in logs
- [ ] Login attempts are logged
- [ ] Failed authentication logged
- [ ] Suspicious activity monitored
- [ ] Audit trail maintained
- [ ] Logs are not publicly accessible

## Third-party & Dependencies

- [ ] Dependencies regularly updated
- [ ] No known vulnerabilities in dependencies
- [ ] Third-party services have SLAs
- [ ] Third-party data handling reviewed
- [ ] Vendor security practices checked
- [ ] API keys limited to needed scopes

## Deployment Security

- [ ] Secrets not in Docker images
- [ ] Build artifacts not public
- [ ] Staging environment mirrors production
- [ ] Database backups encrypted
- [ ] Backups tested regularly
- [ ] Disaster recovery plan exists
- [ ] Only necessary ports open
- [ ] Firewalls configured
- [ ] DDoS protection in place

## Code Review Specific

- [ ] No hardcoded IPs/domains
- [ ] No default/test accounts
- [ ] No commented-out security code
- [ ] Error messages don't leak information
- [ ] Rate limiting implemented (if needed)
- [ ] Sensitive operations have additional confirmation

## Documentation

- [ ] Security requirements documented
- [ ] Security assumptions stated
- [ ] Known limitations listed
- [ ] Security contacts established
- [ ] Incident response plan written
- [ ] Responsible disclosure policy in place
