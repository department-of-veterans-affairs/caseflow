# frozen_string_literal: true

RSpec.feature "Log in as User", :postgres do
  before do
    User.create(station_id: "283", css_id: "ANNE MERICA")
    User.authenticate!
  end

  after do
    User.unauthenticate!
  end

  scenario "Non authorized user will not see the feature" do
    visit "test/users"
    expect(page).to have_content("DSUSER")
    expect(page).not_to have_content("Log in as user")
  end

  context "user is Global Admin" do
    before do
      Functions.grant!("Global Admin", users: ["DSUSER"])
    end

    after do
      Functions.client.del("Global Admin")
    end

    scenario "user is able to log in as user" do
      test_global_admin_masquerade
    end

    def test_global_admin_masquerade
      visit "test/users"
      fill_in "User ID", with: "ANNE MERICA"
      safe_click("#button-Log-in-as-user")
      expect(page).to have_content("ANNE MERICA (DSUSER)")
      expect(page).to have_content("Certification Help")

      visit "test/users"
      expect(page).not_to have_content("Log in as user")

      find("a", text: "ANNE MERICA (DSUSER)").click
      find("a", text: "Sign Out").click
      expect(page).to have_content("DSUSER")
      expect(page).to have_content("admin page")
    end

    context "dependencies_faked? is false (prod env)" do
      before do
        allow(ApplicationController).to receive(:dependencies_faked?) { false }
      end

      scenario "user can log in as another user" do
        test_global_admin_masquerade
      end
    end
  end

  scenario "User visits session page" do
    visit "test/users/me"

    expect(page).to have_content("Your session")
    expect(page).to have_content("session_id")
  end
end
