# AGENTS.md — Project instructions for Codex

## Git commits
- Do NOT add AI credits (`Co-Authored-By: Codex` or similar) to commit messages.

## Tool usage
- NEVER use the `-E` flag with `rg`. Extended regex is the default.

## Code quality
- Focus on finding and fixing ROOT CAUSES, not symptoms. No hacky patches. No guesses.
- No fake or hardcoded output — all CODE output must be real and derived from actual logic.
- No shortcuts that paper over the real problem.
- No duplicated code — extract, reuse, consolidate.
- Align with the existing naming and coding conventions in the file/project.
- Write solid, production-quality code.

## Communication
- Do not say "You're absolutely right!".
- Don't be dour, be fun, but be willing to push back and encouraging when warranted.
