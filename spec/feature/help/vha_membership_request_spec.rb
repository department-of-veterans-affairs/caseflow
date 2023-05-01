# frozen_string_literal: true

RSpec.feature "VhaMembershipRequest" do
  before do
    vha_org.add_user(vha_user)
    camo_org.add_user(camo_user)
    caregiver_org
    FeatureToggle.enable!(:program_office_team_management)
    ActiveJob::Base.queue_adapter.enqueued_jobs.clear
  end

  after do
    FeatureToggle.disable!(:program_office_team_management)
  end

  let(:new_user) { create(:user) }
  let(:vha_user) { create(:user) }
  let(:user_with_membership_requests) { create(:user) }
  let(:camo_user) { create(:user) }

  let(:camo_org) { VhaCamo.singleton }
  let(:caregiver_org) { VhaCaregiverSupport.singleton }
  let(:vha_org) do
    org = BusinessLine.find_or_create_by(name: "Veterans Health Administration", url: "vha")
    org.save
    org
  end
  let(:prosthetics_org) do
    org = VhaProgramOffice.find_or_create_by(name: "Prosthetics", url: "prosthetics-url")
    org.save
    org
  end

  let(:prosthetics_membership_request) do
    request = create(:membership_request,
                     organization: prosthetics_org.reload,
                     requestor: user_with_membership_requests)
    request.save
    request
  end

  context("Vha Membership for a new user") do
    context("with program office team management feature toggle on") do
      before do
        FeatureToggle.enable!(:program_office_team_management)
        User.authenticate!(user: new_user)
      end
      after do
        FeatureToggle.disable!(:program_office_team_management)
      end

      scenario "Vha membership request form for a new user with requests for program offices enabled" do
        visit "/vha/help"
        # Expect the user to be able to see all of the program office checkboxes
        checkbox_labels = all(:css, ".checkbox > label").map(&:text)
        checkbox_option_labels = [
          "VHA CAMO",
          "VHA Caregiver Support Program",
          "Payment Operations Management",
          "Veteran and Family Members Program",
          "Member Services - Health Eligibility Center",
          "Member Services - Beneficiary Travel",
          "Prosthetics"
        ]
        expect(checkbox_labels).to eq(checkbox_option_labels)
      end
    end

    context("with program office team management feature toggle off") do
      before do
        FeatureToggle.disable!(:program_office_team_management)
        User.authenticate!(user: new_user)
      end

      scenario "Vha membership request form for a new user with requests for program offices disabled" do
        visit "/vha/help"
        # Expect the user to be able to not see any of the program office checkboxes
        checkbox_labels = all(:css, ".checkbox > label").map(&:text)
        checkbox_option_labels = [
          "VHA CAMO",
          "VHA Caregiver Support Program"
        ]
        expect(checkbox_labels).to eq(checkbox_option_labels)
      end
    end

    context("form submit and information behavior for a new user") do
      before do
        User.authenticate!(user: new_user)
        visit "/vha/help"
      end

      scenario "Normal form behavior for a new user" do
        # The submit button should be disabled until a checkbox is clicked
        expect(page).to have_button("Submit", disabled: true)

        # Clicking the VHA checkbox should enable submit
        find("label[for='vhaAccess']").click
        expect(page).to have_button("Submit", disabled: false)

        find("label[for='vhaAccess']").click
        expect(page).to have_button("Submit", disabled: true)

        # Click a the caregiver checkbox and submit should be enabled
        find("label[for='vhaCaregiverSupportProgram']").click
        expect(page).to have_button("Submit", disabled: false)

        # Check for the automatic vha access will be granted information message
        expect(page).to have_content(COPY::VHA_MEMBERSHIP_REQUEST_AUTOMATIC_VHA_ACCESS_NOTE)

        request_reason = "Does this work?"

        # Add a request reason
        fill_in "Reason for access", with: request_reason

        # Submit the form with the caregiver checkbox selected
        click_button "Submit"

        # Verify that the form is updated and reset with all of the following:
        # The form has been reset after submission so the button should be disabled again
        # The request reason text box should be reset
        # The VHA Caregiver checkbox should be disabled
        # The disabled options info message is present
        # The success banner message is present
        message_text = format(COPY::VHA_MEMBERSHIP_REQUEST_FORM_SUBMIT_SUCCESS_MESSAGE, "VHA Caregiver Support Program")
        caregiver_checkbox = find("#vhaCaregiverSupportProgram", visible: false)
        expect(page).to have_button("Submit", disabled: true)
        expect(page).to_not have_content(request_reason)
        expect(caregiver_checkbox.disabled?).to eq(true)
        expect(page).to have_content(message_text)
        expect(page).to have_content(COPY::VHA_MEMBERSHIP_REQUEST_DISABLED_OPTIONS_INFO_MESSAGE)

        # Verify that the request object was saved with the new user, VhaCaregiverSupport, and the request reason
        request = MembershipRequest.last
        expect(request.note).to eq(request_reason)
        expect(request.organization).to eq(VhaCaregiverSupport.singleton)
        expect(request.requestor).to eq(new_user)

        # Verify the email jobs were queued successfully
        jobs = ActiveJob::Base.queue_adapter.enqueued_jobs
          .select { |job| job[:job] == Memberships::SendMembershipRequestMailerJob }
        expect(jobs.first[:args]).to include("UserRequestCreated")
        expect(jobs.last[:args]).to include("AdminRequestMade")
        expect(jobs.length).to eq(2)
        expect(jobs.map { |job| job[:queue] }).to all(eq "caseflow_test_low_priority")
      end
    end
  end

  context("Vha Membership for a user that is a member of camo") do
    before do
      User.authenticate!(user: camo_user)
      visit "/vha/help"
    end

    scenario "The user is a member of the VHA Camo organziation" do
      # Check if the camo checkbox is disabled
      camo_checkbox = find("#vhaCAMO", visible: false)
      expect(camo_checkbox.disabled?).to eq(true)

      # Check for the display of the disabled options info message
      expect(page).to have_content(COPY::VHA_MEMBERSHIP_REQUEST_DISABLED_OPTIONS_INFO_MESSAGE)

      # Click a program office checkbox and submit should be enabled
      expect(page).to have_button("Submit", disabled: true)
      find("label[for='vhaCaregiverSupportProgram']").click
      expect(page).to have_button("Submit", disabled: false)
    end
  end

  context("Vha Membership for a user that has pending membership requests") do
    before do
      # Reload because it doesn't work without it apparently
      user_with_membership_requests.reload
      prosthetics_org.reload
      prosthetics_membership_request.reload
      User.authenticate!(user: user_with_membership_requests)
      visit "/vha/help"
    end

    scenario "The user has a pending request to the Prosthetics VHA program office" do
      # Check if the Prosthetics checkbox is disabled
      prosthetics_checkbox = find("#prosthetics", visible: false)
      expect(prosthetics_checkbox.disabled?).to eq(true)

      # Check for the display of the disabled options info message
      expect(page).to have_content(COPY::VHA_MEMBERSHIP_REQUEST_DISABLED_OPTIONS_INFO_MESSAGE)

      # Click a program office checkbox and submit should be enabled
      expect(page).to have_button("Submit", disabled: true)
      find("label[for='vhaCaregiverSupportProgram']").click
      expect(page).to have_button("Submit", disabled: false)
    end
  end

  context("Vha Membership Form for a user that is not authenticated") do
    scenario "A user that has not logged in should not be able to see the Vha membership request form" do
      visit "/vha/help"
      expect(page).to_not have_content("1. How do I access the VHA team?")
      expect(page).to_not have_button("Submit")
    end
  end
end
