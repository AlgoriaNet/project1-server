# Documentation Guidelines

This document outlines the best practices and standards for creating and maintaining documentation for this project. Adhering to these guidelines ensures that our documentation remains clear, consistent, and useful for all contributors, including developers and AI assistants.

## 1. Location
All project documentation files (e.g., `.md` files) must be located within the project's `/documentation` directory. This centralization makes documents easy to find and manage.

## 2. Hierarchy of Authority
When discrepancies arise, the source code and configuration files are the ultimate source of truth, not the documentation. Documentation should always be a reflection of the current state of the project's code.

- **Priority Order**:
  1. Source Code (`.rb`, `.cs`, `.js`, etc.)
  2. Configuration Files (`.csv`, `.yml`, etc.)
  3. Documentation Files (`.md`)

If you find documentation that is out of sync with the code, please update it to match the code's behavior.

## 3. Handling Future Plans & Remarks
Our documentation is a living resource that includes plans for future development. It's critical to handle these notes correctly.

- **Marking Plans**: Any text describing a future feature or a planned change that is not yet implemented must be clearly marked.
  - **Good Example**: `**[PLAN]** - We intend to refactor this service to use the new payment gateway in Q4.`
  - **Bad Example**: `This service uses the new payment gateway.` (This is incorrect if not yet implemented).

- **Verifying Plans**: If you are working on a feature and notice a `[PLAN]` remark that seems to have been implemented, please verify it.
  - **Action**: Check with the project lead or the original author of the plan. If the plan is now a reality, the `[PLAN]` remark should be removed to reflect the current state.

- **Outdated Plans**: If you encounter a plan that seems to conflict with the current implementation or seems obsolete, do not delete it.
  - **Action**: Raise the issue with the team to confirm if the plan is still valid or should be officially deprecated and removed from the documentation.

## 4. Revision History
For significant changes to a document, add a note in a "Revision History" section at the end of the file. This provides a clear log of what changed, when, and by whom.

- **Format**: Use a simple, clear text format.

```
## 🔄 Revision History

**YYYY-MM-DD (Author):**
- A brief, high-level summary of the change.
- Another summary point if needed.
```

## 5. AI Engineer Standard Operating Procedures

This section is for AI engineers (e.g., Claude instances) working on any sub-project of `Rogue`.

### A. Your First Instruction

Your first task upon starting a new session should be to read this `DOCUMENTATION_GUIDELINES.md` file to understand the project's workflow. The user's only instruction to you should be: *"Read the documentation guidelines."*

### B. Reading The Project Log (Catching Up)

You do not need to read the entire project log. To get the necessary context for your work session:
1.  Open the project's log file: `documentation/Process/PROJECT_LOG.md`.
2.  **Read the entries for the last 2-3 days.** This will inform you of the latest progress, decisions, and any blockers from other team members.

### C. Writing To The Project Log (Your Handoff)

At the end of each major task, you **must** add an entry to this project's `documentation/PROJECT_LOG.md`. This is your handoff to the "next shift" and to the other project members.

1.  Use the following heading for your entry: `### [Backend/Frontend] Updates`.
2.  Use this exact 3-bullet format:
    *   **Task:** (A one-line summary of what was accomplished)
    *   **Files:** (A list of the most important files that were changed)
    *   **Next:** (A brief note on blockers or what's next)

### D. Logging Granularity and Git Commits

**When to Write a Log Entry?**

A log entry is required at any "natural handoff point." This typically means:
- At the end of your work session.
- After completing a logical feature or user story.
- When you are blocked and cannot proceed without input or work from another team member.

The goal is to summarize a logical chunk of work, not every single small step.

**Avoiding Duplication with Git Commits**

The project log and git commit history serve different purposes. The log is for team status and handoffs; git history is for the technical code history. To avoid duplicating effort:
1. Write a clear, descriptive commit message as usual.
2. When creating your log entry, you can **copy your commit message** for the `Task:` bullet point.
3. Then, add the `Files:` and `Next:` bullet points, which provide the higher-level context for the team that does not belong in a commit message.
