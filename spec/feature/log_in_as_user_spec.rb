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
    expect(page.has_no_content?("Log in as user")).to eq(true)
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
      expect(page.has_no_content?("Log in as user")).to eq(true)

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

  context "First time user login" do
    let(:vha_body_text) do
      "If you are a VHA team member, you will need access to VHA-specific "\
      "pages to perform your duties. Press the “Request access” button below to"\
      " be redirected to the VHA section within the Help page, where you can"\
      " submit a form for access."
    end

    before do
      Fakes::AuthenticationService.user_session = {
        "id" => "ANNE MERICA", "roles" => ["Certify Appeal"], "station_id" => "405", "email" => "test@example.com"
      }
    end

    scenario "The VHA Info Banner should appear the first time an existing user logs in" do
      visit "/"
      expect(page).to have_content(COPY::VHA_FIRST_LOGIN_INFO_ALERT_TITLE)
      expect(page).to have_content(COPY::VHA_FIRST_LOGIN_INFO_ALERT_BODY)
      click_button("Request access")
      expect(current_path).to eq("/vha/help")
    end

    context "New user that doesn't exist in the database" do
      before do
        User.unauthenticate!
        Fakes::AuthenticationService.user_session = {
          "id" => "BRAND NEW USER", "roles" => ["Certify Appeal"], "station_id" => "405", "email" => "tyler@example.com"
        }
        # Skip this method to avoid the redirect to the help page.
        allow_any_instance_of(User).to receive(:authenticated?).and_return(true)
      end

      scenario "The VHA Info Banner should appear the first time a new user is created and logs in" do
        expect(User.find_by_css_id("BRAND NEW USER")).to be_nil
        visit "/"
        expect(User.find_by_css_id("BRAND NEW USER")).to_not be_nil
        expect(page).to have_content(COPY::VHA_FIRST_LOGIN_INFO_ALERT_TITLE)
        expect(page).to have_content(COPY::VHA_FIRST_LOGIN_INFO_ALERT_BODY)
        click_button("Request access")
        expect(current_path).to eq("/vha/help")
      end
    end
  end
end
