class OrderPayment < ApplicationRecord
  belongs_to :order
  has_many :order_payment_items

  accepts_nested_attributes_for :order_payment_items
end
