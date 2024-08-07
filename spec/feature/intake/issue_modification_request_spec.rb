# frozen_string_literal: true

feature "Issue Modification Request", :postgres do
  let(:veteran_file_number) { "998785765" }

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
           decision_date: Time.zone.now - 5.days,
           requestor: current_user)
  end

  let!(:removal_modification_request) do
    create(:issue_modification_request,
           decision_review: in_pending_hlr,
           request_type: :removal,
           nonrating_issue_category: removal_request_issue.nonrating_issue_category,
           nonrating_issue_description: removal_request_issue.nonrating_issue_description,
           decision_date: removal_request_issue.decision_date,
           request_issue: removal_request_issue,
           requestor: current_user)
  end

  let!(:withdrawal_modification_request) do
    create(:issue_modification_request,
           decision_review: in_pending_hlr,
           request_type: :withdrawal,
           nonrating_issue_category: withdrawal_request_issue.nonrating_issue_category,
           nonrating_issue_description: withdrawal_request_issue.nonrating_issue_description,
           decision_date: withdrawal_request_issue.decision_date,
           request_issue: withdrawal_request_issue,
           withdrawal_date: (Time.zone.now - 1.day).beginning_of_day)
  end

  let!(:modify_existing_modification_request) do
    create(:issue_modification_request,
           decision_review: in_pending_hlr,
           request_type: :modification,
           nonrating_issue_category: "Camp Lejune Family Member",
           nonrating_issue_description: "Newly modified issue description",
           decision_date: modified_request_issue.decision_date,
           request_issue: modified_request_issue,
           requestor: current_user)
  end

  let(:current_user) do
    User.authenticate!(roles: ["System Admin", "Certify Appeal", "Mail Intake", "Admin Intake"])
  end

  before do
    vha_org.add_user(current_user)
    Timecop.freeze
  end

  after do
    Timecop.return
  end

  context "non-admin user" do
    it "does not enable the submit button until all fields are touched" do
      visit "higher_level_reviews/#{in_progress_hlr.uuid}/edit"

      expect(page).to have_content("Request additional issue")

      step "for modification" do
        within "#issue-#{in_progress_hlr.request_issues.first.id}" do
          click_dropdown(text: "Request modification")
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
          click_dropdown(text: "Request withdrawal")
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
          click_dropdown(text: "Request removal")
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
        click_dropdown(text: "Request modification")
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
      expect(page).to have_content("Reviews needing action")

      # Verify the success banner
      expect(page).to have_content("You have successfully submitted a request.")
      expect(page).to have_content("#{in_progress_hlr.veteran_full_name}'s Higher-Level Review was saved.")

      # verify that is on the pending tab
      expect(page).to have_content(COPY::VHA_PENDING_REQUESTS_TAB_DESCRIPTION)
      expect(current_url).to include("/decision_reviews/vha?tab=pending")

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
        expect(page).not_to have_css(".cf-select__control--is-disabled")
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
        expect(page).to have_css(".cf-select__control--is-disabled")
      end
    end

    it "should have a dropdown with specific option for each request type and approval flow" do
      visit "higher_level_reviews/#{in_pending_hlr.uuid}/edit"
      expect(page).to have_text("Pending admin review")

      step "request type Addition and request approval" do
        expect(page).to have_text("Requested Additional Issues")
        verify_select_action_dropdown("addition")
        click_approve("addition")
        expect(current_url).to include("higher_level_reviews/#{in_pending_hlr.uuid}/edit")
        expect(page).to have_text(COPY::VHA_BANNER_FOR_NEWLY_APPROVED_REQUESTED_ISSUE)
        class_name_for_requested_issues_section = page.find(".issues")
        expect(class_name_for_requested_issues_section.find_css(".issue-container").count).to be 2
        expect(page).not_to have_text("Requested Additional Issues")
      end

      step "request type removal and request approval" do
        expect(page).to have_text("Requested Issue Removal")
        verify_select_action_dropdown("removal")
        click_approve("removal")
        expect(page).to have_text("Remove issue")
        expect(page).to have_text("The contention you selected will be removed from the decision review.")
        click_button "Remove"
        expect(current_url).to include("higher_level_reviews/#{in_pending_hlr.uuid}/edit")
        expect(page).not_to have_text("Requested Issue Removal")
      end

      step "request type withdrawal and request approval" do
        expect(page).not_to have_text("Withdrawn issues")
        expect(page).to have_text("Requested Issue Withdrawal")
        verify_select_action_dropdown("withdrawal")
        click_approve("withdrawal")
        expect(current_url).to include("higher_level_reviews/#{in_pending_hlr.uuid}/edit")
        expect(page).to have_text("Withdrawn issues")
        expect(page).to have_text("Withdrawal pending")
        expect(page).not_to have_text("Requested Issue Withdrawal")
      end

      step "request type modification when remove original issue is not selected" do
        expect(page).to have_text("Requested Changes")
        verify_select_action_dropdown("modification")
        click_approve("modification")
        expect(current_url).to include("higher_level_reviews/#{in_pending_hlr.uuid}/edit")
        requested_issues = page.find("tr", text: "Requested issues")
        total_issue_count = requested_issues.find(".issues").find_css(".issue-container").count
        expect(total_issue_count).to eq 4
        expect(page).not_to have_text("Requested Changes")
      end
    end

    it "should create remove original issue and create only 1 new issue when issue modification request is approved" do
      visit "higher_level_reviews/#{in_pending_hlr.uuid}/edit"
      expect(page).to have_text("Requested Changes")
      verify_select_action_dropdown("modification")
      find('label[for="status_approved"]').click
      expect(page).to have_text("Remove original issue")
      find('label[for="removeOriginalIssue"]').click
      click_on "Confirm"
      expect(page).to have_text("Confirm changes")
      expect(page).to have_text("Delete original issue")
      expect(page).to have_text("Issue type: CHAMPVA")
      expect(page).to have_text("Issue description: A description of the newly added issue")
      expect(page).to have_text("Create new issue")
      expect(page).to have_text("Issue type: Camp Lejune Family Member")
      expect(page).to have_text("Issue description: Newly modified issue description")
      click_on "Confirm"

      expect(current_url).to include("higher_level_reviews/#{in_pending_hlr.uuid}/edit")
      requested_issues = page.find("tr", text: "Requested issues")
      total_issue_count = requested_issues.find(".issues").find_css(".issue-container").count
      expect(total_issue_count).to eq 2
      expect(page).not_to have_text("Requested Changes")
      expect(page).not_to have_text(COPY::VHA_BANNER_FOR_NEWLY_APPROVED_REQUESTED_ISSUE)
    end

    it "should remove pending request if issue modification request was rejected" do
      visit "higher_level_reviews/#{in_pending_hlr.uuid}/edit"
      expect(page).to have_text("Pending admin review")

      step "request type Addition and request rejected" do
        expect(page).to have_text("Requested Additional Issues")
        verify_select_action_dropdown("addition")
        click_reject
        verify_rejection_count(1, "Requested Additional Issues")
      end

      step "request type removal and request rejected" do
        expect(page).to have_text("Requested Issue Removal")
        verify_select_action_dropdown("removal")
        click_reject
        verify_rejection_count(2, "Requested Issue Removal")
      end

      step "request type withdrawal and request approval" do
        expect(page).not_to have_text("Withdrawn issues")
        expect(page).to have_text("Requested Issue Withdrawal")
        verify_select_action_dropdown("withdrawal")
        click_reject
        verify_rejection_count(3, "Requested Issue Withdrawal")
      end

      step "request type modification when remove original issue is not selected" do
        expect(page).to have_text("Requested Changes")
        verify_select_action_dropdown("modification")
        click_reject
        verify_rejection_count(4, "Requested Changes")
      end
    end
  end

  context "non admin user" do
    it "should have a dropdown with specific option for each request type" do
      visit "higher_level_reviews/#{in_pending_hlr.uuid}/edit"
      expect(page).to have_text("Pending admin review")

      step "request type Addition" do
        expect(page).to have_text("Requested Additional Issues")
        verify_select_action_dropdown("addition", false)
      end

      step "request type modification" do
        expect(page).to have_text("Requested Changes")
        verify_select_action_dropdown("modification", false)
      end

      step "request type removal" do
        expect(page).to have_text("Requested Issue Removal")
        verify_select_action_dropdown("removal", false)
      end

      step "request type withdrawal" do
        expect(page).to have_text("Requested Issue Withdrawal")

        within "div[data-key=issue-withdrawal]" do
          select_action = find("input", visible: false)
          expect(select_action[:disabled]).to eq "true"
        end
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

  # rubocop:disable convention:Metrics/PerceivedComplexity
  def verify_select_action_dropdown(request_type, admin = true)
    data_key = "div[data-key=issue-#{request_type}]"
    if admin
      option = "Review issue #{request_type} request"
      modal_title = "Request issue #{request_type}"
    else
      option = "Edit #{request_type} request"
      modal_title = "Edit pending request"
    end
    selector = page.find(data_key)
    dropdown_div = selector.find("div.cf-form-dropdown")
    dropdown_div.click
    expect(page).to have_text(option)
    click_dropdown(name: "select-action-#{request_type}", text: option)
    expect(page).to have_text(modal_title)
    expect(page).to have_button("Confirm", disabled: true) if admin
    expect(page).to have_text("Approve request") if admin
    expect(page).to have_text("Reject request") if admin
    click_on "Cancel" unless admin
  end
  # rubocop:enable convention:Metrics/PerceivedComplexity

  def click_approve(request_type)
    find('label[for="status_approved"]').click
    expect(page).to have_text("Remove original issue") if request_type == "modification"
    click_on "Confirm"
  end

  def click_reject
    find('label[for="status_denied"]').click
    expect(page).to have_text("Provide a reason for rejection")
    fill_in "decisionReason", with: "Because i do not agree with you."
    click_on "Confirm"
    expect(current_url).to include("higher_level_reviews/#{in_pending_hlr.uuid}/edit")
  end

  def verify_rejection_count(issue_count, section_title)
    class_name_for_requested_issues_section = page.find(".issues")
    expect(class_name_for_requested_issues_section.find_css(".issue-container").count).to be issue_count
    expect(page).not_to have_text(section_title)
  end
end
