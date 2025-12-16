class CreateSessions < ActiveRecord::Migration[7.1]
  def change
    create_table :sessions do |t|
      t.string :token, null: false
      t.references :user, null: false, foreign_key: true
      t.text :id_token, null: false
      t.datetime :expires_at

      if connection.adapter_name == "PostgreSQL"
        t.jsonb :raw_info
      else
        t.json :raw_info
      end

      t.timestamps
    end

    add_index :sessions, :token, unique: true
  end
end
