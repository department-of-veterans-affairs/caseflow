# frozen_string_literal: true

RSpec.feature "Test Seeds" do
  let!(:current_user) do
    user = create(:user, css_id: "BVADWISE")
    CDAControlGroup.singleton.add_user(user)
    User.authenticate!(user: user)
  end

  context "user is a Case Distro Algorithm Control admin" do
    before do
      OrganizationsUser.make_user_admin(current_user, CDAControlGroup.singleton)
    end

    scenario "visits the test seeds page" do
      visit "test/seeds"
      confirm_page_and_seed_buttons_present
    end
  end
end

def confirm_page_and_buttons_present
  expect(page).to have_content(COPY::TEST_SEEDS_RUN_SEEDS)
end
