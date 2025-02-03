FactoryBot.define do
  factory :store do
    association :user
    sequence(:name) { |n| "Store #{n}" }
    cnpj { '12345678000199' }
  end
end
