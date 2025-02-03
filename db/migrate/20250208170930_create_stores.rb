class CreateStores < ActiveRecord::Migration[8.0]
  def change
    create_table :stores do |t|
      t.string :cnpj
      t.string :name

      t.timestamps
    end
  end
end
