class AddJsonDataToWorkflows < ActiveRecord::Migration[8.1]
  def change
    add_column :workflows, :json_data, :json
  end
end
