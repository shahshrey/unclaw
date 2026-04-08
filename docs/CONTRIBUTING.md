# Contributing

Thanks for contributing.

This repo is a **reusable template** for building long-lived Claude Code agents. The bar for changes is a little different from a normal app repo: improvements should make the template more portable, safer, or easier to set up for other people.

## Contribution Principles

- Keep the template **generic**. Avoid hardcoding personal names, paths, machine-specific assumptions, or private project context.
- Prefer **clear bootstrap paths** over cleverness. Setup should be easy to inspect and debug.
- Document **why** a change exists, especially for hooks, scheduling, watchdog behavior, and memory architecture.
- Do not add secrets, personal identifiers, bot tokens, or real credentials anywhere in the repo.
- If a change is platform-specific, say so explicitly in docs and code comments.

## Good Contributions

- Better setup flow for new agents
- Safer or more observable scheduling/watchdog logic
- Cleaner memory scaffolding or promotion flow
- Better docs, examples, or troubleshooting guides
- Support for additional OS schedulers or channels when done in a reusable way

## Avoid By Default

- Personalized agent behavior that only makes sense for one user
- New complexity without a clear failure mode it solves
- Large unrelated refactors bundled into one PR
- Shipping example secrets or real personal data

## Development Notes

Before opening a PR:

1. Validate shell scripts:
   ```bash
   bash -n bin/setup.sh bin/start-agent.sh .claude/scripts/*.sh
   ```
2. Validate JSON:
   ```bash
   python3 -m json.tool templates/settings.json > /dev/null
   ```
3. Validate launchd plist templates on macOS:
   ```bash
   plutil -lint templates/launchd/*.plist
   ```
4. Re-read the README and setup docs to make sure they still match reality.

## PR Scope

- One focused improvement per PR is preferred.
- If you changed setup behavior, update the README.
- If you changed hooks, watchdog logic, or scheduling, explain the failure mode that motivated it.

## Security

If your change touches secrets handling, Telegram setup, launchd behavior, or watchdog logic, please read `docs/SECURITY.md` before opening the PR.
