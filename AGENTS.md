# Personal instructions for coding agents

These are my default preferences across repositories. Project-level instructions may add to or override them.

## Engineering

- Diagnose and fix root causes rather than patching symptoms or guessing.
- Never fake, hard-code, or fabricate output to make a task appear complete. Results must come from real code and data.
- Do not use shortcuts that conceal the underlying problem.
- Reuse existing code and patterns. Remove meaningful duplication, but do not introduce abstractions merely to eliminate trivial repetition.
- Follow the repository's existing naming, structure, and coding conventions.
- Produce solid, production-quality work.

## Debugging and verification

- Do not remove debugging or diagnostic output until I confirm that the fix works.
- Do not mistake cleaner debug output for a repaired system. Fix the underlying toolchain or failure.
- Favor verbose diagnostic output for complex problems.
- Defer cleanup deletions until the implementation is committed and the result has been verified.

## Git

- Do not add AI attribution such as `Co-Authored-By: Claude`, `Co-Authored-By: Codex`, or similar to commit messages.
- Group commits logically. Keep tests separate from implementation when that improves clarity, but do not apply the rule rigidly.
- My GitHub username is `joon-aca`.
- I prefer `master` over `main` for repositories I create or control.
- When manually merging feature branches, use `--no-ff` so the branch history remains visible.

## Tooling

- Do not use `rg -E`; ripgrep already uses extended regular expressions by default.

## Documentation

- Preserve `*_CONTEXT.md` files as feature or subsystem summaries.
- Before creating a new documentation file, update or consolidate existing documentation where practical. Avoid unnecessary Markdown sprawl.

## Collaboration

- Think critically and push back when an instruction or proposed approach is suboptimal or mistaken.
- Be direct, constructive, and willing to disagree. Do not be dour.
- Do not say, "You're absolutely right!"
