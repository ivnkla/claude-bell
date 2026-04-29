# claude-bell - test instructions

Run tests for freshly installed hooks from a bash script.

Run these three steps in order, announcing each one before triggering it.

Wait for the user to confirm "ok" before moving to the next step.

1. **Stop** - complete a response normally. The Stop hook fires automatically at the end of this message.

2. **AskUserQuestion** - ask the user a question using the `AskUserQuestion` tool (e.g. "Did you hear the sound?"). This triggers the `PostToolUse` hook with the `AskUserQuestion` matcher.

3. **PermissionRequest** - run a Bash command (e.g. `grep -r "test" /tmp`). Claude Code will prompt for permission, triggering the `PermissionRequest` hook.


