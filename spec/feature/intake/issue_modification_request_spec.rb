# frozen_string_literal: true

feature "Issue Modification Request", :postgres do
  let(:veteran_file_number) { "123412345" }

  let(:veteran) do
    Generators::Veteran.build(file_number: veteran_file_number,
                              first_name: "Ed",
                              last_name: "Merica")
  end

  let!(:vha_org) { VhaBusinessLine.singleton }

  let!(:in_progress_hlr) do
    create(:higher_level_review,
           :with_vha_issue,
           :with_end_product_establishment,
           :processed,
           benefit_type: "vha",
           veteran: veteran,
           claimant_type: :veteran_claimant)
  end

  let!(:in_pending_hlr) do
    create(:higher_level_review,
           :with_vha_issue,
           :with_end_product_establishment,
           :processed,
           benefit_type: "vha",
           veteran: veteran,
           claimant_type: :veteran_claimant)
  end

  let!(:modified_request_issue) do
    create(:request_issue,
           benefit_type: "vha",
           nonrating_issue_category: "CHAMPVA",
           nonrating_issue_description: "A description of the newly added issue",
           decision_review: in_pending_hlr,
           decision_date: Time.zone.now - 10.days)
  end

  let!(:withdrawal_request_issue) do
    create(:request_issue,
           benefit_type: "vha",
           nonrating_issue_category: "Foreign Medical Program",
           nonrating_issue_description: "A description of the issue that is being withdrawn",
           decision_review: in_pending_hlr,
           decision_date: Time.zone.now - 10.days)
  end

  let!(:removal_request_issue) do
    create(:request_issue,
           benefit_type: "vha",
           nonrating_issue_category: "Medical and Dental Care Reimbursement",
           nonrating_issue_description: "A description of the issue that is being removed",
           decision_review: in_pending_hlr,
           decision_date: Time.zone.now - 10.days)
  end

  let!(:addition_modification_request) do
    create(:issue_modification_request,
           decision_review: in_pending_hlr,
           benefit_type: "vha",
           nonrating_issue_category: "Caregiver | Eligibility",
           nonrating_issue_description: "A description of a newly added issue",
           decision_date: Time.zone.now - 5.days)
  end

  let!(:removal_modification_request) do
    create(:issue_modification_request,
           decision_review: in_pending_hlr,
           request_type: :removal,
           nonrating_issue_category: removal_request_issue.nonrating_issue_category,
           nonrating_issue_description: removal_request_issue.nonrating_issue_description,
           decision_date: removal_request_issue.decision_date,
           request_issue: removal_request_issue)
  end

  let!(:withdrawal_modification_request) do
    create(:issue_modification_request,
           decision_review: in_pending_hlr,
           request_type: :withdrawal,
           nonrating_issue_category: withdrawal_request_issue.nonrating_issue_category,
           nonrating_issue_description: withdrawal_request_issue.nonrating_issue_description,
           decision_date: withdrawal_request_issue.decision_date,
           request_issue: withdrawal_request_issue,
           withdrawal_date: Time.zone.now)
  end

  let!(:modify_existing_modification_request) do
    create(:issue_modification_request,
           decision_review: in_pending_hlr,
           request_type: :modification,
           nonrating_issue_category: "Camp Lejune Family Member",
           nonrating_issue_description: "Newly modified issue description",
           decision_date: modified_request_issue.decision_date,
           request_issue: modified_request_issue)
  end

  let(:current_user) do
    User.authenticate!(roles: ["System Admin", "Certify Appeal", "Mail Intake", "Admin Intake"])
  end

  before do
    vha_org.add_user(current_user)
  end

  context "non-admin user" do
    it "does not enable the submit button until all fields are touched" do
      visit "higher_level_reviews/#{in_progress_hlr.uuid}/edit"

      expect(page).to have_content("Request additional issue")

      step "for modification" do
        within "#issue-#{in_progress_hlr.request_issues.first.id}" do
          first("select").select("Request modification")
        end

        expect(page).to have_button("Submit request", disabled: true)

        fill_in "Issue type", with: "Beneficiary Travel"
        find(".cf-select__option", exact_text: "Beneficiary Travel").click

        fill_in "Decision date", with: "05/15/2024"
        fill_in "Issue description", with: "An issue description"
        fill_in "Please provide a reason for the issue modification request", with: "I wanted to"

        expect(page).to have_button("Submit request", disabled: false)

        within ".cf-modal-body" do
          click_on "Cancel"
        end
      end

      step "for addition" do
        click_on "Request additional issue"

        expect(page).to have_button("Submit request", disabled: true)

        fill_in "Issue type", with: "Beneficiary Travel"
        find(".cf-select__option", exact_text: "Beneficiary Travel").click

        fill_in "Decision date", with: "05/15/2024"
        fill_in "Issue description", with: "An issue description"
        fill_in "Please provide a reason for the issue addition request", with: "I wanted to"

        expect(page).to have_button("Submit request", disabled: false)

        within ".cf-modal-body" do
          click_on "Cancel"
        end
      end

      step "for withdrawal" do
        within "#issue-#{in_progress_hlr.request_issues.first.id}" do
          first("select").select("Request withdrawal")
        end

        expect(page).to have_button("Submit request", disabled: true)

        fill_in "Request date for withdrawal", with: "05/15/2024"
        fill_in "Please provide a reason for the issue withdrawal request", with: "I wanted to"

        expect(page).to have_button("Submit request", disabled: false)

        within ".cf-modal-body" do
          click_on "Cancel"
        end
      end

      step "for removal" do
        within "#issue-#{in_progress_hlr.request_issues.first.id}" do
          first("select").select("Request removal")
        end

        expect(page).to have_button("Submit request", disabled: true)

        fill_in "Please provide a reason for the issue removal request", with: "I wanted to"

        expect(page).to have_button("Submit request", disabled: false)

        within ".cf-modal-body" do
          click_on "Cancel"
        end
      end
    end

    it "moves issues to the pending admin review section when the issue modification modal is submitted" do
      visit "higher_level_reviews/#{in_progress_hlr.uuid}/edit"

      expect(page).not_to have_text("Pending admin review")

      within "#issue-#{in_progress_hlr.request_issues.first.id}" do
        first("select").select("Request modification")
      end

      fill_in "Issue type", with: "Beneficiary Travel"
      find(".cf-select__option", exact_text: "Beneficiary Travel").click

      fill_in "Decision date", with: "05/15/2024"
      fill_in "Issue description", with: "An issue description"
      fill_in "Please provide a reason for the issue modification request", with: "I wanted to"

      click_on "Submit request"

      pending_section = find("tr", text: "Pending admin review")

      expect(pending_section).to have_text("An issue description")
      expect(pending_section).to have_text("I wanted to")
      expect(pending_section).to have_text("05/15/2024")
      expect(pending_section).to have_text("Beneficiary Travel")

      ri = in_progress_hlr.request_issues.first
      expect(pending_section).to have_text("Original Issue")
      expect(pending_section).to have_text("#{ri.nonrating_issue_category} - #{ri.nonrating_issue_description}".strip)
      expect(pending_section).to have_text(Constants::BENEFIT_TYPES["vha"])
      expect(pending_section).to have_text(ri.decision_date.strftime("%m/%d/%Y").to_s)

      # Verify that the banner is present on the page
      check_for_pending_requests_banner

      # Submit the page and verify that the issue modification requests were saved
      click_on "Save"

      # Verify that the page is redirected to the decision review queue
      expect(page).to have_content("Veterans Health Administration")

      # Verify the success banner
      expect(page).to have_content("You have successfully submitted a request.")
      expect(page).to have_content("#{in_progress_hlr.veteran_full_name}'s Higher-Level Review was saved.")

      # verify that is on the pending tab
      expect(page).to have_content(COPY::VHA_PENDING_REQUESTS_TAB_DESCRIPTION)
      expect(current_url).to include("/decision_reviews/vha?tab=pending")

      # TODO: This fetch might need to change if we create more than one
      issue_request = IssueModificationRequest.last

      # Verify the issue modification request attributes
      expect(issue_request.nonrating_issue_category).to eq("Beneficiary Travel")
      expect(issue_request.nonrating_issue_description).to eq("An issue description")
      expect(issue_request.decision_date).to eq(Date.strptime("05/15/2024", "%m/%d/%Y"))
      expect(issue_request.request_reason).to eq("I wanted to")
      expect(issue_request.request_issue).to eq(ri)
      expect(issue_request.requestor).to eq(current_user)
      expect(issue_request.status).to eq("assigned")
      expect(issue_request.request_type).to eq("modification")
      expect(issue_request.remove_original_issue).to eq(false)
      expect(issue_request.benefit_type).to eq("vha")

      # TODO: Add an addition request to this as well and confirm that both are created

      # TODO: Click the link as a non admin and verify that the pending requests are persisted
      # Update one of them and cancel another and save the page

      # TODO: Swap to admin click the link of the claim in the pending tab to revisit the edit page
      # Then accept or deny the issue request
    end
  end

  context "admin user" do
    before do
      OrganizationsUser.make_user_admin(current_user, vha_org)
      visit "higher_level_reviews/#{in_progress_hlr.uuid}/edit"
    end

    it "should open the edit issues page and not see the new non-admin content" do
      expect(page.has_no_content?("Request additional issue")).to eq(true)
    end

    it "should enable dropdown for Requested Issue Section if no pending request is present" do
      expect(page).not_to have_text("Pending admin review")

      within "#issue-#{in_progress_hlr.request_issues.first.id}" do
        select_action = find("select", text: "Select action")
        expect(select_action[:disabled]).to eq "false"
      end
    end

    it "+ Add Issues button for Admin edit should be enabled if no pending request is present" do
      expect(page).not_to have_text("Pending admin review")
      expect(page).to have_button("Add issue", disabled: false)
    end

    it "+ Add Issues button for Admin edit should be disabled if pending request is present" do
      visit "higher_level_reviews/#{in_pending_hlr.uuid}/edit"
      expect(page).to have_text("Pending admin review")
      expect(page).to have_button("Add issue", disabled: true)
    end

    it "should disable Select action dropdown for Requested Issue Section if pending request is present" do
      visit "higher_level_reviews/#{in_pending_hlr.uuid}/edit"

      expect(page).to have_text("Pending admin review")

      within "#issue-#{in_pending_hlr.request_issues.first.id}" do
        select_action = find("select", text: "Select action")
        expect(select_action[:disabled]).to eq "true"
      end
    end

    it "should have a dropdown with specific option for each request type" do
      visit "higher_level_reviews/#{in_pending_hlr.uuid}/edit"
      expect(page).to have_text("Pending admin review")

      step "request type Addition" do
        expect(page).to have_text("Requested Additional Issues")
        verify_admin_select_action_dropdown("addition")
      end

      step "request type modification" do
        expect(page).to have_text("Requested Changes")
        verify_admin_select_action_dropdown("modification")
      end

      step "request type removal" do
        expect(page).to have_text("Requested Issue Removal")
        verify_admin_select_action_dropdown("removal")
      end

      step "request type withdrawal" do
        expect(page).to have_text("Requested Issue Withdrawal")
        verify_admin_select_action_dropdown("withdrawal")
      end
    end
  end

  context "Claim with all 4 types of pending issue modification requests" do
    it "should display the banner and all 4 types of pending issue modification requests upon loading the page" do
      visit "higher_level_reviews/#{in_pending_hlr.uuid}/edit"

      check_for_pending_requests_banner

      expect(page).to have_content("Pending admin review")
      verify_addition_request(addition_modification_request)
      verify_removal_request(removal_modification_request)
      verify_modify_existing_issue_request(modify_existing_modification_request)
      verify_withdrawal_request(withdrawal_modification_request)
    end
  end

  def check_for_pending_requests_banner(visible = true)
    if visible
      expect(page).to have_content(COPY::PENDING_ISSUE_MODIFICATION_REQUESTS_BANNER_TITLE)
      expect(page).to have_content(COPY::PENDING_ISSUE_MODIFICATION_REQUESTS_BANNER_MESSAGE)
    else
      expect(page).to have_no_content(COPY::PENDING_ISSUE_MODIFICATION_REQUESTS_BANNER_TITLE)
      expect(page).to have_no_content(COPY::PENDING_ISSUE_MODIFICATION_REQUESTS_BANNER_MESSAGE)
    end
  end

  def displayed_user_name(user)
    "#{user.full_name} (#{user.css_id})"
  end

  def displayed_issue_type_and_description(issue_modification_request)
    "#{issue_modification_request.nonrating_issue_category} - #{issue_modification_request.nonrating_issue_description}"
  end

  def verify_addition_request(issue_modification_request)
    expect(page).to have_content("Requested Additional Issues")
    expect(page).to have_content("Reason for requested issue addition:")
    verify_shared_issue_modification_fields(issue_modification_request)
  end

  def verify_modify_existing_issue_request(issue_modification_request)
    expect(page).to have_content("Requested Changes")
    expect(page).to have_content("Reason for requested modification:")
    verify_shared_issue_modification_fields(issue_modification_request)

    original_request = issue_modification_request.request_issue
    # Original issue block
    expect(page).to have_content("Original Issue")
    expect(page).to have_content(displayed_issue_type_and_description(original_request))
    expect(page).to have_content("Benefit type: Veterans Health Administration")
    expect(page).to have_content("Decision date: #{original_request.decision_date.strftime('%m/%d/%Y')}")
  end

  def verify_withdrawal_request(issue_modification_request)
    expect(page).to have_content("Requested Issue Withdrawal")
    expect(page).to have_content("Reason for requested withdrawal of issue:")
    verify_shared_issue_modification_fields(issue_modification_request)

    # Additional withdrawal information
    expect(page).to have_content("Requested date for withdrawal:")
    expect(page).to have_content(issue_modification_request.withdrawal_date.strftime("%m/%d/%Y"))
  end

  def verify_removal_request(issue_modification_request)
    expect(page).to have_content("Requested Issue Removal")
    expect(page).to have_content("Reason for requested removal of issue:")
    verify_shared_issue_modification_fields(issue_modification_request)
  end

  def verify_shared_issue_modification_fields(issue_modification_request)
    expect(page).to have_content(displayed_issue_type_and_description(issue_modification_request))
    expect(page).to have_content("Benefit type: Veterans Health Administration")
    expect(page).to have_content(
      "Decision date: #{issue_modification_request.decision_date.strftime('%m/%d/%Y')}"
    )
    expect(page).to have_content(issue_modification_request.request_reason)
  end

  def verify_admin_select_action_dropdown(request_type)
    data_key = "div[data-key=issue-#{request_type}]"
    option = "Review issue #{request_type} request"
    modal_title = "Request issue #{request_type}"
    selector = page.find(data_key)
    dropdown_div = selector.find("div.cf-form-dropdown")
    dropdown_div.click
    expect(page).to have_text(option)
    # click_dropdown(text: "#{option} request", container = selector)
    click_dropdown(name: "select-action-#{request_type}", text: option)
    expect(page).to have_text(modal_title)
    click_on "Cancel"
  end
end
