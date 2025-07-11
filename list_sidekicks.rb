#!/usr/bin/env ruby
require_relative 'config/environment'
puts '=== Sidekick List (Ally Name, Star, Skill Level) ==='
puts ''
Sidekick.all.each do |sk|
  player = Player.find_by(id: sk.player_id)
  base = BaseSidekick.find_by(id: sk.base_id)
  puts "Player: #{player&.name || player&.id || '?'} | Ally: #{base&.fragment_name || base&.id || '?'} | Star: #{sk.star} | Skill_Level: #{sk.skill_level}"
end
