# frozen_string_literal: true

class Unboxing

  def self.generate_gemstone_by_times(player_id, count)
    raise ArgumentError, "Invalid count" if count != 10 && count != 1
    ApplicationRecord.transaction do
      gemstones = []
      count.times do
        gemstones << generate_gemstone_box(player_id)
      end
      return gemstones
    end
  end

  def self.generate_gemstone_box(player_id)
    ApplicationRecord.transaction do
      probability = CsvConfig.load_epic_gem
      player = Player.find(player_id)
      player.unpack_counts ||= {}
      player.unpack_counts["epic_gem"] ||= 0
      if player.unpack_counts["epic_gem"] == 9
        level = 3
        player.unpack_counts["epic_gem"] = 0
      else
        player.unpack_counts["epic_gem"] += 1
        rand_num = rand(0.0..100.0)
        probability.each do |p|
          rand_num -= p[:probability]
          if rand_num <= 0
            level = p[:level]
            break
          end
        end
        level = 1 if level.nil?
        player.unpack_counts["epic_gem"] = 0 if level >= 3
      end
      gemstone = Gemstone.generate(level, player_id)
      gemstone.save!
      player.save!
      return gemstone
    end
  end

  def self.draw_multiple_epic_gem(player_id, count)
    raise ArgumentError, "Invalid count" if count != 10 && count != 1
    ApplicationRecord.transaction do
      gemstones = []
      count.times do
        gemstones << epic_gem(player_id)
      end
      return gemstones
    end
  end

  def self.epic_gem(player_id)
    ApplicationRecord.transaction do
      probability = CsvConfig.load_epic_gem
      player = Player.find(player_id)
      player.unpack_counts ||= {}
      player.unpack_counts["epic_gem"] ||= 0
      if player.unpack_counts["epic_gem"] == 9
        level = 4
        player.unpack_counts["epic_gem"] = 0
      else
        player.unpack_counts["epic_gem"] += 1
        rand_num = rand(0.0..100.0)
        probability.each do |p|
          rand_num -= p[:probability]
          if rand_num <= 0
            level = p[:level]
            break
          end
        end
        level = 2 if level.nil?
        player.unpack_counts["epic_gem"] = 0 if level >= 4
      end
      gemstone = Gemstone.generate(level, player_id)
      gemstone.save!
      player.save!
      return gemstone
    end
  end
end

