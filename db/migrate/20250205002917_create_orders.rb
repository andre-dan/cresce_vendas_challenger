class CreateOrders < ActiveRecord::Migration[8.0]
  def change
    create_table :orders do |t|
      t.string :transaction_identifier
      t.string :unit_code
      t.integer :loading_number
      t.string :status
      t.date :movement_date
      t.date :delivery_date
      t.time :lcto_time
      t.date :base_date
      t.date :lowering_date
      t.string :route_code
      t.string :payment_code
      t.decimal :freight_percentage
      t.decimal :discount_value
      t.decimal :discount_percentage
      t.decimal :additional_expense_value
      t.decimal :additional_expense_percentage
      t.decimal :commission_value
      t.string :lowering_transaction
      t.string :coupon_number
      t.string :lowering_pdv_code
      t.string :lowering_pdv_unit
      t.integer :delivery_sequence
      t.integer :user_code
      t.integer :kind_code
      t.integer :client_link_code
      t.integer :consolidated_number
      t.integer :production_transaction_number
      t.date :estimated_date
      t.string :delivery_shift
      t.string :unit
      t.string :origin
      t.string :withdrawal_unit
      t.date :date
      t.integer :client_code
      t.string :payment_method
      t.string :client_order_number
      t.string :seller_code
      t.text :observation
      t.integer :kind
      t.decimal :discount
      t.string :document_code
      t.string :name
      t.string :email
      t.string :cpf
      t.string :rg
      t.string :cnpj
      t.string :state_registration
      t.string :address
      t.string :number
      t.string :complement
      t.string :neighborhood
      t.integer :city
      t.string :zip_code
      t.string :phone
      t.string :delivery_turn
      t.date :expected_date
      t.decimal :freight_value
      t.decimal :accessory_expense
      t.string :carrier
      t.string :route
      t.string :deliverer
      t.text :additional_data

      t.timestamps
    end
  end
end
