# Create Pull Request

Follow these steps with caution:

1. **Environment Check**
   - Run `gh auth status` to ensure GitHub CLI is authenticated.
   - Identify the default branch: try `git symbolic-ref refs/remotes/origin/HEAD` first (fast, local-only). If it fails, fall back to:
```
     gh repo view --json defaultBranchRef -q '.defaultBranchRef.name'
```
     Let's call the result `<default-branch>`.

2. **Fetch Latest**
   - Run `git status` to check for uncommitted changes.
   - Run `git fetch origin` to update remote tracking branches.

3. **Feature Branch Creation**
   - Based on the changes made, generate a descriptive branch name (e.g., `feat/add-login-api`).
   - Create and switch to the new branch from the remote default branch:
```
     git checkout -b <new-branch-name> origin/<default-branch>
```
   - If the checkout is rejected due to conflicts with uncommitted changes, fall back to:
```
     git stash
     git checkout -b <new-branch-name> origin/<default-branch>
     git stash pop
```
     If conflicts occur after `git stash pop`, analyze the diff and resolve them carefully.

4. **Reorganize WIP Commits (if any)**
   - Run `git log origin/<default-branch>..HEAD --oneline` to list existing commits on the current branch.
   - Examine whether any commits are work-in-progress commits that should be reorganized. Signs of WIP commits include:
     - Commits prefixed with `WIP:` or `wip:`.
     - Vague or placeholder messages such as `wip`, `temp`, `save`, `checkpoint`, `fixup`, `xxx`, `todo`, etc.
     - A series of small, fragmented commits that logically belong together (e.g., `add function` followed by `fix typo` followed by `forgot to add file`).
   - If WIP commits are detected, reorganize them into clean, logical units. NOTE: interactive rebase (`git rebase -i`) does NOT work in this environment — use the non-interactive reset method instead:
```
     git reset origin/<default-branch>
```
     (mixed reset: unstages everything but keeps the working tree). Then rebuild the history: stage related files by name (`git add <files>`) and commit them group by group, so each commit is one logical unit with a proper Conventional Commits message. Do NOT use `git reset --soft` here — it leaves all changes staged, so the first commit would sweep everything into one. If a single file mixes multiple logical changes, `git add -p` is also unavailable — keep those changes in one commit rather than splitting hunks.
   - Alternative for a pure squash/fixup (no reordering or message editing needed): a scripted rebase works without an editor, e.g. `GIT_SEQUENCE_EDITOR='sed -i "" "2,\$s/^pick/fixup/"' git rebase -i origin/<default-branch>`. Prefer the soft-reset method when in doubt.
   - Guidelines for reorganization:
     - Group changes by logical unit of work (e.g., one commit per feature, bug fix, or refactor).
     - Each resulting commit should be self-contained: it should compile/pass tests on its own when possible.
     - Write clear, descriptive commit messages in English following Conventional Commits (e.g., `feat: ...`, `fix: ...`, `refactor: ...`).
     - Do NOT simply squash everything into a single commit unless all changes genuinely represent one logical unit.
   - After reorganizing, verify the result with `git log --oneline` and `git diff origin/<default-branch>..HEAD` to ensure no changes were lost (the diff must be identical to what it was before the reset).
   - If the scripted rebase encounters conflicts, resolve them carefully by examining the diff context, then continue with `git rebase --continue`.

5. **Stage Changes**
   - Run `git status` to review which files will be staged.
   - Stage only the relevant files by name. Do NOT use `git add .` or `git add -A`.
   - Exclude unintended files such as logs, temp files, `.env`, credentials, or large binaries.
   - Run `git diff --cached --stat` to confirm the staged changes are correct.

6. **Commit & Push**
   - Create a commit message following **Conventional Commits** (e.g., `feat: ...`, `fix: ...`).
   - The message must be in English.
   - Use a heredoc to support multi-line messages:
```
     git commit -m "$(cat <<'EOF'
     <type>: <concise summary>

     <optional body explaining the "why">
     EOF
     )"
```
   - If a pre-commit hook fails, fix the issue and create a new commit. Do NOT use `--no-verify`.
   - Run `git push -u origin HEAD`

7. **PR Creation**
   - Run `gh pr list --head <new-branch-name>` to check if a PR already exists for this branch. If one exists, show the existing PR URL and stop.
   - Run `git log origin/<default-branch>..HEAD --oneline` to collect all commits in this branch.
   - Generate the PR body with the following structure:
     - **Summary**: A concise overview of the changes based on the code diff.
     - **Commits**: A list of commits from the log above.
   - Use a heredoc for the body to ensure correct formatting:
```
     gh pr create --base <default-branch> --title "<title>" --body "$(cat <<'EOF'
     ## Summary
     <summary>

     ## Commits
     <commits>
     EOF
     )"
```
   - Ensure the title and body are professional and written in English.

