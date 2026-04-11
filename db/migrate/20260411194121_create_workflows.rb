class CreateWorkflows < ActiveRecord::Migration[8.1]
  def change
    create_table :workflows do |t|
      t.string :name
      t.string :trigger
      t.jsonb :condition
      t.jsonb :action
      t.string :status

      t.timestamps
    end
  end
end
