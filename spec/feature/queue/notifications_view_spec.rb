# frozen_string_literal: true

RSpec.feature "Notifications View" do
  let(:user_roles) { ["System Admin"] }
  before do
    User.authenticate!(roles: user_roles)
  end
end

