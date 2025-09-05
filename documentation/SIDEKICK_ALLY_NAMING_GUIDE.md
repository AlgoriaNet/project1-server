# Naming Conventions and Legacy Terms

This document clarifies critical naming conventions used in the project to prevent confusion and ensure consistency.

## 1. `Sidekick` vs. `Ally`: The Official Convention

The official and standard term for companion characters in this project is **`Sidekick`**. This is the name used consistently throughout the backend codebase, including:

*   **Database Models:** `Sidekick`, `BaseSidekick`
*   **Database Schema:** `sidekicks`, `base_sidekicks` tables
*   **Internal Logic:** All services, controllers (internal), and channels.

### The `Ally` Legacy Term

You will frequently encounter the term **`Ally`** in the context of the client-facing API and WebSocket communications.

*   **API Endpoint:** `/api/allies/:ally_id/...`
*   **WebSocket Parameters:** `ally_id`, `ally_name`
*   **API Documentation:** `API_GUIDE.md`

**This is a legacy naming convention.** The term `Ally` should be treated as a public-facing **alias** for `Sidekick`. It persists in the API to maintain compatibility with the client application.

### The Golden Rule

*   When working with the **API** (e.g., calling an endpoint, handling WebSocket messages), you will use `ally_id` or `ally_name`.
*   When working inside the **backend codebase**, you will use `Sidekick` models and variables.

The translation between these terms happens at the API boundary, primarily in `app/controllers/api/allies_controller.rb` and `app/channels/player_channel.rb`.

### ID and Name Mapping

It is critical to understand what the API parameters refer to:

*   `ally_id` (API) -> `fragment_name` (on the `BaseSidekick` model)
    *   *Example:* `"04_Aurelia"`
*   `ally_name` (API) -> Also `fragment_name` (on the `BaseSidekick` model)
    *   *Note: The use of `ally_name` is inconsistent and `ally_id` is preferred.*
*   `sidekick.id` (Database) -> The primary key of the player's specific `Sidekick` instance.
*   `sidekick.base_id` (Database) -> The foreign key to the `base_sidekicks` table.

**For all API calls, the client should send the `fragment_name` as the identifier.**

---

**[PLAN]** - A future coordinated effort with the frontend team will involve a breaking change to refactor the API. The term `ally` will be deprecated and replaced with `sidekick` across all endpoints and parameters to resolve this inconsistency permanently.
