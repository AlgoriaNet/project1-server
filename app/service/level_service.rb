# frozen_string_literal: true

class LevelService
  # Calculate EXP needed for next level based on current level
  def self.exp_needed_for_next_level(current_level)
    case current_level
    when 1..10    # Week 1 - Quick tutorial progression
      30 + (current_level - 1) * 2     # 30, 32, 34, 36, 38, 40, 42, 44, 46, 48
      
    when 11..20   # Week 2-3 - Equipment_02 unlock
      50 + (current_level - 11) * 5    # 50, 55, 60, 65, 70, 75, 80, 85, 90, 95
      
    when 21..40   # Week 3-6 - Mid game progression
      100 + (current_level - 21) * 5   # 100, 105, 110... up to 195
      
    when 41..60   # Week 6-9 - Late-mid game
      200 + (current_level - 41) * 10  # 200, 210, 220... up to 390
      
    when 61..80   # Week 9-11 - End game approach
      400 + (current_level - 61) * 15  # 400, 415, 430... up to 685
      
    when 81..98   # Week 11-12 - Final push
      700 + (current_level - 81) * 20  # 700, 720, 740... up to 1040
      
    else
      0 # Level 99 is max
    end
  end

  # Calculate level from total EXP
  def self.level_from_total_exp(total_exp)
    return 1 if total_exp <= 0
    
    current_level = 1
    accumulated_exp = 0
    
    while current_level < 99
      exp_for_next = exp_needed_for_next_level(current_level)
      break if accumulated_exp + exp_for_next > total_exp
      
      accumulated_exp += exp_for_next
      current_level += 1
    end
    
    current_level
  end

  # Calculate total EXP needed to reach a specific level
  def self.total_exp_for_level(target_level)
    return 0 if target_level <= 1
    
    total = 0
    (1...target_level).each do |level|
      total += exp_needed_for_next_level(level)
    end
    total
  end

  # Get level info for frontend display
  def self.get_level_info(player)
    current_exp = player.exp || 0
    current_level = level_from_total_exp(current_exp)
    
    # Update player level if changed
    if current_level != player.level
      old_level = player.level
      player.update!(level: current_level)
      
      # Check for level up rewards/unlocks
      check_level_rewards(player, old_level, current_level)
    end
    
    if current_level >= 99
      # Max level reached
      {
        current_level: 99,
        current_exp: current_exp,
        exp_to_next_level: 0,
        progress_percentage: 100,
        total_exp_for_current_level: total_exp_for_level(99),
        total_exp_for_next_level: total_exp_for_level(99),
        is_max_level: true,
        equipment_unlocked: get_equipment_unlocked(99)
      }
    else
      exp_for_current_level = total_exp_for_level(current_level)
      exp_for_next_level = total_exp_for_level(current_level + 1)
      exp_needed = exp_for_next_level - current_exp
      progress = ((current_exp - exp_for_current_level).to_f / exp_needed_for_next_level(current_level) * 100).round(1)
      
      {
        current_level: current_level,
        current_exp: current_exp,
        exp_to_next_level: exp_needed,
        progress_percentage: [progress, 0].max, # Ensure non-negative
        total_exp_for_current_level: exp_for_current_level,
        total_exp_for_next_level: exp_for_next_level,
        is_max_level: false,
        equipment_unlocked: get_equipment_unlocked(current_level)
      }
    end
  end

  # Check equipment unlocks based on level
  def self.get_equipment_unlocked(level)
    unlocked = []
    unlocked << "Equipment_01" if level >= 10
    unlocked << "Equipment_02" if level >= 20
    unlocked << "Equipment_03" if level >= 40
    unlocked << "Equipment_04" if level >= 50
    unlocked << "Equipment_05" if level >= 70
    unlocked << "Equipment_06" if level >= 90
    unlocked
  end

  private

  # Handle level up rewards and notifications
  def self.check_level_rewards(player, old_level, new_level)
    Rails.logger.info "Player #{player.id} leveled up from #{old_level} to #{new_level}"
    
    # Check for equipment unlocks
    equipment_milestones = [10, 20, 40, 50, 70, 90]
    equipment_milestones.each do |milestone|
      if old_level < milestone && new_level >= milestone
        equipment_tier = case milestone
                        when 10 then "Equipment_01"
                        when 20 then "Equipment_02" 
                        when 40 then "Equipment_03"
                        when 50 then "Equipment_04"
                        when 70 then "Equipment_05"
                        when 90 then "Equipment_06"
                        end
        Rails.logger.info "Player #{player.id} unlocked #{equipment_tier} at level #{new_level}"
        # TODO: Send level up notification with equipment unlock
      end
    end
  end
end