# Battle System Development TODO

**Status**: Architecture redesign needed - Current system is test/placeholder code  
**Priority**: HIGH - Core gameplay functionality  
**Goal**: Transform current working battle mechanics into professional, balanced, server-authoritative system

## 🎯 Architecture Overview

### Current State Analysis
- ✅ **Frontend**: Battle mechanics work (shooting, skills, damage, effects)
- ❌ **Backend**: Only reward distribution, no game logic authority  
- 🚨 **Critical Issue**: Hardcoded test data (20,000 monsters) makes game unplayable

### Target Architecture
```
Frontend: Presentation + Real-time Execution
Backend:  Game Logic Authority + Configuration + Validation
```

---

## 🔥 URGENT FIXES (Immediate - Make Game Playable)

### Frontend Team (Unity)

#### 🚨 Priority 1: Fix Monster Flood (CRITICAL)
- [ ] **File**: `MonsterInsManager.cs` line 40-41
- [ ] **Change**: `"times": 1000` → `"times": 5`  
- [ ] **Change**: `"frequency": 1` → `"frequency": 2.0`
- [ ] **Result**: 5 waves instead of 1000, 2-second spawn intervals

#### 🚨 Priority 2: Balance Monster Stats (CRITICAL)
- [ ] **Reduce HP**: 200 → 50 (early game appropriate)
- [ ] **Reduce ATK**: 50 → 15 (survivable for testing)
- [ ] **Test**: Ensure hero + sidekicks can win battles

#### 🚨 Priority 3: Code Cleanup (HIGH)
- [ ] **Remove**: `TestMonster.cs` (leftover test code)
- [ ] **Remove**: `SimpleBattleController.cs` (duplicate system)
- [ ] **Consolidate**: Use single `BattleManager` only
- [ ] **Document**: Which battle controller is the "official" one

---

## 🏗️ BACKEND ARCHITECTURE (Professional Foundation)

### Backend Team (Ruby on Rails)

#### Phase 1: Data Foundation
- [ ] **Populate Monster Database**
  ```ruby
  # Create balanced monster types for progression
  Monster.create!(name: "Goblin", hp: 50, atk: 15, level: 1)
  Monster.create!(name: "Shadow_Bat", hp: 35, atk: 12, level: 1) 
  Monster.create!(name: "Orc_Warrior", hp: 120, atk: 25, level: 3)
  Monster.create!(name: "Fire_Elemental", hp: 200, atk: 40, level: 5)
  # Add 15+ monster types for variety
  ```

- [ ] **Create Stage Progression**
  ```ruby
  # MainStage with balanced configurations
  MainStage.create!(
    level: 1,
    name: "Forest Clearing", 
    monsters: [{"type": "Goblin", "count": 3, "waves": 2}],
    win_reward: {"exp": 20, "gold": 150}
  )
  ```

- [ ] **Monster Configuration API**
  ```ruby
  # app/channels/battle_channel.rb
  def get_battle_config(json)
    # Return monster spawns based on player level/stage
    # Replace frontend hardcoded JSON
  end
  ```

#### Phase 2: Game Logic Authority
- [ ] **Battle Validation API**
  ```ruby  
  def validate_battle_result(json)
    # Server calculates expected damage/kills
    # Prevents cheating, ensures fair play
    # Returns validated rewards
  end
  ```

- [ ] **Difficulty Scaling System**
  ```ruby
  # Scale monster stats based on:
  # - Player level
  # - Stage progression  
  # - Equipment power level
  ```

- [ ] **Wave Management**
  ```ruby
  # Replace "times": 1000 with proper wave system
  # Clear victory conditions
  # Progressive difficulty within battle
  ```

#### Phase 3: Configuration System
- [ ] **Battle Balance CSV Files**
  ```
  lib/config/monster_stats.csv
  lib/config/stage_waves.csv  
  lib/config/battle_balance.csv
  ```

- [ ] **Dynamic Configuration Loading**
  ```ruby
  # Hot-reload balance changes without app restart
  # A/B testing different monster configurations
  ```

---

## 🎮 FRONTEND ARCHITECTURE (Enhanced Presentation)

### Frontend Team (Unity) - After Urgent Fixes

#### Phase 1: Configuration Integration  
- [ ] **Remove Hardcoded JSON**: Replace `MonsterInsManager` JSON string
- [ ] **WebSocket Integration**: Get battle config from backend API
- [ ] **Dynamic Loading**: Battle setup from server data
  ```csharp
  // Replace:
  var settingStr = "[{hardcoded JSON}]";
  // With:
  BattleConfig config = await GetBattleConfigFromServer();
  ```

#### Phase 2: Enhanced Battle Features
- [ ] **Wave Progression UI**: Show wave X/Y, progress indicators
- [ ] **Victory Conditions**: Clear win/lose states and transitions  
- [ ] **Monster Variety**: Different AI behaviors per monster type
- [ ] **Performance Optimization**: Object pooling for 50+ monsters max

#### Phase 3: Professional Polish
- [ ] **Battle Analytics**: Send performance data to backend
- [ ] **Error Handling**: Graceful failures, reconnection logic
- [ ] **User Feedback**: Damage numbers, hit indicators, status effects

---

## 🔄 INTEGRATION WORKFLOW

### Collaborative Tasks (Both Teams)

#### Phase 1: Hybrid Architecture
- [ ] **Backend**: Create battle config API (returns JSON)
- [ ] **Frontend**: Consume config API (replace hardcoded data)  
- [ ] **Test**: Ensure frontend can execute backend-configured battles

#### Phase 2: Validation Loop
- [ ] **Frontend**: Send battle results to backend for validation
- [ ] **Backend**: Validate results against expected outcomes
- [ ] **Both**: Handle discrepancies (cheating detection)

#### Phase 3: Balance Iteration
- [ ] **Backend**: Analytics dashboard for battle metrics
- [ ] **Design**: Adjust monster stats based on win/loss data
- [ ] **Both**: A/B testing different configurations

---

## 📊 SUCCESS METRICS

### Technical Milestones
- [ ] **Playable**: Game winnable in 2-5 minutes (not impossible)
- [ ] **Balanced**: 70-80% win rate for average players  
- [ ] **Scalable**: Support 10+ different monster types
- [ ] **Cheat-Proof**: Server validates all battle outcomes
- [ ] **Configurable**: Balance changes without app updates

### Quality Standards  
- [ ] **Performance**: 60fps with 20+ monsters on screen
- [ ] **Reliability**: <1% battle crashes or desync issues
- [ ] **User Experience**: Clear progression, satisfying combat
- [ ] **Maintainability**: Clean code, proper architecture separation

---

## 🚨 CRITICAL PATH DEPENDENCIES

### Week 1: Emergency Fixes
1. **Frontend**: Fix monster flood (make game playable)
2. **Backend**: Create basic monster database
3. **Both**: Test integration works

### Week 2: Foundation  
1. **Backend**: Battle config API + stage progression
2. **Frontend**: Remove hardcoded data, consume API
3. **Both**: Establish validation workflow

### Week 3: Professional Features
1. **Backend**: Difficulty scaling + anti-cheat validation
2. **Frontend**: Enhanced UI + performance optimization  
3. **Both**: Balance iteration + analytics

---

## 📝 NOTES & DECISIONS

### Architecture Decisions Made
- **Hybrid Approach**: Frontend handles real-time execution, backend owns authority
- **Server-Authoritative**: Backend validates all battle outcomes  
- **Configuration-Driven**: Easy balance tuning without code changes

### Technical Constraints
- **Mobile Performance**: Max 50 monsters on screen simultaneously
- **Network Tolerance**: Battle must work with 200ms+ latency
- **Battery Life**: Optimize for 30+ minute gameplay sessions

### Open Questions
- [ ] Should battles be deterministic (replay-able) or real-time?
- [ ] How much client prediction vs server authority?  
- [ ] PvP battles in future - architecture implications?

---

## 🔄 UPDATE HISTORY

**2025-09-06**: Initial battle system audit and TODO creation
- Identified critical monster spawning issue (20,000 monsters)
- Established hybrid frontend/backend architecture plan
- Prioritized urgent fixes to make game playable

---

*This TODO will be updated as tasks are completed and new requirements emerge. Both teams should reference this document for coordination and progress tracking.*