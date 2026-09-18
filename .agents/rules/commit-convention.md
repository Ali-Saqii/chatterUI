# Git Commit Message Convention

Whenever making a Git commit in this project, follow this exact commit message convention — a bracketed tag followed by a short, lowercase-start description of the change:

- `[Feature] <description>` — new functionality being added (a new endpoint, screen, model, service, etc.)
- `[Bug] <description>` — fixing broken/incorrect behavior
- `[Patch] <description>` — small fixes or tweaks to existing code that aren't full bug fixes (typos, minor config, small adjustments)
- `[Updation] <description>` — updating/modifying existing functionality (changing an existing endpoint, refactoring a model, editing existing UI)
- `[Refactor] <description>` — restructuring code without changing behavior
- `[Docs] <description>` — documentation, comments, README changes
- `[Config] <description>` — environment, dependency, or project config changes
- `[Test] <description>` — adding or updating tests
- `[Chore] <description>` — routine maintenance (formatting, cleanup, .gitignore changes)

## Rules
1. One tag per commit — pick the single most accurate tag for what changed.
2. Keep the description short (under ~60 characters), specific, and in plain English — e.g. `[Feature] add friend request accept/decline routes`.
3. If a commit touches multiple unrelated things, split it into separate commits with their own tags instead of combining them.
4. Never use a generic message like "update" or "fix" alone — always pair the tag with what specifically changed.
5. Match the exact bracket + capitalization style shown above — `[Feature]`, not `[feature]` or `[FEATURE]`.
