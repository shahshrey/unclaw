# Security Policy

This repo is a template for running powerful local agents. That means small mistakes can become dangerous if the template encourages bad defaults.

## Scope

Please report issues related to:

- secrets handling
- accidental credential exposure
- unsafe default permissions
- prompt or tool-policy bypass paths
- watchdog / scheduler behavior that can create duplicate consumers or unintended background execution
- channel integrations that can leak messages or attachments

## Safe Defaults

The template is designed around a few principles:

- Secrets live **outside the repo** whenever possible
- Runtime logs are gitignored
- Messaging credentials are stored under `~/.claude/channels/...`, not in the project
- The agent should run as a **single long-lived session**, not a swarm of duplicate consumers
- Hooks, watchdogs, and scheduling should be inspectable and repairable

## Reporting a Vulnerability

Please do **not** open a public issue for a credential leak or security bug that could affect real users.

Instead, report it privately to the maintainer with:

- what component is affected
- exact reproduction steps
- impact
- suggested mitigation if you have one

## Operational Advice

If you suspect compromise:

1. Rotate any bot/API tokens immediately
2. Stop the running agent session
3. Disable launchd jobs or other schedulers
4. Review runtime logs under `.claude/runtime/`
5. Remove any accidentally committed secrets from history before publishing

## Out of Scope

These are usually not security vulnerabilities by themselves:

- local-only debugging logs that are already gitignored
- `ws://` or cleartext traffic on a private LAN unless it crosses a trust boundary
- behavior that only occurs after the operator explicitly disables safeguards
