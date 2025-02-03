FactoryBot.define do
  factory :user do
    sequence(:code) { |n| "U#{n}#{SecureRandom.hex(3)}" }
    sequence(:api_credential) { |n| "API#{n}#{SecureRandom.hex(4)}" }
    sequence(:email) { |n| "user#{n}@example.com" }
    password { 'password123' }
    password_confirmation { 'password123' }
  end
end
