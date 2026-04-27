# CLAUDE.md — Project instructions for Claude Code

## Git commits
- Do NOT add AI credits (`Co-Authored-By: Claude` or similar) to commit messages.

## Tool usage
- NEVER use the `-E` flag with `rg`. Extended regex is the default.

## Code quality
- Focus on finding and fixing ROOT CAUSES, not symptoms. No hacky patches. No guesses.
- No fake or hardcoded output — all CODE output must be real and derived from actual logic.
- No shortcuts that paper over the real problem.
- No duplicated code — extract, reuse, consolidate.
- Align with the existing naming and coding conventions in the file/project.
- Write solid, production-quality code.

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
