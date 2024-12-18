class CreateBaseSkills < ActiveRecord::Migration[7.1]
  def change
    create_table :base_skills do |t|
      t.string :name, null: false, comment: '技能名称'
      t.string :icon, null: false, comment: '技能图标'
      t.float :cd, default: 10.0, null: false, comment: '技能CD'
      t.float :duration, default: 10.0, null: false, comment: '技能持续时间'
      t.integer :max_angle, default: 30, comment: '最大散射角度'
      t.float :damage_ratio, default: 1.0, comment: '伤害系数'
      t.float :two_stage_damage_ratio, null: false, comment: '二阶段伤害系数'
      t.float :three_stage_damage_ratio, comment: '三阶段伤害系数'
      t.float :speed, default: 20.0, null: false, comment: '移动速度'
      t.float :scope, default: 1.0, null: false, comment: '技能范围'
      t.integer :split_count, null: false, comment: '分裂数量, 如果有分裂'
      t.integer :release_ultimate_count, default: 10, comment: '释放多少次普通攻击后释放大招'
      t.integer :release_count, default: 1, null: false, comment: '单次释放的技能数'
      t.integer :launches_count, default: 1, null: false, comment: '技能一轮释放的技能次数'
      t.float :launches_interval, default: 0.5, null: false, comment: '技能一轮释放多次技能的间隔时间'
      t.float :destroy_delay, default: 0.0, comment: '技能消失延时'
      t.boolean :is_dynamic, default: false, null: false, comment: '技能是否是动态的'
      t.boolean :is_living_position_release, default: true, null: false, comment: '技能是否通过英雄或者伙伴位置发出'
      t.boolean :is_impenetrability, default: true, null: false, comment: '是否不可穿透. 如果是TRUE, 技能不能穿透怪物'
      t.boolean :is_trace_monster, default: false, null: false, comment: '是否能跟踪怪物, 飞行途中怪物消失, 自动索敌'
      t.boolean :is_cd_rest_by_released, default: false, null: false, comment: '技能是释放后计算CD, 还是持续时间结束后计算CD. TRUE表示释放后计算CD'
      t.string :damage_type, default: 'Mechanical', null: false, comment: '伤害类型. Mechanical, Light, Fire, Ice, Wind, Physics, Cure, Burn'
      t.string :skill_target_type, default: 'Latest', null: false, comment: '技能选择怪物的方式, Latest, LatestMultiple, Random, Farmost, FarmostMultiple, Central, LatestNearby,'
      t.text :active_character, comment: '携带的特性.'
      t.text :description, comment: '技能描述'
      t.timestamps
    end
    add_index :base_skills, :name, unique: true
  end
end
