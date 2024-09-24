# frozen_string_literal: true

feature "Reassign Cases to Camo feature test", :postgres do
  let(:ssn) { Generators::Random.unique_ssn }
  let(:ssn2) { Generators::Random.unique_ssn }
  let(:ssn3) { Generators::Random.unique_ssn }
  let(:ssn4) { Generators::Random.unique_ssn }
  let(:veteran) { create(:veteran, file_number: "000000000", ssn: ssn) }
  let(:veteran2) { create(:veteran, file_number: "123445459", ssn: ssn2) }
  let(:veteran3) { create(:veteran, file_number: ssn3, ssn: ssn3) }
  let(:veteran4) { create(:veteran, file_number: ssn4, ssn: ssn3) }

  let!(:vha_org) { VhaBusinessLine.singleton }
  let!(:current_user) do
    User.authenticate!(roles: ["Mail Intake", "Admin Intake"])
  end

  before do
    vha_org.add_user(current_user)
  end

  let!(:in_progress_hlr) do
    create(:higher_level_review,
           :with_vha_issue,
           :with_end_product_establishment,
           :processed,
           :update_assigned_at,
           benefit_type: "vha",
           veteran: veteran,
           claimant_type: :veteran_claimant)
  end

  let!(:in_progress_hlr_removal) do
    create(:higher_level_review,
           :with_vha_issue,
           :with_end_product_establishment,
           :processed,
           :update_assigned_at,
           benefit_type: "vha",
           veteran: veteran2,
           claimant_type: :veteran_claimant)
  end

  let!(:in_progress_hlr_withdrawal) do
    create(:higher_level_review,
           :with_vha_issue,
           :with_end_product_establishment,
           :processed,
           :update_assigned_at,
           benefit_type: "vha",
           veteran: veteran3,
           claimant_type: :veteran_claimant)
  end

  let!(:in_progress_hlr_modification) do
    create(:higher_level_review,
           :with_vha_issue,
           :with_end_product_establishment,
           :processed,
           :update_assigned_at,
           benefit_type: "vha",
           veteran: veteran4,
           claimant_type: :veteran_claimant)
  end

  describe "issue modification request and approval workflow" do
    it "should be able to request new issue addition and admin should be able to approve requested issues" do
      visit_decision_review

      step "non admin makes Issue Adition Request" do
        click_to_edit_page(veteran, in_progress_hlr)

        expect(page).to have_text("Request additional issue")
        click_on "Request additional issue"

        expect(page).to have_button("Submit request", disabled: true)

        fill_in "Issue type", with: "Beneficiary Travel"
        find(".cf-select__option", exact_text: "Beneficiary Travel").click

        fill_in "Decision date", with: "05/15/2024"
        fill_in "Issue description", with: "Adding issue description"
        fill_in "Please provide a reason for the issue addition request", with: "Lets test this addition"

        expect(page).to have_button("Submit request", disabled: false)
        within ".cf-modal-body" do
          click_on "Submit request"
        end

        expect(current_url).to have_text("higher_level_reviews/#{in_progress_hlr.uuid}/edit")

        expect(page).to have_text("Requested Additional Issues")

        pending_section = find("tr", text: "Pending admin review")

        expect(pending_section).to have_text("Beneficiary Travel - Adding issue description")
        expect(pending_section).to have_text("Lets test this addition")
        expect(pending_section).to have_text("05/15/2024")
        expect(pending_section).to have_text("Benefit type: Veterans Health Administration")
        click_on_save(in_progress_hlr)

        expect(page).to have_content("You have successfully submitted a request.")
        expect(page).to have_content("#{in_progress_hlr.claimant.name}'s #{HigherLevelReview.review_title} was saved.")
      end

      step "admin approves Issue Addition request" do
        make_current_user_admin

        visit "/decision_reviews/vha?tab=pending&page=1&sort_by=daysWaitingColumn&order=desc"
        click_link veteran.name.to_s
        expect(current_url).to have_text("higher_level_reviews/#{in_progress_hlr.uuid}/edit")

        expect(page).to have_text("Requested Additional Issues")
        expect(page).to have_text("Pending admin review")
        data_key = "div[data-key=issue-addition]"
        selector = page.find(data_key)
        dropdown_div = selector.find("div.cf-form-dropdown")
        dropdown_div.click
        option = "Review issue addition request"
        expect(page).to have_text(option)
        click_dropdown(name: "select-action-addition", text: option)
        expect(page).to have_text("Request issue addition")
        expect(page).to have_button("Confirm", disabled: true)
        expect(page).to have_text("Reject request")
        find('label[for="status_denied"]').click
        expect(page).to have_button("Confirm", disabled: true) # this should be uncommented after the file merge
        find('label[for="status_approved"]').click
        click_on "Confirm"
        click_establish
      end
    end

    it "should be able to request issue removal and admin should be able to approve it" do
      visit_decision_review
      vet_name_and_claim = "#{in_progress_hlr_removal.claimant.name}'s #{HigherLevelReview.review_title}"

      step "request issue removal" do
        click_to_edit_page(veteran2, in_progress_hlr_removal)
        non_admin_request_type("removal", in_progress_hlr_removal)
        fill_in "Please provide a reason for the issue removal request", with: "this issue is bad."

        expect(page).to have_button("Submit request", disabled: false)
        within ".cf-modal-body" do
          click_on "Submit request"
        end
        expect(current_url).to have_text("higher_level_reviews/#{in_progress_hlr_removal.uuid}/edit")
        expect(page).to have_text "Requested Issue Removal"
        expect(page).to have_text "Reason for requested removal of issue"
        expect(page).to have_text "this issue is bad"
        expect(page).to have_text "Requested by"
        expect(page).to have_text "#{current_user.full_name} (#{current_user.css_id})"

        # Also create an addition
        click_on "Request additional issue"

        expect(page).to have_button("Submit request", disabled: true)

        fill_in "Issue type", with: "Beneficiary Travel"
        find(".cf-select__option", exact_text: "Beneficiary Travel").click

        fill_in "Decision date", with: "05/15/2024"
        fill_in "Issue description", with: "Adding issue description"
        fill_in "Please provide a reason for the issue addition request", with: "Lets test this addition"

        expect(page).to have_button("Submit request", disabled: false)
        within ".cf-modal-body" do
          click_on "Submit request"
        end

        click_on_save(in_progress_hlr_removal)

        expect(page).to have_content("You have successfully submitted a request.")
        expect(page).to have_content("#{vet_name_and_claim} was saved.")
      end

      step "approve issue removal request by admin" do
        make_current_user_admin

        visit "/decision_reviews/vha?tab=pending&page=1&sort_by=daysWaitingColumn&order=desc"
        click_link veteran2.name.to_s
        expect(current_url).to have_text("higher_level_reviews/#{in_progress_hlr_removal.uuid}/edit")

        expect(page).to have_text("Requested Issue Removal")
        expect(page).to have_text("Pending admin review")
        data_key = "div[data-key=issue-removal]"
        selector = page.find(data_key)
        dropdown_div = selector.find("div.cf-form-dropdown")
        dropdown_div.click
        option = "Review issue removal request"
        expect(page).to have_text(option)
        click_dropdown(name: "select-action-removal", text: option)
        expect(page).to have_text("Request issue removal")
        expect(page).to have_button("Confirm", disabled: true)
        expect(page).to have_text("Reject request")
        find('label[for="status_denied"]').click
        expect(page).to have_button("Confirm", disabled: true)
        find('label[for="status_approved"]').click
        click_on "Confirm"
        expect(page).to have_text("Remove issue")
        expect(page).to have_text("The contention you selected will be removed from the decision review.")
        click_button "Remove"

        # Check for my new banner here
        banner_text = "All pending issue addition requests must be reviewed before the claim can be saved."
        expect(page).to have_content(banner_text)
        expect(page).to have_button("Save", disabled: true)

        click_dropdown(text: "Review issue addition request")
        find('label[for="status_denied"]').click
        fill_in "Provide a reason for rejection", with: "Testing rejection of an addition"
        click_on "Confirm"

        expect(page).not_to have_text(banner_text)
        expect(page).to have_button("Establish", disabled: false)

        expect(current_url).to include("higher_level_reviews/#{in_progress_hlr_removal.uuid}/edit")
        expect(page).to have_button("Establish", disabled: false)
        click_on("Establish")
        expect(page).to have_text("Delete appeal and cancel all tasks")
        expect(page).to have_text("The review originally had 1 issue but now has 0")
        expect(page).to have_text("Removing the last issue will cancel all tasks")
        click_on "Remove"

        # Verify that we are back on the in progress tab
        expect(page).to have_content("Reviews needing action")
        expect(current_url).to include("/decision_reviews/vha?tab=in_progress")
        expect(page).to have_content("The claim has been removed.")
        expect(page).to have_content("You have successfully edited #{vet_name_and_claim}")
      end
    end

    it "should be able to request issue withdrawal and admin should be able to approve it" do
      visit_decision_review

      step "request issue withdrawal" do
        click_to_edit_page(veteran3, in_progress_hlr_withdrawal)
        non_admin_request_type("withdrawal", in_progress_hlr_withdrawal)
        expect(page).to have_text "Request date for withdrawal"
        expect(page).to have_text "Withdrawal request reason"
        fill_in "Request date for withdrawal", with: 5.days.ago
        fill_in "Please provide a reason for the issue withdrawal request", with: "this is withdrawan"
        expect(page).to have_button("Submit request", disabled: false)

        within ".cf-modal-body" do
          click_on "Submit request"
        end

        expect(current_url).to have_text("higher_level_reviews/#{in_progress_hlr_withdrawal.uuid}/edit")
        expect(page).to have_text "Requested Issue Withdrawal"
        expect(page).to have_text "Reason for requested withdrawal of issue"
        expect(page).to have_text "this is withdrawan"
        expect(page).to have_text "Requested by"
        expect(page).to have_text "#{current_user.full_name} (#{current_user.css_id})"
        click_on_save(in_progress_hlr_withdrawal)
      end

      step "admin should be able to approve withdrawal" do
        make_current_user_admin

        visit "/decision_reviews/vha?tab=pending&page=1&sort_by=daysWaitingColumn&order=desc"
        click_link veteran3.name.to_s
        expect(current_url).to have_text("higher_level_reviews/#{in_progress_hlr_withdrawal.uuid}/edit")

        expect(page).to have_text("Requested Issue Withdrawal")
        expect(page).to have_text("Pending admin review")
        data_key = "div[data-key=issue-withdrawal]"
        selector = page.find(data_key)
        dropdown_div = selector.find("div.cf-form-dropdown")
        dropdown_div.click
        option = "Review issue withdrawal request"
        expect(page).to have_text(option)
        click_dropdown(name: "select-action-withdrawal", text: option)
        expect(page).to have_text("Request issue withdrawal")
        expect(page).to have_button("Confirm", disabled: true)
        expect(page).to have_text("Reject request")
        find('label[for="status_denied"]').click
        expect(page).to have_button("Confirm", disabled: true)
        find('label[for="status_approved"]').click
        click_on "Confirm"

        expect(current_url).to include("higher_level_reviews/#{in_progress_hlr_withdrawal.uuid}/edit")
        expect(page).to have_button("Withdraw", disabled: false)
        click_on("Withdraw")

        expect(page).to have_text("You have successfully edited #{veteran3.name}'s Higher-Level Review")
        expect(current_url).to have_content("tab=in_progress&page=1&sort_by=daysWaitingColumn&order=desc")
      end
    end

    it "should be able to request issue modification and admin should be able to approve it" do
      visit_decision_review

      step "request issue modification" do
        click_to_edit_page(veteran4, in_progress_hlr_modification)
        non_admin_request_type("modification", in_progress_hlr_modification)
        fill_in "Issue type", with: "Clothing Allowance"
        find(".cf-select__option", exact_text: "Clothing Allowance").click

        fill_in "Decision date", with: "05/15/2024"
        fill_in "Issue description", with: "An issue description"
        fill_in "Please provide a reason for the issue modification request", with: "I need money to buy cloths"
        expect(page).to have_button("Submit request", disabled: false)

        within ".cf-modal-body" do
          click_on "Submit request"
        end

        expect(current_url).to have_text("higher_level_reviews/#{in_progress_hlr_modification.uuid}/edit")
        expect(page).to have_text "Requested Changes"
        expect(page).to have_text "Reason for requested modification"
        expect(page).to have_text "I need money to buy cloths"
        expect(page).to have_text "Requested by"
        expect(page).to have_text "#{current_user.full_name} (#{current_user.css_id})"
        click_on_save(in_progress_hlr_modification)
      end

      step "admin should be able to approve modification" do
        make_current_user_admin

        visit "/decision_reviews/vha?tab=pending&page=1&sort_by=daysWaitingColumn&order=desc"
        click_link veteran4.name.to_s
        expect(current_url).to have_text("higher_level_reviews/#{in_progress_hlr_modification.uuid}/edit")

        expect(page).to have_text("Requested Changes")
        expect(page).to have_text("Pending admin review")
        data_key = "div[data-key=issue-modification]"
        selector = page.find(data_key)
        dropdown_div = selector.find("div.cf-form-dropdown")
        dropdown_div.click
        option = "Review issue modification request"
        expect(page).to have_text(option)
        click_dropdown(name: "select-action-modification", text: option)
        expect(page).to have_text("Request issue modification")
        expect(page).to have_button("Confirm", disabled: true)
        expect(page).to have_text("Reject request")
        find('label[for="status_denied"]').click
        expect(page).to have_button("Confirm", disabled: true)
        find('label[for="status_approved"]').click
        click_on "Confirm"
        requested_issues = page.find("tr", text: "Requested issues")
        total_issue_count = requested_issues.find(".issues").find_css(".issue-container").count
        expect(total_issue_count).to eq 2
        expect(current_url).to include("higher_level_reviews/#{in_progress_hlr_modification.uuid}/edit")
        expect(page).to have_text(COPY::VHA_BANNER_FOR_NEWLY_APPROVED_REQUESTED_ISSUE)
        expect(page).to have_button("Establish", disabled: false)
        click_establish
      end
    end
  end

  def click_to_edit_page(veteran, hlr)
    click_link veteran.name.to_s
    expect(current_url).to have_text("/decision_reviews/vha/tasks/")
    expect(page).to have_link("Request issue modification", href: hlr.caseflow_only_edit_issues_url)
    expect(page).to have_button("Edit Issues", disabled: true)
    click_on "Request issue modification"
    expect(current_url).to have_text("higher_level_reviews/#{hlr.uuid}/edit")
    class_name_for_requested_issues_section = page.find(".issues")
    expect(class_name_for_requested_issues_section.find_css(".issue-container").count).to be 1
  end

  def click_on_save(hlr)
    expect(page).to have_button("Save", disabled: false)

    click_on "Save"
    expect(page).to have_text("You have successfully submitted a request.")
    expect(page).to have_text(
      "#{hlr.veteran.first_name} #{hlr.veteran.last_name}'s Higher-Level Review was saved."
    )
    expect(current_url).to have_content("tab=pending&page=1&sort_by=daysWaitingColumn&order=desc")
  end

  def make_current_user_admin
    OrganizationsUser.make_user_admin(current_user, vha_org)
    current_user.reload
  end

  def click_establish
    expect(page).to have_button("Establish", disabled: false)
    click_on("Establish")
    expect(page).to have_content("Number of issues has changed")
    expect(page).to have_content("The review originally had 1 issue but now has 2")
    click_on("Confirm")
    expect(page).to have_text("You have successfully edited")
    expect(page).to have_text("The claim has been modified.")
    expect(current_url).to have_content("tab=in_progress&page=1&sort_by=daysWaitingColumn&order=desc")
  end

  def visit_decision_review
    visit "/decision_reviews/vha?tab=in_progress&page=1&sort_by=daysWaitingColumn&order=desc"
    expect(page).to have_text("Veterans Health Administration")
  end

  def non_admin_request_type(request_type, hlr)
    within "#issue-#{hlr.request_issues.first.id}" do
      click_dropdown(text: "Request #{request_type}")
    end
    expect(page).to have_button("Submit request", disabled: true)
    expect(page).to have_text "Request issue #{request_type}"
    expect(page).to have_text "Current issue"
    expect(page).to have_text("Caregiver | Other")
    expect(page).to have_text("Issue description")
  end
end
