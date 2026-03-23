class AddUniqueIndexOnEmailToUsers < ActiveRecord::Migration[8.0]
  def up
    execute <<~SQL.squish
      UPDATE users
      SET email = LOWER(TRIM(email))
      WHERE email IS NOT NULL
    SQL

    add_index :users, :email, unique: true
  end

  def down
    remove_index :users, :email, unique: true
  end
end
