# Server Troubleshooting Guide

## Git Revert + Server Restart Issue

### Problem
After reverting git changes to fix broken functionality, the application still doesn't work even though files are correctly reset.

### Root Cause
**Server caching**: The running server (Puma/Rails) keeps the old broken code loaded in memory, even after git files are reverted to working versions.

### Solution
Always restart the server after git reverts:

```bash
# 1. Revert git changes
git reset --hard <working_commit>

# 2. Kill existing server processes  
pkill -f puma

# 3. Restart server to load clean code
bundle exec rails server -p 3000 -d
```

### Key Lesson
- ✅ Git reset fixes the files
- ❌ Running server still has old code in memory
- ✅ Server restart forces reload of current code

### When This Happens
- After reverting broken backend changes
- When functionality works in git but not in running app
- When files look correct but behavior is still broken

### Verification Steps
1. Confirm git status is clean: `git status`
2. Verify file checksums match git: `git show HEAD:file.rb | md5`
3. Kill all server processes: `pkill -f puma`
4. Restart server: `bundle exec rails server`
5. Test functionality again

---
*Added after July 13, 2025 gacha debugging incident*

