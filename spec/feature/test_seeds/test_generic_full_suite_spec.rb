# frozen_string_literal: true

RSpec.feature "Test Generic Seeds" do
  unless Rake::Task.task_defined?("assets:precompile")
    Rails.application.load_tasks
  end
  let!(:current_user) do
    user = create(:user, css_id: "BVALNICK")
    CDAControlGroup.singleton.add_user(user)
    User.authenticate!(user: user)
  end

  context "user is a Case Distro Algorithm Control admin" do
    before do
      OrganizationsUser.make_user_admin(current_user, CDAControlGroup.singleton)
    end

    scenario "visits the acd test seeds page" do
      visit "acd-controls/test"
      expect(page).to have_content(COPY::TEST_RUN_GENERIC_FULL_SUITE_APPEALS_TITLE)
      find(:xpath, "//*[@id='button-Run-Generic-Full-Suite-Appeals-Seeds']").click
      expect(page).to have_content("Reseeding Generic Full Suite Appeals Seeds")
    end
  end

  def login
    visit "test/seeds"
    visit "test/seeds"
  end
end
