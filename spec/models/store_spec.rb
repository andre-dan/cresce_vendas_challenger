require 'rails_helper'

RSpec.describe Store, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
    it { should have_many(:products) }
  end
end
