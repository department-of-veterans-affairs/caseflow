# frozen_string_literal: true

RSpec.shared_context "enable business line" do
  before { FeatureToggle.enable!(:board_grant_effectuation_task) }
  after { FeatureToggle.disable!(:board_grant_effectuation_task) }
end

RSpec.shared_context :business_line do |name, url|
  let(:business_line) { create(:business_line, name: name, url: url) }
end

RSpec.shared_context :organization do |name, type|
  let!(:organization) { create(:organization, name: name, type: type) }
end

RSpec.shared_context "create user" do
  let!(:user) { create(:user) }
end

RSpec.shared_context :add_user_to_business_line do
  before do
    business_line.add_user(:user)
  end
end

RSpec.shared_context :admin_user_to_business_line do |user, business_line|
  let!(:admin_user_to_business_line) do
    OrganizationsUser.make_user_admin(user, business_line.singleton)
  end
end
