class CreateItems < ActiveRecord::Migration
  def self.up
    create_table :todoitem do |t|
      t.integer :todo_list_id
      t.string :name
      t.timestamps :duedate
      t.boolean :finished
    end
  end

  def self.down
    drop_table :todoitem
  end
end