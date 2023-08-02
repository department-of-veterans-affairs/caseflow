# frozen_string_literal: true

RSpec.feature "VhaTeamManagement" do
  let(:vha_business_line) { VhaBusinessLine.singleton }
  let(:camo_org) { VhaCamo.singleton }
  let(:vha_admin) { create(:user, full_name: "VHA ADMIN", css_id: "VHA_ADMIN") }

  before do
    OrganizationsUser.make_user_admin(vha_admin, vha_business_line)
    OrganizationsUser.make_user_admin(vha_admin, camo_org)
    User.authenticate!(user: vha_admin)
    vha_request.reload
    requestor.reload
    ActiveJob::Base.queue_adapter.enqueued_jobs.clear
  end

  context("Vha Business Line requests") do
    let(:new_user_name) { "Gaius Baelsar" }
    let(:requested_org) { vha_business_line }
    let(:requestor) do
      requestor = create(:user, full_name: new_user_name, email: "test@test.com", css_id: "VHA_REQUESTOR")
      requestor.save
      requestor
    end
    let(:vha_request) do
      request = create(:membership_request, requestor: requestor, organization: requested_org)
      request.save
      request
    end
    let(:title_action_verb) { "approved" }
    let(:body_action_verb) { (title_action_verb == "approved") ? "granted" : title_action_verb }
    let(:success_message_title) do
      format(COPY::MEMBERSHIP_REQUEST_ACTION_SUCCESS_TITLE, title_action_verb, new_user_name)
    end
    let(:success_message_body) do
      format(COPY::MEMBERSHIP_REQUEST_ACTION_SUCCESS_MESSAGE, body_action_verb, requested_org.name)
    end

    scenario "Approving a user request to the vha business line" do
      visit "/organizations/vha/users"
      click_button "Select action"
      click_link "Approve"

      # Verify the success message
      expect(page).to have_content(success_message_title)
      expect(page).to have_content(success_message_body)

      # Verify the User was added to the page and removed from the list of requests
      expect(page).to have_content("View 0 pending requests")
      expect(page).to have_content("#{requestor.full_name} (#{requestor.css_id})")

      # Verify the user was added to the vha org
      expect(requestor.reload.member_of_organization?(requested_org)).to eq(true)

      # Verify the request data
      expect(vha_request.reload.status).to eq("approved")
      expect(vha_request.decider).to eq(vha_admin)
      expect(vha_request.decided_at).to_not eq(nil)

      # Verify the email job was queue successfully
      jobs = ActiveJob::Base.queue_adapter.enqueued_jobs
        .select { |job| job[:job] == Memberships::SendMembershipRequestMailerJob }

      expect(jobs.first[:args]).to include("VhaBusinessLineApproved")
      expect(jobs).to be_an(Array)
      expect(jobs.length).to eq(1)
      expect(jobs.map { |job| job[:queue] }).to all(eq "caseflow_test_low_priority")
    end

    context("denying a request") do
      let(:title_action_verb) { "denied" }

      scenario "Denying a user request to the vha business line" do
        visit "/organizations/vha/users"
        click_button "Select action"
        click_link "Deny"

        # Verify the success message
        expect(page).to have_content(success_message_title)
        expect(page).to have_content(success_message_body)

        # Verify the User was not added to the page and removed from the list of requests
        expect(page).to have_content("View 0 pending requests")
        expect(page).to_not have_content("#{requestor.full_name} (#{requestor.css_id})")

        # Verify the user was not added to the vha org
        expect(requestor.reload.member_of_organization?(requested_org)).to eq(false)

        # Verify the request data
        expect(vha_request.reload.status).to eq("denied")
        expect(vha_request.decider).to eq(vha_admin)
        expect(vha_request.decided_at).to_not eq(nil)

        # Verify the email job was queue successfully
        jobs = ActiveJob::Base.queue_adapter.enqueued_jobs
          .select { |job| job[:job] == Memberships::SendMembershipRequestMailerJob }

        expect(jobs.first[:args]).to include("VhaBusinessLineDenied")
        expect(jobs).to be_an(Array)
        expect(jobs.length).to eq(1)
        expect(jobs.map { |job| job[:queue] }).to all(eq "caseflow_test_low_priority")
      end
    end
  end

  context("Vha Predocket Organization requests") do
    let(:new_user_name) { "Gaius Baelsar" }
    let(:requestor) do
      requestor = create(:user, full_name: new_user_name, email: "test@test.com", css_id: "VHA_REQUESTOR")
      requestor.save
      requestor
    end
    let(:requested_org) { camo_org }
    let(:vha_request) do
      request = create(:membership_request, requestor: requestor, organization: requested_org)
      request.save
      request
    end
    let(:title_action_verb) { "approved" }
    let(:body_action_verb) { (title_action_verb == "approved") ? "granted" : title_action_verb }
    let(:success_message_title) do
      format(COPY::MEMBERSHIP_REQUEST_ACTION_SUCCESS_TITLE, title_action_verb, new_user_name)
    end
    let(:success_message_body) do
      format(COPY::MEMBERSHIP_REQUEST_ACTION_SUCCESS_MESSAGE, body_action_verb, requested_org.name)
    end

    scenario "Approving a user request to VHA Camo" do
      visit "/organizations/vha-camo/users"
      click_button "Select action"
      click_link "Approve"

      # Verify the success message
      expect(page).to have_content(success_message_title)
      expect(page).to have_content(success_message_body)

      # Verify the User was added to the page and removed from the list of requests
      expect(page).to have_content("View 0 pending requests")
      expect(page).to have_content("#{requestor.full_name} (#{requestor.css_id})")

      # Verify the user was added to the camo org and also the vha organization
      expect(requestor.reload.member_of_organization?(requested_org)).to eq(true)
      expect(requestor.member_of_organization?(vha_business_line)).to eq(true)

      # Verify the request data
      expect(vha_request.reload.status).to eq("approved")
      expect(vha_request.decider).to eq(vha_admin)
      expect(vha_request.decided_at).to_not eq(nil)

      # Verify the email job was queue successfully
      jobs = ActiveJob::Base.queue_adapter.enqueued_jobs
        .select { |job| job[:job] == Memberships::SendMembershipRequestMailerJob }

      expect(jobs.first[:args]).to include("VhaPredocketApproved")
      expect(jobs).to be_an(Array)
      expect(jobs.length).to eq(1)
      expect(jobs.map { |job| job[:queue] }).to all(eq "caseflow_test_low_priority")
    end

    context("denying a request") do
      let(:title_action_verb) { "denied" }

      scenario "Denying a user request to VHA Camo" do
        visit "/organizations/vha-camo/users"
        click_button "Select action"
        click_link "Deny"

        # Verify the success message
        expect(page).to have_content(success_message_title)
        expect(page).to have_content(success_message_body)

        # Verify the User was not added to the page and removed from the list of requests
        expect(page).to have_content("View 0 pending requests")
        expect(page).to_not have_content("#{requestor.full_name} (#{requestor.css_id})")

        # Verify the user was not added to the camo org and also not added to the vha org
        expect(requestor.reload.member_of_organization?(requested_org)).to eq(false)
        expect(requestor.member_of_organization?(vha_business_line)).to eq(false)

        # Verify the request data
        expect(vha_request.reload.status).to eq("denied")
        expect(vha_request.decider).to eq(vha_admin)
        expect(vha_request.decided_at).to_not eq(nil)

        # Verify the email job was queue successfully
        jobs = ActiveJob::Base.queue_adapter.enqueued_jobs
          .select { |job| job[:job] == Memberships::SendMembershipRequestMailerJob }

        expect(jobs.first[:args]).to include("VhaPredocketDenied")
        expect(jobs).to be_an(Array)
        expect(jobs.length).to eq(1)
        expect(jobs.map { |job| job[:queue] }).to all(eq "caseflow_test_low_priority")
      end
    end
  end
end
