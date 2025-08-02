#!/usr/bin/env ruby

# Test dismantle API response format

player = Player.find(4)
spare_equipment = player.equipments.where(equip_with_hero_id: nil, equip_with_sidekick_id: nil).first

if spare_equipment
  puts "Testing dismantle API response format..."
  puts "Equipment ID: #{spare_equipment.id}"
  puts "Crystals before: #{player.items_json['crystal'] || 0}"
  
  # Simulate the API call parameters
  mock_json = {
    "requestId" => "test-123",
    "json" => {
      "equipmentId" => spare_equipment.id
    }.to_json
  }
  
  # Call dismantle and check the result format
  result = spare_equipment.dismantle
  
  if result[:success]
    player.reload
    player_profile = PlayerProfile.new(player.id)
    
    # This is what render_response would create
    api_response = {
      action: "dismantle",
      code: 200,
      requestId: mock_json["requestId"],
      data: {
        success: true,
        equipmentId: spare_equipment.id,
        crystals_rewarded: result[:crystals_rewarded],
        base_crystals: result[:base_crystals],
        refund_crystals: result[:refund_crystals],
        player_profile: player_profile.as_ws_json
      }
    }
    
    puts "API Response Structure:"
    puts "- action: #{api_response[:action]}"
    puts "- code: #{api_response[:code]}"
    puts "- requestId: #{api_response[:requestId]}"
    puts "- data: #{api_response[:data].class}"
    puts "- data.success: #{api_response[:data][:success]}"
    puts "- data.crystals_rewarded: #{api_response[:data][:crystals_rewarded]}"
    puts "- data.player_profile present: #{api_response[:data][:player_profile].present?}"
    
    puts
    puts "Crystals after: #{player.items_json['crystal'] || 0}"
    puts "Equipment count: #{player.equipments.count}"
    
  else
    puts "Dismantle failed: #{result[:error]}"
  end
else
  puts "No spare equipment found for testing"
end