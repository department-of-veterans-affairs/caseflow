# frozen_string_literal: true

feature "Appeal Edit issues", :all_dbs do
  include IntakeHelpers

  before do
    Timecop.freeze(post_ama_start_date)

    # skip the sync call since all edit requests require resyncing
    # currently, we're not mocking out vbms and bgs
    allow_any_instance_of(EndProductEstablishment).to receive(:sync!).and_return(nil)
    non_comp_org.add_user(current_user)
  end

  let(:veteran) do
    create(:veteran,
           first_name: "Ed",
           last_name: "Merica")
  end

  let!(:current_user) do
    User.authenticate!(roles: ["Mail Intake"])
  end

  let!(:non_comp_org) { create(:business_line, name: "Non-Comp Org", url: "nco") }
  let(:last_week) { Time.zone.now - 7.days }
  let(:receipt_date) { Time.zone.today - 20.days }
  let(:profile_date) { (receipt_date - 30.days).to_datetime }

  let!(:rating) { generate_rating_with_defined_contention(veteran, receipt_date, profile_date) }
  let!(:rating_before_ama) { generate_pre_ama_rating(veteran) }
  let!(:rating_before_ama_from_ramp) { generate_rating_before_ama_from_ramp(veteran) }
  let!(:ratings_with_legacy_issues) do
    generate_rating_with_legacy_issues(veteran, receipt_date - 4.days, receipt_date - 4.days)
  end
  let(:request_issue_decision_mdY) { rating_request_issue.decision_or_promulgation_date.mdY }

  let(:legacy_opt_in_approved) { false }

  let!(:appeal) do
    create(:appeal,
           veteran_file_number: veteran.file_number,
           receipt_date: receipt_date,
           docket_type: Constants.AMA_DOCKETS.evidence_submission,
           veteran_is_not_claimant: false,
           legacy_opt_in_approved: legacy_opt_in_approved).tap(&:create_tasks_on_intake_success!)
  end

  let!(:appeal2) do
    create(:appeal,
           veteran_file_number: veteran.file_number,
           receipt_date: receipt_date,
           docket_type: Constants.AMA_DOCKETS.evidence_submission,
           veteran_is_not_claimant: false,
           legacy_opt_in_approved: legacy_opt_in_approved).tap(&:create_tasks_on_intake_success!)
  end

  let!(:appeal_intake) do
    create(:intake, user: current_user, detail: appeal, veteran_file_number: veteran.file_number)
  end

  let(:nonrating_request_issue_attributes) do
    {
      decision_review: appeal,
      nonrating_issue_category: "Military Retired Pay",
      nonrating_issue_description: "nonrating description",
      contention_reference_id: "1234",
      decision_date: 1.month.ago
    }
  end

  let!(:nonrating_request_issue) { create(:request_issue, nonrating_request_issue_attributes) }

  let(:rating_request_issue_attributes) do
    {
      decision_review: appeal,
      contested_rating_issue_reference_id: "def456",
      contested_rating_issue_profile_date: profile_date,
      contested_issue_description: "PTSD denied",
      contention_reference_id: "4567"
    }
  end

  let!(:rating_request_issue) { create(:request_issue, rating_request_issue_attributes) }

  scenario "allows adding/removing issues" do
    visit "appeals/#{appeal.uuid}/edit/"

    expect(page).to have_content(nonrating_request_issue.description)

    # remove an issue
    click_remove_intake_issue_dropdown(nonrating_request_issue.description)
    expect(page.has_no_content?(nonrating_request_issue.description)).to eq(true)
    expect(page).to have_content("When you finish making changes, click \"Save\" to continue")

    # add a different issue
    click_intake_add_issue
    add_intake_rating_issue("Left knee granted")
    # save flash should still occur because issues are different
    expect(page).to have_content("When you finish making changes, click \"Save\" to continue")

    # save
    expect(page).to have_content("Left knee granted")
    safe_click("#button-submit-update")

    # should redirect to queue
    expect(page).to have_current_path("/queue/appeals/#{appeal.uuid}")

    # going back to edit page should show those issues
    visit "appeals/#{appeal.uuid}/edit/"
    expect(page).to have_content("Left knee granted")
    expect(page.has_no_content?("nonrating description")).to eq(true)

    # canceling should redirect to queue
    click_on "Cancel"
    expect(page).to have_current_path("/queue/appeals/#{appeal.uuid}")
  end

  scenario "allows removing and re-adding same issue" do
    issue_description = rating_request_issue.description

    visit "appeals/#{appeal.uuid}/edit/"

    expect(page).to have_content(issue_description)
    expect(page).to have_button("Save", disabled: true)
    # remove
    click_remove_intake_issue_dropdown(issue_description)
    expect(page.has_no_content?(issue_description)).to eq(true)
    expect(page).to have_content("When you finish making changes, click \"Save\" to continue")

    # re-add
    click_intake_add_issue
    add_intake_rating_issue(issue_description, "a new comment")
    expect(page).to have_content(issue_description)
    expect(page).to_not have_content(
      Constants.INELIGIBLE_REQUEST_ISSUES.duplicate_of_rating_issue_in_active_review.gsub("{review_title}", "Appeal")
    )
    expect(page).to have_content("When you finish making changes, click \"Save\" to continue")

    # issue note was added
    expect(page).to have_button("Save", disabled: false)
  end

  scenario "when selecting a new benefit type the issue category dropdown should return to a default state" do
    new_vet = create(:veteran, first_name: "Ed", last_name: "Merica")
    new_appeal = create(:appeal,
                        veteran_file_number: new_vet.file_number,
                        receipt_date: receipt_date,
                        docket_type: Constants.AMA_DOCKETS.evidence_submission,
                        veteran_is_not_claimant: false,
                        legacy_opt_in_approved: legacy_opt_in_approved).tap(&:create_tasks_on_intake_success!)

    visit "appeals/#{new_appeal.uuid}/edit/"

    click_intake_add_issue

    dropdown_select_string = "Select or enter..."
    benefit_text = "Compensation"

    # Select the first benefit type
    all(".cf-select__control", text: dropdown_select_string).first.click
    find("div", class: "cf-select__option", text: benefit_text).click

    # Select the first issue category
    find(".cf-select__control", text: dropdown_select_string).click
    find("div", class: "cf-select__option", text: "Unknown Issue Category").click

    # Verify that the default dropdown text is missing from the page
    expect(page).to_not have_content(dropdown_select_string)

    # Select a different benefit type
    find(".cf-select__control", text: benefit_text).click
    find("div", class: "cf-select__option", text: "Education").click

    # Verify that the default dropdown text once again present on the page
    expect(page).to have_content(dropdown_select_string)
  end

  context "with remove decision review enabled" do
    scenario "allows all request issues to be removed and saved" do
      visit "appeals/#{appeal.uuid}/edit/"
      # remove all issues
      click_remove_intake_issue_dropdown("PTSD denied")
      click_remove_intake_issue_dropdown("Military Retired Pay")
      expect(page).to have_button("Save", disabled: false)
    end
  end

  context "ratings with disabiliity codes" do
    let(:disabiliity_receive_date) { receipt_date - 1.day }
    let(:disability_profile_date) { receipt_date - 10.days }
    let!(:ratings_with_diagnostic_codes) do
      generate_ratings_with_disabilities(
        veteran,
        disabiliity_receive_date,
        disability_profile_date
      )
    end

    scenario "saves diagnostic codes" do
      visit "appeals/#{appeal.uuid}/edit/"
      save_and_check_request_issues_with_diagnostic_codes(
        Constants.INTAKE_FORM_NAMES.appeal,
        appeal
      )
    end
  end

  context "with multiple request issues with same data fields" do
    let!(:duplicate_nonrating_request_issue) do
      create(:request_issue, nonrating_request_issue_attributes.merge(contention_reference_id: "4444"))
    end
    let!(:duplicate_rating_request_issue) do
      create(:request_issue, rating_request_issue_attributes.merge(contention_reference_id: "5555"))
    end

    scenario "saves by id" do
      visit "appeals/#{appeal.uuid}/edit/"
      expect(page).to have_content(duplicate_nonrating_request_issue.description, count: 2)
      expect(page).to have_content(duplicate_rating_request_issue.description, count: 2)

      # add another new issue
      click_intake_add_issue
      click_intake_no_matching_issues
      add_intake_nonrating_issue(
        category: "Active Duty Adjustments",
        description: "A description!",
        date: profile_date.mdY
      )
      click_edit_submit_and_confirm

      expect(page).to have_current_path("/queue/appeals/#{appeal.uuid}")

      request_issue_update = RequestIssuesUpdate.where(review: appeal).last
      non_modified_ids = [duplicate_nonrating_request_issue.id, duplicate_rating_request_issue.id,
                          nonrating_request_issue.id, rating_request_issue.id]

      # duplicate issues should be neither added nor removed
      expect(request_issue_update.added_issues.map(&:id)).to_not include(non_modified_ids)
      expect(request_issue_update.removed_issues.map(&:id)).to_not include(non_modified_ids)
    end
  end

  context "with legacy appeals" do
    before do
      setup_legacy_opt_in_appeals(veteran.file_number)
    end

    context "with legacy_opt_in_approved" do
      let(:legacy_opt_in_approved) { true }

      scenario "adding issues" do
        visit "appeals/#{appeal.uuid}/edit/"

        click_intake_add_issue
        expect(page).to have_content("Next")
        add_intake_rating_issue("Left knee granted")

        # expect legacy opt in modal
        expect(page).to have_content("Does issue 3 match any of these VACOLS issues?")

        add_intake_rating_issue("intervertebral disc syndrome") # ineligible issue

        expect(page).to have_content(
          "Left knee granted #{Constants.INELIGIBLE_REQUEST_ISSUES.legacy_appeal_not_eligible}"
        )

        click_intake_add_issue
        add_intake_rating_issue("Back pain")
        add_intake_rating_issue("ankylosis of hip") # eligible issue
        click_edit_submit_and_confirm

        expect(page).to have_current_path("/queue/appeals/#{appeal.uuid}")

        ineligible_ri = RequestIssue.find_by(
          contested_issue_description: "Left knee granted",
          ineligible_reason: :legacy_appeal_not_eligible,
          vacols_id: "vacols2",
          vacols_sequence_id: "1"
        )
        expect(ineligible_ri).to_not be_nil
        expect(ineligible_ri.closed_status).to eq("ineligible")

        ri_with_optin = RequestIssue.find_by(
          contested_issue_description: "Back pain",
          ineligible_reason: nil,
          vacols_id: "vacols1",
          vacols_sequence_id: "1"
        )

        expect(ri_with_optin).to_not be_nil
        li_optin = ri_with_optin.legacy_issue_optin
        expect(li_optin.optin_processed_at).to_not be_nil
        expect(VACOLS::CaseIssue.find_by(isskey: "vacols1", issseq: 1).issdc).to eq(
          LegacyIssueOptin::VACOLS_DISPOSITION_CODE
        )

        # Check rollback
        visit "appeals/#{appeal.uuid}/edit/"
        click_remove_intake_issue_dropdown("Back pain")

        # Let's verify ineligible issue properly changes removed status
        click_remove_intake_issue_dropdown("Left knee granted")

        click_edit_submit_and_confirm

        expect(page).to have_current_path("/queue/appeals/#{appeal.uuid}")
        expect(li_optin.reload.rollback_processed_at).to_not be_nil
        expect(VACOLS::CaseIssue.find_by(isskey: "vacols1", issseq: 1).issdc).to eq(
          li_optin.original_disposition_code
        )

        expect(ineligible_ri.reload.closed_status).to eq("removed")
      end
    end

    context "with legacy opt in not approved" do
      let(:legacy_opt_in_approved) { false }
      scenario "adding issues" do
        visit "appeals/#{appeal.uuid}/edit/"
        click_intake_add_issue
        add_intake_rating_issue("Left knee granted")

        expect(page).to have_content("Does issue 3 match any of these VACOLS issues?")
        # do not show inactive appeals when legacy opt in is false
        expect(page).to_not have_content("impairment of hip")
        expect(page).to_not have_content("typhoid arthritis")

        add_intake_rating_issue("ankylosis of hip")

        expect(page).to have_content(
          "Left knee granted #{Constants.INELIGIBLE_REQUEST_ISSUES.legacy_issue_not_withdrawn}"
        )

        safe_click("#button-submit-update")
        safe_click ".confirm"

        expect(page).to have_current_path("/queue/appeals/#{appeal.uuid}")

        expect(RequestIssue.find_by(
                 contested_issue_description: "Left knee granted",
                 ineligible_reason: :legacy_issue_not_withdrawn,
                 vacols_id: "vacols1",
                 vacols_sequence_id: "1"
               )).to_not be_nil
      end
    end
  end

  def add_contested_claim_issue
    click_intake_add_issue
    click_intake_no_matching_issues

    # add the cc issue
    dropdown_select_string = "Select or enter..."
    benefit_text = "Insurance"

    # Select the benefit type
    all(".cf-select__control", text: dropdown_select_string).first.click
    find("div", class: "cf-select__option", text: benefit_text).click

    # Select the issue category
    find(".cf-select__control", text: dropdown_select_string).click
    find("div", class: "cf-select__option", text: "Contested Death Claim | Intent of Insured").click

    # fill in date and issue description
    fill_in "Decision date", with: 1.day.ago.to_date.mdY.to_s
    fill_in "Issue description", with: "CC Instructions"

    # click buttons
    click_on "Add this issue"
    click_on "Save"
    click_on "Yes, save"
  end

  context "A contested claim is added to an evidence submission appeal" do
    let!(:cc_appeal) do
      create(:appeal,
             veteran_file_number: veteran.file_number,
             receipt_date: receipt_date,
             docket_type: Constants.AMA_DOCKETS.evidence_submission,
             veteran_is_not_claimant: false,
             legacy_opt_in_approved: legacy_opt_in_approved).tap(&:create_tasks_on_intake_success!)
    end

    before do
      User.authenticate!(user: current_user)
      FeatureToggle.enable!(:cc_appeal_workflow)
      FeatureToggle.enable!(:indicator_for_contested_claims)
      FeatureToggle.enable!(:indicator_for_contested_claims)
      ClerkOfTheBoard.singleton
    end

    scenario "the cc_appeal_workflow feature toggle is not enabled" do
      FeatureToggle.disable!(:cc_appeal_workflow)
      visit("/appeals/#{cc_appeal.uuid}/edit")
      add_contested_claim_issue

      assert page.has_content?("You have successfully added 1 issue")
      expect(cc_appeal.reload.tasks.find_by(type: "SendInitialNotificationLetterTask").nil?).to be true
    end

    scenario "a cc issue is assigned to an evidence submission appeal" do
      visit("/appeals/#{cc_appeal.uuid}/edit")
      add_contested_claim_issue

      assert page.has_content?("You have successfully added 1 issue")
      expect(cc_appeal.reload.tasks.find_by(type: "SendInitialNotificationLetterTask").nil?).to be false
      expect(
        cc_appeal.reload.tasks.find_by(type: "SendInitialNotificationLetterTask").parent
      ).to eql(cc_appeal.tasks.find_by(type: "EvidenceSubmissionWindowTask"))
      expect(
        cc_appeal.reload.tasks.find_by(type: "SendInitialNotificationLetterTask").assigned_to
      ).to eql(ClerkOfTheBoard.singleton)
      expect(
        cc_appeal.reload.tasks.find_by(type: "SendInitialNotificationLetterTask").assigned_by
      ).to eql(current_user)
    end
  end

  context "A contested claim is added to an hearing appeal" do
    let!(:cc_appeal) do
      create(:appeal,
             veteran_file_number: veteran.file_number,
             receipt_date: receipt_date,
             docket_type: Constants.AMA_DOCKETS.hearing,
             veteran_is_not_claimant: false,
             legacy_opt_in_approved: legacy_opt_in_approved).tap(&:create_tasks_on_intake_success!)
    end

    before do
      User.authenticate!(user: current_user)
      FeatureToggle.enable!(:cc_appeal_workflow)
      FeatureToggle.enable!(:indicator_for_contested_claims)
      FeatureToggle.enable!(:indicator_for_contested_claims)
      ClerkOfTheBoard.singleton
    end

    scenario "a cc issue is assigned to a hearing appeal" do
      visit("/appeals/#{cc_appeal.uuid}/edit")
      add_contested_claim_issue

      assert page.has_content?("You have successfully added 1 issue")
      expect(cc_appeal.reload.tasks.find_by(type: "SendInitialNotificationLetterTask").nil?).to be false
      expect(
        cc_appeal.reload.tasks.find_by(type: "SendInitialNotificationLetterTask").parent
      ).to eql(cc_appeal.tasks.find_by(type: "ScheduleHearingTask"))
      expect(
        cc_appeal.reload.tasks.find_by(type: "SendInitialNotificationLetterTask").assigned_to
      ).to eql(ClerkOfTheBoard.singleton)
      expect(
        cc_appeal.reload.tasks.find_by(type: "SendInitialNotificationLetterTask").assigned_by
      ).to eql(current_user)
    end
  end

  context "A contested claim is added to a direct review appeal" do
    let!(:cc_appeal) do
      create(:appeal,
             veteran_file_number: veteran.file_number,
             receipt_date: receipt_date,
             docket_type: Constants.AMA_DOCKETS.direct_review,
             veteran_is_not_claimant: false,
             legacy_opt_in_approved: legacy_opt_in_approved).tap(&:create_tasks_on_intake_success!)
    end

    before do
      User.authenticate!(user: current_user)
      FeatureToggle.enable!(:cc_appeal_workflow)
      FeatureToggle.enable!(:indicator_for_contested_claims)
      FeatureToggle.enable!(:indicator_for_contested_claims)
      ClerkOfTheBoard.singleton
    end

    scenario "a cc issue is assigned to a direct review appeal" do
      visit("/appeals/#{cc_appeal.uuid}/edit")
      add_contested_claim_issue

      assert page.has_content?("You have successfully added 1 issue")
      expect(cc_appeal.reload.tasks.find_by(type: "SendInitialNotificationLetterTask").nil?).to be false
      expect(
        cc_appeal.reload.tasks.find_by(type: "SendInitialNotificationLetterTask").parent
      ).to eql(cc_appeal.tasks.find_by(type: "DistributionTask"))
      expect(
        cc_appeal.reload.tasks.find_by(type: "SendInitialNotificationLetterTask").assigned_to
      ).to eql(ClerkOfTheBoard.singleton)
      expect(
        cc_appeal.reload.tasks.find_by(type: "SendInitialNotificationLetterTask").assigned_by
      ).to eql(current_user)
    end
  end

  context "A cc issue is added to a cc appeal with the initial letter task" do
    let!(:cc_appeal) do
      create(:appeal,
             veteran_file_number: veteran.file_number,
             receipt_date: receipt_date,
             docket_type: Constants.AMA_DOCKETS.direct_review,
             veteran_is_not_claimant: false,
             legacy_opt_in_approved: legacy_opt_in_approved).tap(&:create_tasks_on_intake_success!)
    end

    let(:initial_letter_task) do
      SendInitialNotificationLetterTask.create!(
        appeal: cc_appeal,
        parent: appeal.tasks.find_by(type: "DistributionTask"),
        assigned_to: ClerkOfTheBoard.singleton,
        assigned_by: current_user
      )
    end

    before do
      User.authenticate!(user: current_user)
      FeatureToggle.enable!(:cc_appeal_workflow)
      FeatureToggle.enable!(:indicator_for_contested_claims)
      FeatureToggle.enable!(:indicator_for_contested_claims)
      ClerkOfTheBoard.singleton
    end

    scenario "if the first task is open, a 2nd SendInitialNotificationLetterTask is not created" do
      visit("/appeals/#{cc_appeal.uuid}/edit")
      add_contested_claim_issue

      assert page.has_content?("You have successfully added 1 issue")
      expect(cc_appeal.reload.tasks.where(type: "SendInitialNotificationLetterTask").count).to eq 1
      # expect(cc_appeal.reload.tasks.find_by(type: "SendInitialNotificationLetterTask")).to be initial_letter_task
    end

    scenario "if the first task is completed, a new SendInitialNotificationLetterTask is created" do
      initial_letter_task.completed!

      visit("/appeals/#{cc_appeal.uuid}/edit")
      add_contested_claim_issue

      assert page.has_content?("You have successfully added 1 issue")
      expect(cc_appeal.reload.tasks.where(type: "SendInitialNotificationLetterTask").count).to eq 2
      expect(cc_appeal.reload.tasks.where(
        type: "SendInitialNotificationLetterTask"
      ).where(status: "assigned").count).to eq 1
    end

    scenario "if the first task is cancelled, a new SendInitialNotificationLetterTask is created" do
      initial_letter_task.cancelled!

      visit("/appeals/#{cc_appeal.uuid}/edit")
      add_contested_claim_issue

      assert page.has_content?("You have successfully added 1 issue")
      expect(cc_appeal.reload.tasks.where(type: "SendInitialNotificationLetterTask").count).to eq 2
      expect(cc_appeal.reload.tasks.where(
        type: "SendInitialNotificationLetterTask"
      ).where(status: "assigned").count).to eq 1
    end
  end

  context "User is a member of the Supervisory Senior Council" do
    let!(:organization) { SupervisorySeniorCouncil.singleton }
    let!(:current_user) { create(:user, roles: ["Mail Intake"]) }
    let!(:organization_user) { OrganizationsUser.make_user_admin(current_user, organization) }
    scenario "less than 2 request issues on the appeal, the split appeal button doesn't show" do
      User.authenticate!(user: current_user)
      visit "appeals/#{appeal2.uuid}/edit/"
      expect(appeal2.decision_issues.length + appeal2.request_issues.length).to be < 2
      expect(page).to_not have_button("Split appeal")
    end
  end

  context "The user is a member of Supervisory Senior Council and the appeal has 2 or more tasks" do
    let!(:organization) { SupervisorySeniorCouncil.singleton }
    let!(:current_user) { create(:user, roles: ["Mail Intake"]) }
    let!(:organization_user) { OrganizationsUser.make_user_admin(current_user, organization) }
    let(:request_issue_1) do
      create(:request_issue,
             id: 22,
             decision_review: appeal2,
             decision_date: profile_date,
             contested_rating_issue_reference_id: "def456",
             contested_rating_issue_profile_date: profile_date,
             contested_issue_description: "PTSD denied",
             contention_reference_id: "3897",
             benefit_type: "Education")
    end

    let(:request_issue_2) do
      create(:request_issue,
             id: 25,
             decision_review: appeal2,
             decision_date: profile_date,
             contested_rating_issue_reference_id: "blah1234",
             contested_rating_issue_profile_date: profile_date,
             contested_issue_description: "Other Issue Description",
             contention_reference_id: "78910",
             benefit_type: "Education")
    end

    scenario "the split appeal button shows and leads to create_split page" do
      # add issues to the appeal
      appeal2.request_issues << request_issue_1
      appeal2.request_issues << request_issue_2

      User.authenticate!(user: current_user)
      FeatureToggle.enable!(:split_appeal_workflow)
      visit "appeals/#{appeal2.uuid}/edit/"

      expect(page).to have_button("Split appeal")
      # clicking the button takes the user to the next page
      click_button("Split appeal")

      expect(page).to have_current_path("/appeals/#{appeal2.uuid}/edit/create_split")

      FeatureToggle.disable!(:split_appeal_workflow)
    end

    scenario "The SSC user navigates to the split appeal page" do
      # add issues to the appeal
      appeal2.request_issues << request_issue_1
      appeal2.request_issues << request_issue_2

      User.authenticate!(user: current_user)
      visit("/appeals/#{appeal2.uuid}/edit/create_split")
      # expect issue descritions to display
      expect(page).to have_content("PTSD denied")
      expect(page).to have_content("Other Issue Description")
      # expect the select bar, cancel button, and continue button to show
      expect(page).to have_content("Select...")
      expect(page).to have_content("Cancel")
      # expect the continue button to be disabled
      expect(page).to have_button("Continue", disabled: true)
    end

    scenario "The cancel button goes back to the edit page when clicked" do
      # add issues to the appeal
      appeal2.request_issues << request_issue_1
      appeal2.request_issues << request_issue_2

      User.authenticate!(user: current_user)
      visit("/appeals/#{appeal2.uuid}/edit/create_split")

      # click the cancel link and go to queue page
      click_button("Cancel")
      expect(page).to have_current_path("/queue/appeals/#{appeal2.uuid}")
    end

    scenario "If no issues are selected on the split appeal page, the Continue button is disabled" do
      User.authenticate!(user: current_user)
      visit("/appeals/#{appeal.uuid}/edit/create_split")

      # expect issue descritions to display
      expect(page).to have_content("PTSD denied")
      expect(page).to have_content("Military Retired Pay - nonrating description")
      find("label", text: "PTSD denied").click
      expect(page).to have_content("Select...")
      expect(page).to have_button("Continue", disabled: true)
    end

    scenario "If no issues are selected after de-selecting an issue, the Continue button is disabled" do
      User.authenticate!(user: current_user)
      visit("/appeals/#{appeal.uuid}/edit/create_split")

      # expect issue descritions to display
      expect(page).to have_content("PTSD denied")
      expect(page).to have_content("Military Retired Pay - nonrating description")
      find("label", text: "PTSD denied").click
      find("label", text: "PTSD denied").click
      expect(page).to have_content("Select...")
      expect(page).to have_button("Continue", disabled: true)
    end

    scenario "If all issues are selected on the split appeal page, the Continue button is disabled" do
      User.authenticate!(user: current_user)
      visit("/appeals/#{appeal.uuid}/edit/create_split")

      # expect issue descritions to display
      expect(page).to have_content("PTSD denied")
      expect(page).to have_content("Military Retired Pay - nonrating description")
      # click checkboxes
      find("label", text: "PTSD denied").click
      find("label", text: "Military Retired Pay - nonrating description").click
      expect(page).to have_content("Select...")
      find(:css, ".cf-select").select_option
      find(:css, ".cf-select__menu").click
      expect(page).to have_button("Continue", disabled: true)
    end

    def skill_form(appeal)
      # add issues to the appeal
      appeal.request_issues << request_issue_1
      appeal.request_issues << request_issue_2

      User.authenticate!(user: current_user)
      visit("/appeals/#{appeal.uuid}/edit/create_split")

      # expect issue descritions to display
      expect(page).to have_content("PTSD denied")
      expect(page).to have_content("Other Issue Description")
      find("label", text: "PTSD denied").click
      expect(page).to have_content("Select...")

      find(:css, ".cf-select").select_option
      find(:css, ".cf-select__menu").click

      click_button("Continue")
      expect(page).to have_current_path("/appeals/#{appeal2.uuid}/edit/review_split")
    end

    def wait_for_ajax
      max_time = Capybara::Helpers.monotonic_time + Capybara.default_max_wait_time
      while Capybara::Helpers.monotonic_time < max_time
        finished = finished_all_ajax_requests?
        if finished
          break
        else
          sleep 0.1
        end
      end
      raise "wait_for_ajax timeout" unless finished
    end

    def finished_all_ajax_requests?
      page.evaluate_script(<<~EOS
        ((typeof window.jQuery === 'undefined')
        || (typeof window.jQuery.active === 'undefined')
        || (window.jQuery.active === 0))
        && ((typeof window.injectedJQueryFromNode === 'undefined')
        || (typeof window.injectedJQueryFromNode.active === 'undefined')
        || (window.injectedJQueryFromNode.active === 0))
        && ((typeof window.httpClients === 'undefined')
        || (window.httpClients.every(function (client) { return (client.activeRequestCount === 0); })))
      EOS
                          )
    end

    scenario "The SSC user navigates to the split appeal page to review page" do
      skill_form(appeal2)
    end

    scenario "When the user accesses the review_split page, the page renders as expected" do
      # add issues to the appeal
      skill_form(appeal2)

      expect(page).to have_table("review_table")
      expect(page).to have_content("Cancel")
      expect(page).to have_button("Back")
      expect(page).to have_button("Split appeal")
      expect(page).to have_content("Reason for new appeal stream:")
    end

    scenario "on the review_split page, the back button takes the user back" do
      skill_form(appeal2)

      click_button("Back")
      expect(page).to have_current_path("/appeals/#{appeal2.uuid}/edit/create_split")
    end

    scenario "on the review_split page, the cancel button takes the user to queue" do
      skill_form(appeal2)

      click_button("Cancel")
      expect(page).to have_current_path("/queue/appeals/#{appeal2.uuid}")
    end

    scenario "on the review_split page, testing appellant and vetera" do
      skill_form(appeal2)
      if expect(appeal2.veteran_is_not_claimant).to be(false)
        row2_1 = page.find(:xpath, ".//table/tr[2]/td[1]/em").text
        row3_1 = page.find(:xpath, ".//table/tr[3]/td[1]/em").text
        expect(row2_1).to eq("Veteran")
        expect(row3_1).to eq("Docket Number")
      else
        row2_1 = page.find(:xpath, ".//table/tr[2]/td[1]/em").text
        row3_1 = page.find(:xpath, ".//table/tr[3]/td[1]/em").text
        expect(row2_1).to eq("Veteran")
        expect(row3_1).to eq("Appellant")
      end
    end

    scenario "on the review_split page, appeal type is no hearing" do
      skill_form(appeal2)
      expect(appeal2.docket_type).not_to have_content("hearing")
    end

    scenario "on the review_split page, the Split appeal button takes the user to queue" do
      skill_form(appeal2)

      click_button("Split appeal")
      # wait_for_ajax
      # page.find(:xpath, '/queue/appeals/#{appeal2.uuid}')
      # assert_current_path("/queue/appeals/#{appeal2.uuid}")
      expect(page).to have_current_path("/queue/appeals/#{appeal2.uuid}", ignore_query: true)
    end
  end

  context "Veteran is invalid" do
    let!(:veteran) do
      create(:veteran,
             first_name: "Ed",
             last_name: "Merica",
             ssn: nil,
             bgs_veteran_record: {
               sex: nil,
               ssn: nil,
               country: nil,
               address_line1: "this address is more than 20 chars"
             })
    end

    let!(:rating_request_issue) { nil }
    let!(:nonrating_request_issue) { nil }

    scenario "adding an issue with a vbms benefit type" do
      visit "appeals/#{appeal.uuid}/edit/"

      # Add issue that is not a VBMS issue
      click_intake_add_issue
      click_intake_no_matching_issues
      add_intake_nonrating_issue(
        benefit_type: "Education",
        category: "Accrued",
        description: "Description for Accrued",
        date: 1.day.ago.to_date.mdY
      )
      expect(page).to_not have_content("Check the Veteran's profile for invalid information")
      expect(page).to have_button("Save", disabled: false)

      # Add a rating issue
      click_intake_add_issue
      add_intake_rating_issue("Left knee granted")
      expect(page).to have_content("Check the Veteran's profile for invalid information")
      expect(page).to have_content("Please fill in the following fields in the Veteran's profile in VBMS or")
      expect(page).to have_content(
        "the corporate database, then retry establishing the EP in Caseflow: country"
      )
      expect(page).to have_content("This Veteran's address is too long. Please edit it in VBMS or SHARE")
      expect(page).to have_button("Save", disabled: true)
      click_remove_intake_issue_dropdown("Left knee granted")
      expect(page).to_not have_content("Check the Veteran's profile for invalid information")
      expect(page).to have_button("Save", disabled: false)

      # Add a compensation nonrating issue
      click_intake_add_issue
      click_intake_no_matching_issues
      add_intake_nonrating_issue(
        benefit_type: "Compensation",
        category: "Apportionment",
        description: "Description for Apportionment",
        date: 2.days.ago.to_date.mdY
      )
      expect(page).to have_content("Check the Veteran's profile for invalid information")
      expect(page).to have_button("Save", disabled: true)
    end
  end

  context "when appeal Type is Veterans Health Administration By default (Predocket option)" do
    scenario "appeal with benefit type VHA" do
      visit "appeals/#{appeal.uuid}/edit/"
      click_intake_add_issue
      click_intake_no_matching_issues
      fill_in "Benefit type", with: "Veterans Health Administration"
      find("#issue-benefit-type").send_keys :enter
      fill_in "Issue category", with: "Beneficiary Travel"
      find("#issue-category").send_keys :enter
      fill_in "Issue description", with: "I am a VHA issue"
      fill_in "Decision date", with: 1.month.ago.mdY
      radio_choices = page.all(".cf-form-radio-option > label")
      expect(radio_choices[0]).to have_content("Yes")
      expect(radio_choices[1]).to have_content("No")
      expect(find("#is-predocket-needed_true", visible: false).checked?).to eq(true)
      expect(find("#is-predocket-needed_false", visible: false).checked?).to eq(false)
      expect(page).to have_content(COPY::VHA_PRE_DOCKET_ISSUE_BANNER)
    end
  end

  context "when appeal Type is Veterans Health Administration NO Predocket" do
    scenario "appeal with benefit type VHA no - predocket" do
      visit "appeals/#{appeal.uuid}/edit/"
      click_intake_add_issue
      click_intake_no_matching_issues
      fill_in "Benefit type", with: "Veterans Health Administration"
      find("#issue-benefit-type").send_keys :enter
      fill_in "Issue category", with: "Beneficiary Travel"
      find("#issue-category").send_keys :enter
      fill_in "Issue description", with: "I am a VHA issue"
      fill_in "Decision date", with: 1.month.ago.mdY
      radio_choices = page.all(".cf-form-radio-option > label")
      expect(radio_choices[0]).to have_content("Yes")
      expect(radio_choices[1]).to have_content("No")

      radio_choices[1].click
      expect(find("#is-predocket-needed_true", visible: false).checked?).to eq(false)
      expect(find("#is-predocket-needed_false", visible: false).checked?).to eq(true)
      expect(page).to have_no_content(COPY::VHA_PRE_DOCKET_ISSUE_BANNER)
    end
  end

  context "appeal is non-comp benefit type" do
    let!(:request_issue) { create(:request_issue, benefit_type: "education") }

    scenario "adding an issue with a non-comp benefit type" do
      visit "appeals/#{appeal.uuid}/edit/"

      # Add issue that is not a VBMS issue
      click_intake_add_issue
      click_intake_no_matching_issues
      add_intake_nonrating_issue(
        benefit_type: "Education",
        category: "Accrued",
        description: "Description for Accrued",
        date: 1.day.ago.to_date.mdY
      )

      expect(page).to_not have_content("Check the Veteran's profile for invalid information")
      expect(page).to have_button("Save", disabled: false)

      click_edit_submit_and_confirm
      expect(page).to have_current_path("/queue/appeals/#{appeal.uuid}")
      expect(page).to_not have_content("Unable to load this case")
      expect(RequestIssue.find_by(
               benefit_type: "education",
               veteran_participant_id: nil
             )).to_not be_nil
    end
  end

  context "appeal is outcoded" do
    let(:appeal) { create(:appeal, :outcoded, veteran: veteran) }

    scenario "error message is shown and no edit is allowed" do
      visit "appeals/#{appeal.uuid}/edit/"

      expect(page).to have_current_path("/appeals/#{appeal.uuid}/edit/outcoded")
      expect(page).to have_content("Issues Not Editable")
      expect(page).to have_content("This appeal has been outcoded and the issues are no longer editable.")
    end
  end

  context "when withdraw decision reviews is enabled" do
    scenario "remove an issue with dropdown and show alert message" do
      visit "appeals/#{appeal.uuid}/edit/"
      expect(page).to have_content("PTSD denied")
      click_remove_intake_issue_dropdown("PTSD denied")

      expect(page).to_not have_content("PTSD denied")

      click_edit_submit_and_confirm

      expect(page).to have_current_path("/queue/appeals/#{appeal.uuid}")

      expect(page).to have_content("You have successfully removed 1 issue.")
    end

    let(:withdraw_date) { 1.day.ago.to_date.mdY }

    let!(:in_progress_task) do
      create(:appeal_task,
             :in_progress,
             appeal: appeal,
             assigned_to: non_comp_org,
             assigned_at: last_week)
    end

    scenario "withdraw entire review and show alert" do
      visit "appeals/#{appeal.uuid}/edit/"

      click_withdraw_intake_issue_dropdown("PTSD denied")
      fill_in "withdraw-date", with: withdraw_date

      expect(page).to_not have_content("This review will be withdrawn.")
      expect(page).to have_button("Save", disabled: false)

      click_withdraw_intake_issue_dropdown("Military Retired Pay - nonrating description")

      expect(page).to have_content("This review will be withdrawn.")
      expect(page).to have_button("Withdraw", disabled: false)

      click_edit_submit

      expect(page).to have_current_path("/queue/appeals/#{appeal.uuid}")

      expect(page).to have_content("You have successfully withdrawn a review.")

      expect(in_progress_task.reload.status).to eq(Constants.TASK_STATUSES.cancelled)
    end

    scenario "withdraw an issue" do
      visit "appeals/#{appeal.uuid}/edit/"

      expect(page).to_not have_content("Withdrawn issues")
      expect(page).to_not have_content("Please include the date the withdrawal was requested")

      click_withdraw_intake_issue_dropdown("PTSD denied")

      expect(page).to have_content(
        /Withdrawn issues\n[1-2]..PTSD denied\nDecision date: #{request_issue_decision_mdY}\nWithdrawal pending/i
      )
      expect(page).to have_content("Please include the date the withdrawal was requested")

      expect(page).to have_button("Save", disabled: true)

      fill_in "withdraw-date", with: withdraw_date

      safe_click("#button-submit-update")
      expect(page).to have_current_path("/queue/appeals/#{appeal.uuid}")

      withdrawn_issue = RequestIssue.where(closed_status: "withdrawn").first

      expect(withdrawn_issue).to_not be_nil
      expect(withdrawn_issue.closed_at).to eq(1.day.ago.to_date.to_datetime)
      expect(page).to have_content("You have successfully withdrawn 1 issue.")
    end

    scenario "show withdrawn issue when appeal edit page is reloaded" do
      visit "appeals/#{appeal.uuid}/edit/"

      click_intake_add_issue
      add_intake_rating_issue("Left knee granted")

      expect(page).to have_button("Save", disabled: false)

      safe_click("#button-submit-update")
      expect(page).to have_content("Number of issues has changed")

      safe_click ".confirm"
      expect(page).to have_current_path("/queue/appeals/#{appeal.uuid}")

      # reload to verify that the new issues populate the form
      visit "appeals/#{appeal.uuid}/edit/"
      expect(page).to have_content("Left knee granted")

      click_withdraw_intake_issue_dropdown("PTSD denied")

      expect(page).to_not have_content(/Requested issues\s*[0-9]+\. PTSD denied/i)
      expect(page).to have_content(
        /Withdrawn issues\n[1-2]..PTSD denied\nDecision date: #{request_issue_decision_mdY}\nWithdrawal pending/i
      )
      expect(page).to have_content("Please include the date the withdrawal was requested")

      fill_in "withdraw-date", with: withdraw_date

      safe_click("#button-submit-update")
      expect(page).to have_current_path("/queue/appeals/#{appeal.uuid}")

      withdrawn_issue = RequestIssue.where(closed_status: "withdrawn").first
      expect(withdrawn_issue).to_not be_nil
      expect(withdrawn_issue.closed_at).to eq(1.day.ago.to_date.to_datetime)

      sleep 1

      # reload to verify that the new issues populate the form
      visit "appeals/#{appeal.uuid}/edit/"

      expect(page).to have_content(
        /Withdrawn issues\s*[0-9]+\. PTSD denied\s*Decision date: #{request_issue_decision_mdY}\s*Withdrawn on/i
      )
    end

    scenario "show alert when issue is added, removed and withdrawn" do
      visit "appeals/#{appeal.uuid}/edit/"
      click_intake_add_issue
      add_intake_rating_issue("Left knee granted")
      click_edit_submit_and_confirm

      expect(page).to have_current_path("/queue/appeals/#{appeal.uuid}")

      expect(page).to have_content("You have successfully added 1 issue")

      # reload to verify that the new issues populate the form
      visit "appeals/#{appeal.uuid}/edit/"

      click_intake_add_issue
      add_intake_rating_issue("Back pain")

      click_remove_intake_issue_dropdown("Military Retired Pay")

      click_withdraw_intake_issue_dropdown("PTSD denied")

      expect(page).to have_content(
        /Withdrawn issues\n[1-2]..PTSD denied\nDecision date: #{request_issue_decision_mdY}\nWithdrawal pending/i
      )
      expect(page).to have_content("Please include the date the withdrawal was requested")

      expect(page).to have_button("Save", disabled: true)

      fill_in "withdraw-date", with: withdraw_date

      click_edit_submit

      expect(page).to have_current_path("/queue/appeals/#{appeal.uuid}")

      expect(page).to have_content("You have successfully added 1 issue, removed 1 issue, and withdrawn 1 issue.")
    end

    scenario "show alert when withdrawal date is not valid" do
      visit "appeals/#{appeal.uuid}/edit/"
      click_withdraw_intake_issue_dropdown("PTSD denied")
      fill_in "withdraw-date", with: 50.days.ago.to_date.mdY

      expect(page).to have_content(
        "We cannot process your request. Please select a date after the Appeal's receipt date."
      )
      expect(page).to have_button("Save", disabled: true)

      fill_in "withdraw-date", with: 2.years.from_now.to_date.mdY

      expect(page).to have_content("We cannot process your request. Please select a date prior to today's date.")
      expect(page).to have_button("Save", disabled: true)
    end
  end

  context "when remove decision reviews is enabled" do
    let(:today) { Time.zone.now }
    let(:appeal) do
      # reload to get uuid
      create(:appeal, veteran_file_number: veteran.file_number).reload
    end
    let!(:existing_request_issues) do
      [create(:request_issue, :nonrating, decision_review: appeal),
       create(:request_issue, :nonrating, decision_review: appeal)]
    end

    let!(:completed_task) do
      create(:appeal_task,
             :completed,
             appeal: appeal,
             assigned_to: non_comp_org,
             closed_at: last_week)
    end

    let!(:cancelled_task) do
      create(:appeal_task,
             :cancelled,
             appeal: appeal,
             assigned_to: non_comp_org,
             closed_at: Time.zone.now)
    end

    context "when review has multiple active tasks" do
      let!(:in_progress_task) do
        create(:appeal_task,
               :in_progress,
               appeal: appeal,
               assigned_to: non_comp_org,
               assigned_at: last_week)
      end

      scenario "cancel all active tasks when all request issues are removed" do
        visit "appeals/#{appeal.uuid}/edit"
        # remove all request issues
        click_remove_intake_issue_dropdown("Apportionment")
        click_remove_intake_issue_dropdown("Apportionment")
        click_remove_intake_issue_dropdown("PTSD denied")
        click_remove_intake_issue_dropdown("Military Retired Pay")

        click_edit_submit_and_confirm
        expect(page).to have_current_path("/queue/appeals/#{appeal.uuid}")

        expect(RequestIssue.find_by(
                 benefit_type: "compensation",
                 veteran_participant_id: nil
               )).to_not be_nil

        visit "appeals/#{appeal.uuid}/edit"
        expect(page.has_no_content?(existing_request_issues.first.description)).to eq(true)
        expect(page.has_no_content?(existing_request_issues.second.description)).to eq(true)
        expect(completed_task.reload.status).to eq(Constants.TASK_STATUSES.completed)
        expect(in_progress_task.reload.status).to eq(Constants.TASK_STATUSES.cancelled)
      end

      context "when appeal is non-comp benefit type" do
        let!(:request_issue) { create(:request_issue, benefit_type: "education") }

        scenario "remove all non-comp decision reviews" do
          visit "appeals/#{appeal.uuid}/edit"

          # remove all request issues
          click_remove_intake_issue_dropdown("Apportionment")
          click_remove_intake_issue_dropdown("Apportionment")
          click_remove_intake_issue_dropdown("PTSD denied")
          click_remove_intake_issue_dropdown("Military Retired Pay")
          click_edit_submit_and_confirm

          expect(page).to have_current_path("/queue/appeals/#{appeal.uuid}")
          expect(page).to have_content("Edit Completed")
        end
      end

      context "when review has no active tasks" do
        scenario "no tasks are cancelled when all request issues are removed" do
          visit "appeals/#{appeal.uuid}/edit"

          click_remove_intake_issue_dropdown("Apportionment")
          click_remove_intake_issue_dropdown("Apportionment")
          click_remove_intake_issue_dropdown("PTSD denied")
          click_remove_intake_issue_dropdown("Military Retired Pay")
          click_edit_submit_and_confirm
          expect(completed_task.reload.status).to eq(Constants.TASK_STATUSES.completed)
        end
      end

      context "when appeal task is cancelled" do
        scenario "show timestamp when all request issues are cancelled" do
          visit "appeals/#{appeal.uuid}/edit"
          # remove all request issues

          click_remove_intake_issue_dropdown("Apportionment")
          click_remove_intake_issue_dropdown("Apportionment")
          click_remove_intake_issue_dropdown("PTSD denied")
          click_remove_intake_issue_dropdown("Military Retired Pay")

          click_edit_submit_and_confirm
          expect(page).to have_current_path("/queue/appeals/#{appeal.uuid}")

          visit "appeals/#{appeal.uuid}/edit"
          expect(page.has_no_content?(existing_request_issues.first.description)).to eq(true)
          expect(page.has_no_content?(existing_request_issues.second.description)).to eq(true)
          expect(cancelled_task.status).to eq(Constants.TASK_STATUSES.cancelled)
          expect(cancelled_task.closed_at).to eq(Time.zone.now)
        end
      end
    end
  end

  # We need to
  # 1. Sign in as BVA Intake Admin User
  # 2. We need a veteran file number with a legacy appeal
  # 3. The legacy appeal with 3 request issues
  context "with BVA Intake Admin user" do
    # creates organization
    let!(:bva_intake) { BvaIntake.singleton }
    # creates admin user
    let!(:bva_intake_admin_user) { create(:user, roles: ["Mail Intake"]) }
    # { Bva.singleton.add_user(authenticated_user) }

    before do
      # joins the user with the organization to grant access to role and org permissions
      OrganizationsUser.make_user_admin(bva_intake_admin_user, bva_intake)
      User.authenticate!(user: bva_intake_admin_user)
    end

    context "with Legacy MST/PACT identifications" do

      let!(:legacy_appeal) do
        create(
          :legacy_appeal,
          vacols_id: "1234567",
          vbms_id: appeal.veteran_file_number,
          vacols_case: create(
            :case,
            :assigned,
            user: bva_intake_admin_user,
            case_issues: [
              create(:case_issue, issmst: "N", isspact: "Y"),
              create(:case_issue, issmst: "Y", isspact: "N"),
              create(:case_issue, issmst: "Y", isspact: "Y")
            ]
          )
        )
      end

      before do
        FeatureToggle.enable!(:mst_identification)
        FeatureToggle.enable!(:pact_identification)
        FeatureToggle.enable!(:legacy_mst_pact_identification)
      end

      after do
        FeatureToggle.disable!(:mst_identification)
        FeatureToggle.disable!(:pact_identification)
        FeatureToggle.disable!(:legacy_mst_pact_identification)
      end

      scenario "can add MST/PACT to issues" do
        visit "/queue"
        # click_on "Search cases"
        # fill_in "search", with: appeal.veteran_file_number
        # click_on "Search"
        binding.pry
        # click_on appeal.docket_number.to_s
        click_on "Correct issues"
        # find("select", id: "issue-action-0").click
        # find("div", class: ".cf-form-dropdown", text: "Edit issue").click
        # uncheck("Military Sexual Trauma (MST)", allow_label_click: true, visible: false)
        # uncheck("PACT Act", allow_label_click: true, visible: false)
      end
    end
  end
end
