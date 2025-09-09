# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2025_09_08_093555) do
  create_table "base_equipments", charset: "utf8", force: :cascade do |t|
    t.string "description"
    t.string "name", limit: 30, null: false
    t.integer "quality", null: false, comment: "品质"
    t.string "part", null: false, comment: "部位"
    t.integer "base_atk", null: false, comment: "基础攻击力"
    t.integer "growth_atk", null: false, comment: "成长攻击力"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "display_name"
  end

  create_table "base_items", charset: "utf8", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "stackable", default: true, null: false
    t.string "item_type"
    t.integer "quality"
    t.index ["name"], name: "index_base_items_on_name"
    t.index ["name"], name: "index_base_items_on_unique_name", unique: true
  end

  create_table "base_sidekicks", charset: "utf8", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.integer "skill_id", null: false, comment: "Base技能"
    t.text "character", null: false, comment: "特性"
    t.integer "atk", default: 0, null: false, comment: "基础攻击力"
    t.integer "def", default: 0, null: false, comment: "基础防御力"
    t.integer "cri", default: 0, null: false, comment: "暴击力"
    t.integer "crt", default: 150, null: false, comment: "暴击伤害"
    t.json "variety_damage", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "cn_name", comment: "中文名"
    t.string "drawing_icon", comment: "立绘名"
    t.string "fragment_name", comment: "碎片名"
    t.string "card_name", comment: "卡牌名"
    t.string "portrait_icon", comment: "头像名"
    t.string "skill_icon", comment: "技能ICON"
    t.string "skill_book_icon", comment: "技能书icon"
    t.index ["cn_name"], name: "index_base_sidekicks_on_cn_name"
    t.index ["fragment_name"], name: "index_base_sidekicks_on_fragment_name"
  end

  create_table "base_skill_level_up_effects", charset: "utf8", force: :cascade do |t|
    t.integer "skill_id", null: false
    t.string "effect_name", limit: 25, comment: "效果名称"
    t.integer "level", null: false, comment: "等级"
    t.text "effects", null: false, comment: "效果"
    t.integer "weight", default: 10, comment: "3选1权重"
    t.string "depend_character", limit: 225, comment: "依赖特性"
    t.integer "max_count", default: 1, null: false, comment: "3选1最大出现次数"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "gold_cost"
    t.index ["skill_id"], name: "fk_rails_c33a2be3e9"
  end

  create_table "base_skills", id: :integer, charset: "utf8", force: :cascade do |t|
    t.string "name", null: false, comment: "技能名称"
    t.string "icon", null: false, comment: "技能图标"
    t.float "cd", default: 10.0, null: false, comment: "技能CD"
    t.float "duration", default: 10.0, null: false, comment: "技能持续时间"
    t.integer "max_angle", default: 30, comment: "最大散射角度"
    t.float "damage_ratio", default: 1.0, comment: "伤害系数"
    t.float "two_stage_damage_ratio", null: false, comment: "二阶段伤害系数"
    t.float "three_stage_damage_ratio", comment: "三阶段伤害系数"
    t.float "speed", default: 20.0, null: false, comment: "移动速度"
    t.float "scope", default: 1.0, null: false, comment: "技能范围"
    t.integer "split_count", null: false, comment: "分裂数量, 如果有分裂"
    t.integer "release_ultimate_count", default: 10, comment: "释放多少次普通攻击后释放大招"
    t.integer "release_count", default: 1, null: false, comment: "单次释放的技能数"
    t.integer "launches_count", default: 1, null: false, comment: "技能一轮释放的技能次数"
    t.float "launches_interval", default: 0.5, null: false, comment: "技能一轮释放多次技能的间隔时间"
    t.float "destroy_delay", default: 0.0, comment: "技能消失延时"
    t.boolean "is_dynamic", default: false, null: false, comment: "技能是否是动态的"
    t.boolean "is_living_position_release", default: true, null: false, comment: "技能是否通过英雄或者伙伴位置发出"
    t.boolean "is_impenetrability", default: true, null: false, comment: "是否不可穿透. 如果是TRUE, 技能不能穿透怪物"
    t.boolean "is_trace_monster", default: false, null: false, comment: "是否能跟踪怪物, 飞行途中怪物消失, 自动索敌"
    t.boolean "is_cd_rest_by_released", default: false, null: false, comment: "技能是释放后计算CD, 还是持续时间结束后计算CD. TRUE表示释放后计算CD"
    t.string "damage_type", default: "Mechanical", null: false, comment: "伤害类型. Mechanical, Light, Fire, Ice, Wind, Physics, Cure, Burn"
    t.string "skill_target_type", default: "Latest", null: false, comment: "技能选择怪物的方式, Latest, LatestMultiple, Random, Farmost, FarmostMultiple, Central, LatestNearby,"
    t.text "active_character", comment: "携带的特性."
    t.text "description", comment: "技能描述"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_base_skills_on_name", unique: true
  end

  create_table "battle_formations", charset: "utf8", force: :cascade do |t|
    t.bigint "player_id", null: false
    t.bigint "sidekick1_id"
    t.bigint "sidekick2_id"
    t.bigint "sidekick3_id"
    t.bigint "sidekick4_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["player_id"], name: "battle_formations_players_id_fk"
    t.index ["sidekick1_id"], name: "battle_formation_sidekicks1_id_fk"
    t.index ["sidekick2_id"], name: "battle_formation_sidekicks2_id_fk"
    t.index ["sidekick3_id"], name: "battle_formation_sidekicks3_id_fk"
    t.index ["sidekick4_id"], name: "battle_formation_sidekicks4_id_fk"
  end

  create_table "equipments", charset: "utf8", force: :cascade do |t|
    t.bigint "base_equipment_id", null: false
    t.integer "intensify_level", default: 0, comment: "强化等级"
    t.text "nearby_attributes"
    t.text "additional_attributes"
    t.bigint "player_id", null: false
    t.bigint "equip_with_sidekick_id"
    t.bigint "equip_with_hero_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "total_crystals_spent", default: 0, null: false, comment: "Total crystals spent on forging this equipment"
    t.integer "upgrade_rank", default: 1, null: false, comment: "Upgrade rank (1-12) for percentage attack bonus"
    t.index ["base_equipment_id"], name: "equipments_base_equipments_id_fk"
    t.index ["equip_with_hero_id"], name: "equipments_heros_id_fk"
    t.index ["equip_with_sidekick_id"], name: "equipments_sidekicks_id_fk"
    t.index ["player_id"], name: "equipments_players_id_fk"
  end

  create_table "gemstone_entries", charset: "utf8", force: :cascade do |t|
    t.string "effect_description"
    t.string "effect_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "attribute_type", default: "basic"
    t.integer "attribute_id"
    t.decimal "base_value", precision: 8, scale: 2
  end

  create_table "gemstones", charset: "utf8", force: :cascade do |t|
    t.string "name"
    t.string "description"
    t.integer "level"
    t.string "access_channels"
    t.bigint "player_id"
    t.integer "entry_id"
    t.integer "inlay_with_sidekick_id"
    t.integer "inlay_with_hero_id"
    t.string "part", null: false
    t.boolean "is_locked", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "equipment_id"
    t.integer "slot_number", default: 1
    t.boolean "is_in_inventory", default: true
    t.bigint "secondary_entry_id"
    t.index ["equipment_id", "slot_number"], name: "index_gemstones_on_equipment_id_and_slot_number", unique: true
    t.index ["player_id"], name: "fk_rails_4ea6464855"
    t.index ["secondary_entry_id"], name: "fk_rails_ff7a298a3a"
  end

  create_table "heros", charset: "utf8", force: :cascade do |t|
    t.string "name"
    t.integer "player_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "main_stages", charset: "utf8", force: :cascade do |t|
    t.integer "level"
    t.string "name"
    t.json "monsters"
    t.json "upgrade_required_experience"
    t.json "first_award"
    t.json "win_reward"
    t.json "lose_reward"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.json "monsters_config"
    t.integer "stage_number"
  end

  create_table "monsters", charset: "utf8", force: :cascade do |t|
    t.string "name"
    t.integer "range"
    t.string "type"
    t.json "character"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "level"
    t.integer "hp"
    t.integer "atk"
    t.float "speed"
    t.json "abilities"
    t.json "rewards"
    t.string "size"
    t.string "elemental_weakness"
    t.float "movement_speed_multiplier", default: 1.0
    t.float "attack_range", default: 1.0
    t.json "special_abilities"
    t.json "habitat_levels"
    t.json "spawn_probability"
    t.boolean "is_boss", default: false
    t.boolean "is_elite", default: false
  end

  create_table "orders", charset: "utf8", force: :cascade do |t|
    t.bigint "player_id", null: false
    t.string "order_id", null: false
    t.string "product_id", null: false
    t.string "platform_order_id"
    t.string "platform", null: false
    t.boolean "is_sandbox", default: false
    t.decimal "money", precision: 10, scale: 2
    t.string "currency", default: "CNY"
    t.datetime "pay_time"
    t.datetime "deliver_time"
    t.string "status", default: "pending", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["order_id"], name: "index_orders_on_order_id", unique: true
    t.index ["platform_order_id"], name: "index_orders_on_platform_order_id", unique: true
    t.index ["player_id", "platform", "status"], name: "index_orders_on_player_id_and_platform_and_status"
    t.index ["player_id"], name: "index_orders_on_player_id"
  end

  create_table "players", charset: "utf8", force: :cascade do |t|
    t.string "name", comment: "用户昵称"
    t.integer "level", default: 1, null: false, comment: "等级"
    t.integer "exp", default: 0, null: false, comment: "经验"
    t.integer "gold_coin", default: 0, null: false, comment: "金币"
    t.integer "diamond", default: 0, null: false, comment: "钻石"
    t.integer "stamina", default: 100, null: false, comment: "体力"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "device_id"
    t.string "monthly_card_expiry"
    t.string "weekly_card_expiry"
    t.json "items_json"
    t.json "draw_times", comment: "抽奖次数记录,包括保底记录等，JSON格式"
    t.json "summoned_allies"
    t.text "deployed_base_ids"
    t.integer "current_stage", default: 1
    t.index ["device_id"], name: "index_players_on_device_id", unique: true
  end

  create_table "purchase_products", charset: "utf8", force: :cascade do |t|
    t.string "product_id", null: false
    t.decimal "money", precision: 10, scale: 2, null: false
    t.string "currency", default: "USD"
    t.text "description"
    t.json "reward_items"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id"], name: "index_purchase_products_on_product_id", unique: true
  end

  create_table "sidekicks", charset: "utf8", force: :cascade do |t|
    t.integer "base_id"
    t.integer "skill_level"
    t.integer "star"
    t.boolean "is_deployed"
    t.integer "player_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", charset: "utf8", force: :cascade do |t|
    t.string "email"
    t.string "password_digest"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "base_skill_level_up_effects", "base_skills", column: "skill_id"
  add_foreign_key "battle_formations", "players"
  add_foreign_key "battle_formations", "sidekicks", column: "sidekick1_id"
  add_foreign_key "battle_formations", "sidekicks", column: "sidekick2_id"
  add_foreign_key "battle_formations", "sidekicks", column: "sidekick3_id"
  add_foreign_key "battle_formations", "sidekicks", column: "sidekick4_id"
  add_foreign_key "equipments", "base_equipments", name: "equipments_base_equipments_id_fk"
  add_foreign_key "equipments", "heros", column: "equip_with_hero_id", name: "equipments_heros_id_fk"
  add_foreign_key "equipments", "players", name: "equipments_players_id_fk"
  add_foreign_key "equipments", "sidekicks", column: "equip_with_sidekick_id", name: "equipments_sidekicks_id_fk"
  add_foreign_key "gemstones", "equipments"
  add_foreign_key "gemstones", "gemstone_entries", column: "secondary_entry_id"
  add_foreign_key "gemstones", "players"
  add_foreign_key "orders", "players"
end
