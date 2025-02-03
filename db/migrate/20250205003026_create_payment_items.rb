class CreatePaymentItems < ActiveRecord::Migration[8.0]
  def change
    create_table :order_payment_items do |t|
      t.references :order_payment, null: false, foreign_key: true
      t.string :lowering_account
      t.integer :installment
      t.string :host_nsu
      t.string :sitef_nsu
      t.string :authorization_nsu
      t.string :authorizer
      t.string :card_bin
      t.string :bank
      t.string :agency
      t.decimal :value
      t.string :pix_id
      t.string :ecomm_transaction_id
      t.string :card_flag
      t.string :payer_cnpj
      t.string :payer_state
      t.string :receiver_cnpj
      t.string :payment_terminal_id
      t.string :payment_date

      t.timestamps
    end
  end
end
