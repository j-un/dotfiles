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

4. **Stage Changes**
   - Run `git status` to review which files will be staged.
   - Stage only the relevant files by name. Do NOT use `git add .` or `git add -A`.
   - Exclude unintended files such as logs, temp files, `.env`, credentials, or large binaries.
   - Run `git diff --cached --stat` to confirm the staged changes are correct.

5. **Commit & Push**
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

6. **PR Creation**
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

