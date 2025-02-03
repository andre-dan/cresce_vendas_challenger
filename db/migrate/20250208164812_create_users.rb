class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :code
      t.string :email
      t.string :api_credential
      t.string :password_digest

      t.timestamps
    end

    add_index :users, :email, unique: true
  end
end
