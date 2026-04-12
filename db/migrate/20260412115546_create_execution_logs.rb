class CreateExecutionLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :execution_logs do |t|
      t.references :workflow, null: false, foreign_key: true
      t.string :event_type
      t.jsonb :event_payload
      t.boolean :condition_passed
      t.string :action_executed

      t.timestamps
    end
  end
end
