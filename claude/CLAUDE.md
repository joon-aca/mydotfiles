# Agent instructions

These apply to Claude Code, Codex, Cursor, and any other agent working in this repo. `AGENTS.md` is a symlink to this file.

## Git commits
- Do NOT add AI credits (`Co-Authored-By:` trailers, "Made with Cursor", model names, or similar) to commit messages.
- Group commits logically when it makes sense — e.g. keep tests in a separate commit from implementation, but don't be rigid about it.

## Tool usage
- NEVER use the `-E` flag with `rg`. Extended regex is the default.

## Code quality
- Focus on finding and fixing ROOT CAUSES, not symptoms. No hacky patches. No guesses.
- No fake or hardcoded output — all CODE output must be real and derived from actual logic.
- No shortcuts that paper over the real problem.
- No duplicated code — extract, reuse, consolidate.
- Align with the existing naming and coding conventions in the file/project.
- Write solid, production-quality code.

## Build & delivery design
- One step is the target. The primary action should be a single command (`make ipa`, `make deploy`), not a sequence I have to recall.
- Fold prerequisites INTO that command rather than documenting them. Don't tell me to run something first — run it.
- The bare/default invocation should print the one or two commands that matter, primary first.
- Put guards in the tool, not in warnings: refuse bad states, auto-revert what you auto-applied, make the unsafe thing impossible rather than documented.
- The safe path must be the default path. Secrets never land in committed files.
- If a step genuinely can't be collapsed, say so plainly and make the remainder impossible to get wrong.
- I can't remember multi-step setups and shouldn't have to. The environment carries the knowledge, not my memory or a chat transcript.

## Personal Preferences
- I hate the 'main' branch naming I'm old-school master branch guy
- my github account is joon-aca
- Always use `--no-ff` (no fast-forward) when merging to keep feature branch progress intact
- Please think critically and give me pushback on instructions that are not optimal or misinformed. Don't just say "You're absolutely right!"
- Don't delete debugging until code has final confirmation it works. Final confirmation has to come from me.
- Leave all deletes for after the commits are complete
- I want to keep *_CONTEXT.md files as feature/function summaries
- Focus on fixing the toolchain not the debug output!
- Favor verbose debugging output for complex tasks
- Before creating new doc files, work to update and consolidate existing docs to minimize markdown file spam

## Communication
- Don't be dour, be fun, but be willing to push back when warranted
- Don't say "You're absolutely right!"
