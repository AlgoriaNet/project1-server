# Project Status Report (as of 2025-08-27)

### 1. High-Level Summary

The project is a functional Ruby on Rails backend server for a mobile RPG. The core gameplay loop of collecting and upgrading sidekicks, battling through stages, and enhancing equipment is well-established. The server has a real-time WebSocket API for gameplay and a standard HTTP API for other operations. The primary areas needing work are not in core features, but in game balance (costs, stats), content completeness (placeholder skills, missing descriptions), and formalizing the testing and code quality processes.

---

### 2. Core Systems Status

*   **✅ Completed**
    *   **User & Player System**: Full user authentication (email/guest), player data model, and JWT-based sessions are in place.
    *   **Sidekick System**: The foundation for collecting, leveling up (1-20), and starring up (0-5) the 20 unique sidekicks is complete.
    *   **Battle & Formations**: The ability to create battle formations with up to 4 sidekicks and progress through stages is implemented.
    *   **Equipment & Gemstones**: Core logic for equipping, replacing, and enhancing equipment and gemstones is functional. The "washing" (re-rolling) system is also implemented.
    *   **Monetization**: The framework for handling IAPs (Apple/Google), subscriptions (monthly cards), and a Gacha (draw) system is implemented.
    *   **Real-time API**: A robust set of WebSocket channels (`battle`, `equipment`, `draw`, `purchase`, etc.) provides the foundation for real-time gameplay.

*   **🟡 In-Progress / Needs Work**
    *   **Skill System**: While the `BaseSkill` model exists, several skills are explicitly marked as `Skill_Dummy` placeholders in `base_skills.csv`. The `SKILL_SYSTEM_ANALYSIS.md` indicates that several skills from the original design are not yet implemented.
    *   **Equipment "Upgrade" Feature**: The `CLAUDE.md` file notes that the "upgrade" function within the Forge system (for quality/tier upgrades) is not yet implemented.
    *   **Game Balance**: `CLAUDE.md` explicitly states that gold costs, skill book requirements, and combat stats need significant balancing work. The current values in the CSVs may not be final.

---

### 3. Key Data & Content

*   **Sidekicks**: 20 unique sidekicks are defined in `base_sidekicks.csv`.
*   **Skills**: 20 skills are defined in `base_skills.csv`, but at least 6 of these are placeholders.
*   **Leveling Costs**: A complete cost table for levels 1-100 (skillbooks and gold) is defined in `level_up_costs.csv`.
*   **Star Upgrades**: Costs for all 5 star levels are defined in `star_upgrade_costs.csv`.

---

### 4. Outstanding TODOs & Known Issues

This is a summary of critical items from the documentation:

*   **Critical Process Warning**: The server **must** be manually restarted (`pkill -f puma`) after any `git revert` or direct database modification to prevent critical data consistency bugs.
*   **Documentation Debt**: The testing framework and any linting/code quality tools need to be formally documented.
*   **Content TODOs**:
    *   Many skill upgrade effects lack proper descriptions.
    *   The "Hero Gun Shooting" skill needs to be created.
    *   Several other skills from the design charts are missing (Tornado, Aerial Strafe, etc.).
*   **Data Loss Incidents**: The project has experienced at least two major data loss incidents due to improper use of generation scripts (`GenerateBaseEquipment.generate`) and test cleanup scripts (`destroy_all`). This highlights a need for more robust data management procedures.
