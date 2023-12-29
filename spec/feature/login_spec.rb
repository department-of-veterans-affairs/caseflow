# frozen_string_literal: true

RSpec.feature "Login", :all_dbs do
  let(:appeal) { create(:legacy_appeal, vacols_case: create(:case_with_ssoc)) }
  let(:station_id) { "405" }
  let(:user_email) { "test@example.com" }
  let(:roles) { ["Certify Appeal"] }
  let!(:user) { create(:user, css_id: "ANNE MERICA", station_id: station_id) }

  before do
    @old_session = Fakes::AuthenticationService.user_session
    Fakes::AuthenticationService.user_session = {
      "id" => "ANNE MERICA", "roles" => roles, "station_id" => station_id, "email" => user_email
    }
  end

  after do
    Fakes::AuthenticationService.user_session = @old_session
  end

  after(:all) do
    Rails.application.config.sso_service_disabled = false
  end

  context "User whose station ID has one RO doesn't require login" do
    let(:station_id) { "314" }

    it "shows new certification" do
      visit "certifications/new/#{appeal.vacols_id}"

      expect(page).to have_current_path("/certifications/#{appeal.vacols_id}/check_documents")
      expect(find("#menu-trigger")).to have_content("ANNE MERICA (RO14)")
      expect(user.reload.email).to eq user_email
      expect(user.selected_regional_office).to be_nil
    end
  end

  def select_ro_from_dropdown
    find(".cf-select__control").click
    find("#react-select-2-option-0").click
  end

  context "VSO user has multple RO values" do
    let(:station_id) { "351" }
    let(:organization) { create(:organization) }
    let(:roles) { ["VSO"] }

    context "User is in the Org they are trying to view" do
      before do
        organization.add_user(user)
      end

      scenario "user is presented with RO selection page and redirects to initial location" do
        User.authenticate!(user: user)
        visit "organizations/#{organization.url}"

        expect(current_path).to eq("/login")

        select_ro_from_dropdown
        click_on("Log in")

        expect(page).to have_content(organization.name)
        expect(current_path).to eq("/organizations/#{organization.url}")
      end
    end

    context "User is not in the Org they are trying to view" do
      scenario "user is presented with RO selection page and gets 403 /unauthorized error" do
        User.authenticate!(user: user)
        visit "organizations/#{organization.url}"

        expect(current_path).to eq("/login")

        select_ro_from_dropdown
        click_on("Log in")

        expect(page).to have_content("Unauthorized")
        expect(current_path).to eq("/unauthorized")
      end
    end

    context "User is in the BGS VSO org" do
      let(:vso_participant_id) { "12345" }
      let(:organization) { create(:vso, participant_id: vso_participant_id) }

      before do
        allow_any_instance_of(User).to receive(:vsos_user_represents).and_return(
          [{ participant_id: vso_participant_id }]
        )
      end

      scenario "user is presented with RO selection page and redirects to initial location" do
        visit "organizations/#{organization.url}"

        expect(current_path).to eq("/login")

        select_ro_from_dropdown
        click_on("Log in")

        expect(page).to have_content(organization.name)
        expect(current_path).to eq("/organizations/#{organization.url}")
      end
    end
  end

  # :nocov:
  # https://stackoverflow.com/questions/36472930/session-sometimes-not-persisting-in-capybara-selenium-test
  scenario "with valid credentials" do
    visit "certifications/new/#{appeal.vacols_id}"
    expect(page).to have_content("Please select the regional office you are logging in from.")
    select_ro_from_dropdown
    click_on "Log in"
    expect(page).to have_current_path("/certifications/#{appeal.vacols_id}/check_documents")
    expect(find("#menu-trigger")).to have_content("ANNE MERICA (RO05)")
  end

  scenario "logging out redirects to home page" do
    visit "certifications/new/#{appeal.vacols_id}"

    # vacols login
    expect(page).to have_content("Please select the regional office you are logging in from.")
    select_ro_from_dropdown
    click_on "Log in"

    click_on "ANNE MERICA (RO05)"
    click_on "Sign Out"
    visit "certifications/new/#{appeal.vacols_id}"
    expect(page).to have_current_path("/login")
  end
  # :nocov:

  context "user is logged out" do
    before do
      Fakes::AuthenticationService.user_session = nil
      @cached_sso_url = ENV["SSO_URL"]
      ENV["SSO_URL"] = "/fake-login-page"
    end

    after do
      ENV["SSO_URL"] = @cached_sso_url
    end

    scenario "Sign In menu option on /help page" do
      visit "/help"

      click_on "Menu"
      expect(page).to have_link("Sign In", href: "/search")
      click_on "Sign In"

      expect(current_path).to eq("/fake-login-page")
    end
  end

  scenario "email and selected regional office should be set on login" do
    visit "certifications/new/#{appeal.vacols_id}"
    select_ro_from_dropdown
    click_on "Log in"
    # Automatically wait for elements to disappear (but actually wait for asynchronous code to return)
    expect(page.has_no_content?("Logging in")).to eq(true)
    expect(user.reload.email).to eq user_email
    expect(user.selected_regional_office).to eq "RO05"
  end

  # :nocov:
  context "Single Sign on is down" do
    before do
      Rails.application.config.sso_service_disabled = true
    end

    after do
      Rails.application.config.sso_service_disabled = false
    end

    scenario "it displays the error page" do
      visit "certifications/new/#{appeal.vacols_id}"

      expect(page).to have_content("Something went wrong")
    end
  end
  # :nocov:
end
