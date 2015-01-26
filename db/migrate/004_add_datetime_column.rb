class AddDatetimeColumn < ActiveRecord::Migration
  def self.up
    add_column :todo_items, :due_date, :datetime
  end

  def self.down
    remove_column :due_date
  end
end