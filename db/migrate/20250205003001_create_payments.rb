class CreatePayments < ActiveRecord::Migration[8.0]
  def change
    create_table :order_payments do |t|
      t.references :order, null: false, foreign_key: true
      t.string :payment_method
      t.string :nfe_flag_code
      t.string :payment_institution_cnpj
      t.decimal :change_value

      t.timestamps
    end
  end
end
