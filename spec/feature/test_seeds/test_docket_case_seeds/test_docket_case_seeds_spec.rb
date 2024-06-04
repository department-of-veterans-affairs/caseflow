# frozen_string_literal: true

RSpec.feature "Test Docket Case Seeds" do
  let!(:current_user) do
    user = create(:user, css_id: "BVATTWAYNE")
    CDAControlGroup.singleton.add_user(user)
    User.authenticate!(user: user)
  end

  context "user is in Case Distro Algorithm Control organization but not an admin" do
    scenario "visits the test seeds page" do
      visit "test/seeds"
    end
  end

  context "user is a Case Distro Algorithm Control admin" do
    before do
      OrganizationsUser.make_user_admin(current_user, CDAControlGroup.singleton)
    end

    scenario "visits the test seeds page" do
      visit "test/seeds"
    end
  end
end
