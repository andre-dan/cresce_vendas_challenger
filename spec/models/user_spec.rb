require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'associations' do
    it { should have_many(:stores) }
  end

  describe 'validations' do
    subject { create(:user) }

    it { should validate_presence_of(:code) }
    it { should validate_uniqueness_of(:code) }

    it { should validate_presence_of(:api_credential) }
    it { should validate_uniqueness_of(:api_credential) }

    it { should validate_presence_of(:email) }
    it { should allow_value('user@example.com').for(:email) }
    it { should_not allow_value('invalid-email').for(:email) }

    it { should have_secure_password }
  end
end
