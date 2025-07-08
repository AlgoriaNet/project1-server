class ChangeUnpackCountsToDrawTimes < ActiveRecord::Migration[7.1]
  def change
    if column_exists?(:players, :unpack_counts)
      remove_column :players, :unpack_counts
    end
    if column_exists?(:players, :draw_times)
      remove_column :players, :draw_times
    end
    add_column :players, :draw_times, :json
    # Note: SQLite doesn't support column comments, so we skip the comment
    # change_column_comment :players, :draw_times, '抽奖次数记录,包括保底记录等，JSON格式'
  end
end
