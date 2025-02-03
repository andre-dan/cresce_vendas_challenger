class CreateItems < ActiveRecord::Migration[8.0]
  def change
    create_table :items do |t|
      t.references :order, null: false, foreign_key: true
      t.decimal :unit_quantity
      t.decimal :product_value
      t.decimal :flex_product_value
      t.decimal :discount_value
      t.decimal :increase_value
      t.decimal :gross_total_value
      t.decimal :flex_base_value
      t.text :observation
      t.integer :loading_number
      t.string :unit_code
      t.string :status
      t.integer :product_code
      t.integer :sequential
      t.string :route_code
      t.date :movement_date
      t.date :lowering_date
      t.integer :quantity
      t.integer :package_quantity
      t.decimal :discount_percentage
      t.decimal :total_value
      t.decimal :commission_value
      t.integer :original_quantity
      t.decimal :sale_price
      t.decimal :flex_value
      t.decimal :unit_value
      t.integer :client_order_item_number
      t.integer :order_number
      t.string :icms_symbol
      t.decimal :icms_aliquot
      t.decimal :icms_reduction_base
      t.integer :stock_code
      t.string :series
      t.date :wms_valid_date

      t.timestamps
    end
  end
end
