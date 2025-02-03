class AddUserToStores < ActiveRecord::Migration[8.0]
  def change
    add_reference :stores, :user, null: true, foreign_key: true
  end
end
