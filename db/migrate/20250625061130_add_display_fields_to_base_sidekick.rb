# db/migrate/[timestamp]_add_display_fields_to_base_sidekick.rb
class AddDisplayFieldsToBaseSidekick < ActiveRecord::Migration[6.1]
  def change
    add_column :base_sidekicks, :cn_name, :string, comment: '中文名'
    add_column :base_sidekicks, :drawing_icon, :string, comment: '立绘名'
    add_column :base_sidekicks, :fragment_name, :string, comment: '碎片名'
    add_column :base_sidekicks, :card_name, :string, comment: '卡牌名'
    add_column :base_sidekicks, :portrait_icon, :string, comment: '头像名'
    add_column :base_sidekicks, :skill_icon, :string, comment: '技能ICON'
    add_column :base_sidekicks, :skill_book_icon, :string, comment: '技能书icon'

    # 为常用查询字段添加索引
    add_index :base_sidekicks, :cn_name
    add_index :base_sidekicks, :fragment_name
  end
end
