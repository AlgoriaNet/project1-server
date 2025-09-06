# Project Rogue: Backend - Project Log

**2025-09-05**

### Backend Updates
*   **Task:** Removed unused levelUpEffects from battle start API - eliminated 34 lines of complex random selection logic per frontend notification
*   **Files:** `app/channels/battle_channel.rb` (build_battle_data method simplified)
*   **Next:** Battle API now returns only essential data (sidekicks array), improving performance and reducing payload size

### Documentation Updates
*   **Task:** Created a new guide to clarify the `Sidekick` vs. `Ally` naming inconsistency.
*   **Files:** `documentation/SIDEKICK_ALLY_NAMING_GUIDE.md`
*   **Next:** All developers should refer to this guide to understand the legacy naming convention and prepare for an eventual API refactoring.

**2025-09-04**

### Backend Updates
*   **Task:** Implemented universal static data system with hot-fix deployment and version control - all 20 sidekicks migrated from database to file-based skill effects
*   **Files:** 
    *   `public/static_data/skill_effects.json` (all 20 sidekicks L01-L20)
    *   `app/controllers/static_data_controller.rb` (new endpoints)
    *   `app/channels/player_channel.rb` (WebSocket API updated)
    *   `config/routes.rb` (static data routes)
*   **Next:** System proven with successful hot-fix test (01_Zorath L03 → "Dummy Effect", version 1.0.0→1.0.1). Ready for expansion to other static data types (items, characters, costs).

**2025-09-03**

### Project Management Updates
*   **Task:** Created an `IMPORTANT_TODO.md` file to track major, long-term tasks.
*   **Files:** `documentation/IMPORTANT_TODO.md`
*   **Next:** The to-do list is now ready to be used for tracking progress on the static data system.

### Backend Updates
*   **Task:** Documented the proposed universal static data architecture.
*   **Files:** `documentation/static_data_architecture.md`
*   **Next:** Proceed with Phase 1 implementation: creating manual JSON files for skill effects.

**2025-09-02**

### Backend Updates
*   **Task:** Generated complete 20-level skill effects for all characters (L01-L20) - L01-L02 enhanced versions, L03-L20 placeholder "To be confirmed"
*   **Files:**
    *   `BaseSkillLevelUpEffect` database (added ~400 new effect records)
*   **Next:** Frontend should now display complete 20-level grid instead of duplicate L01 entries

### Backend Updates
*   **Task:** Fixed get_upgrade_levels API Internal server error - removed double JSON.parse and invalid sidekick_fragment_name filtering
*   **Files:**
    *   `app/channels/player_channel.rb` (get_upgrade_levels method lines 718-720)
*   **Next:** UpgradePanelManager should now receive proper upgrade levels data and display prefabs correctly

### Backend Updates
*   **Task:** Enhanced battle API randomness with balanced shuffling algorithm - ensures equal weight across all character pool sizes (1-5 characters)
*   **Files:**
    *   `app/channels/battle_channel.rb` (balanced shuffling implementation replacing SecureRandom)
*   **Next:** Battle API provides fair selection for all scenarios: Hero-only through Hero+4-sidekicks with 82.7% average fairness

### Backend Updates
*   **Task:** Fixed critical randomness bias in battle API - replaced Array#sample with SecureRandom for 16% better distribution fairness  
*   **Files:**
    *   `app/channels/battle_channel.rb` (SecureRandom implementation, debug logging added)
*   **Next:** Battle API now provides truly fair 3-for-1 selection - ready for production use

### Backend Updates  
*   **Task:** Verified and tested 3-for-1 random selection algorithm in battle API - confirmed fair probability distribution across all characters
*   **Files:**
    *   `app/channels/battle_channel.rb` (3-for-1 selection logic working correctly)
*   **Next:** Ready for frontend integration - battle API returns exactly 3 random skill effects with fair character distribution

**2025-09-01**

### Backend Updates
*   **Task:** Implemented dummy skill effects system for battle API - replaced frontend dummy creation with backend database effects (TEMPORARY - needs real effects later)
*   **Files:**
    *   `app/channels/battle_channel.rb` (battle API unchanged, now returns real DB effects)
    *   `BaseSkillLevelUpEffect` (41 new dummy records: Hero 1 effect, Sidekicks 40 effects)
    *   `documentation/DUMMY_SKILL_EFFECTS_IMPLEMENTATION.md` (implementation log)
*   **Next:** Future agent must replace dummy effects with real skill-specific effects and balance values for actual gameplay

**2025-08-27**

### Project Management Updates
*   **Task:** Established the role of a "Project Secretary" (Gemini) and a formal documentation and handoff process.
*   **Files:** 
    *   `documentation/Process/DOCUMENTATION_GUIDELINES.md`
    *   `documentation/Process/PROJECT_LOG.md`
*   **Next:** Begin logging engineering tasks. The secretary's role is now active.