class Order < ApplicationRecord
  has_many :items
  has_many :order_payments

  accepts_nested_attributes_for :items
  accepts_nested_attributes_for :order_payments
end
