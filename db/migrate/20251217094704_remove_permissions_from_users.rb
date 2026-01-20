class RemovePermissionsFromUsers < ActiveRecord::Migration[8.0]
  def change
    remove_column :users, :permissions, :text
  end
end
