# frozen_string_literal: true

require "helpers/sanitized_json_configuration.rb"
require "helpers/sanitized_json_importer.rb"

RSpec.feature "Judge checkout flow", :all_dbs do
  let(:attorney_user) { create(:default_user) }
  let!(:vacols_atty) { create(:staff, :attorney_role, sdomainid: attorney_user.css_id) }

  let(:judge_user) { create(:user, station_id: User::BOARD_STATION_ID, full_name: "Aaron Judge") }
  let!(:vacols_judge) { create(:staff, vacols_role_trait, sdomainid: judge_user.css_id) }
  let(:vacols_role_trait) { :judge_role }

  before do
    # When a judge completes judge checkout we create either a QR or dispatch task. Make sure we have somebody in
    # the BVA dispatch team so that the creation of that task (which round robin assigns org tasks) does not fail.
    BvaDispatch.singleton.add_user(create(:user))
  end

  # Replicates bug in prod: https://github.com/department-of-veterans-affairs/caseflow/issues/13416
  # Scenario: judge opens the Case Details page for the same appeal in two tabs;
  #   In tab 1, judge goes through checkout and the appeal is (randomly) selected for quality review;
  #   Then in tab 2, judge goes through checkout and appeal is NOT selected for quality review
  #     and should NOT create a BvaDispatchTask because the QualityReviewTask is not complete.
  context "given an AMA appeal that is selected for quality review" do
    before do
      Organization.create!(id: 212, url: "bvajlmarch", name: "BVAJLMARCH")

      # force skipping Quality Review (to mimic tab 2)
      allow(QualityReviewCaseSelector).to receive(:select_case_for_quality_review?).and_return(false)
    end
    let!(:appeal) do
      sji = SanitizedJsonImporter.from_file("spec/records/appeal-dispatch_before_quality_review_complete.json",
                                            verbosity: 0)
      sji.import

      # Remove extraneous tasks
      Task.find(2_001_653_201).destroy
      Task.find(2_001_648_871).destroy
      Task.find(2_001_618_026).destroy

      sji.imported_records[Appeal.table_name].first.tap do |appeal|
        appeal.root_task.update(status: :on_hold)

        # Withdraw a remanded decision issue because CircleCI's Capybara fails clicking boxes for the 2nd issue
        decision_issue = appeal.reload.decision_issues.remanded.order(:id).first
        decision_issue.update(disposition: :withdrawn)
      end.reload
    end
    let(:jdr_task) { Task.find(2_001_579_253) }

    it "prevents appeal dispatch when judge performs checkout again" do
      User.authenticate!(user: User.find_by_css_id("WHITEYVACO"))

      # Change JudgeDecisionReviewTask status so that "Ready for Dispatch" action is available
      jdr_task.update(status: :assigned)
      appeal.request_issues.update_all(closed_at: nil)
      visit "queue/appeals/#{appeal.uuid}"

      # Restore JudgeDecisionReviewTask status from the first checkout
      jdr_task.update(status: :completed)
      # Note that the judge can continue and complete checkout because frontend was loaded before jdr_task was complete

      click_dropdown(text: Constants.TASK_ACTIONS.JUDGE_AMA_CHECKOUT.label)
      # Special Issues page
      expect(page).to have_content("Select special issues")
      find("label", text: "No Special Issues").click
      click_on "Continue"

      # Decision Issues page
      click_on "Continue"
      expect(page).to have_content("Issue 1")
      find("label", text: "No notice sent").click
      find("label", text: "Pre AOJ").click
      click_on "Continue"

      # Evaluate Decision page
      expect(page).to have_content("Evaluate Decision")

      find("label", text: Constants::JUDGE_CASE_REVIEW_OPTIONS["COMPLEXITY"]["easy"]).click
      text_to_click = "3 - #{Constants::JUDGE_CASE_REVIEW_OPTIONS['QUALITY']['meets_expectations']}"
      find("label", text: text_to_click).click
      find("#logically_organized", visible: false).sibling("label").click
      find("#issues_are_not_addressed", visible: false).sibling("label").click
      fill_in "additional-factors", with: generate_words(5)
      # Submit POST request
      click_on "Continue"

      expect(page).to have_content(COPY::JUDGE_CHECKOUT_DISPATCH_SUCCESS_MESSAGE_TITLE % appeal.veteran_full_name)

      # The bug was that a BvaDispatchTask is created while the QualityReviewTask is open. It should not be created.
      expect(appeal.tasks.open.of_type(:BvaDispatchTask).count).to eq 0
    end
  end

  context "given a valid ama appeal with single issue" do
    let!(:appeal) do
      create(
        :appeal,
        number_of_claimants: 1,
        request_issues: build_list(
          :request_issue, 1,
          contested_issue_description: "Tinnitus"
        )
      )
    end
    let!(:decision_issue) { create(:decision_issue, decision_review: appeal, request_issues: appeal.request_issues) }

    let(:root_task) { create(:root_task, appeal: appeal) }
    let(:parent_task) do
      create(
        :ama_judge_decision_review_task,
        :in_progress,
        assigned_to: judge_user,
        parent: root_task
      )
    end

    let(:child_task) do
      create(
        :ama_attorney_task,
        :in_progress,
        assigned_to: attorney_user,
        assigned_by: judge_user,
        parent: parent_task
      )
    end

    before do
      child_task.update!(status: Constants.TASK_STATUSES.completed)
      User.authenticate!(user: judge_user)
    end

    scenario "starts dispatch checkout flow" do
      visit "/queue"
      click_on "(#{appeal.veteran_file_number})"

      click_dropdown(text: Constants.TASK_ACTIONS.JUDGE_AMA_CHECKOUT.label)
      # Special Issues screen
      find("label", text: "No Special Issues").click
      click_on "Continue"

      # Decision Issues Screen
      click_on "Continue"
      expect(page).to have_content("Evaluate Decision")

      expect(page).to_not have_content("Select an action")
      expect(page).to_not have_content("One Touch Initiative")

      find("label", text: Constants::JUDGE_CASE_REVIEW_OPTIONS["COMPLEXITY"]["easy"]).click
      text_to_click = "1 - #{Constants::JUDGE_CASE_REVIEW_OPTIONS['QUALITY']['does_not_meet_expectations']}"
      find("label", text: text_to_click).click
      find("#logically_organized", visible: false).sibling("label").click
      find("#issues_are_not_addressed", visible: false).sibling("label").click

      dummy_note = generate_words 5
      fill_in "additional-factors", with: dummy_note
      expect(page).to have_content(dummy_note[0..5])
      click_on "Continue"

      expect(page).to have_content(COPY::JUDGE_CHECKOUT_DISPATCH_SUCCESS_MESSAGE_TITLE % appeal.veteran_full_name)

      case_review = JudgeCaseReview.find_by(task_id: parent_task.id)
      expect(case_review.attorney).to eq attorney_user
      expect(case_review.judge).to eq judge_user
      expect(case_review.complexity).to eq "easy"
      expect(case_review.quality).to eq "does_not_meet_expectations"
      expect(case_review.one_touch_initiative).to eq false
      expect(case_review.positive_feedback).to include("logically_organized")
    end

    scenario "starts dispatch checkout flow" do
      visit "/queue"
      click_on "(#{appeal.veteran_file_number})"

      click_dropdown(text: Constants.TASK_ACTIONS.JUDGE_AMA_CHECKOUT.label)

      # Special Issues page
      expect(page).to have_content("Select special issues")

      expect(page.find("label[for=no_special_issues]")).to have_content("No Special Issues")

      expect(page).to have_content("Blue Water")
      expect(page).to have_content("Burn Pit")
      expect(page).to have_content("Military Sexual Trauma (MST)")
      expect(page).to have_content("US Court of Appeals for Veterans Claims (CAVC)")
      find("label", text: "Blue Water").click
      expect(page.find("#blue_water", visible: false).checked?).to eq true
      find("label", text: "No Special Issues").click
      expect(page.find("#blue_water", visible: false).checked?).to eq false
      expect(page.find("#blue_water", visible: false).disabled?).to eq true
      find("label", text: "No Special Issues").click
      expect(page.find("#blue_water", visible: false).checked?).to eq false
      find("label", text: "Blue Water").click
      click_on "Continue"

      # Decision Issues screen
      click_on "Continue"
      expect(page).to have_content("Evaluate Decision")

      expect(page).to_not have_content("Select an action")
      expect(page).to_not have_content("One Touch Initiative")

      find("label", text: Constants::JUDGE_CASE_REVIEW_OPTIONS["COMPLEXITY"]["easy"]).click
      text_to_click = "1 - #{Constants::JUDGE_CASE_REVIEW_OPTIONS['QUALITY']['does_not_meet_expectations']}"
      find("label", text: text_to_click).click
      find("#logically_organized", visible: false).sibling("label").click
      find("#issues_are_not_addressed", visible: false).sibling("label").click

      dummy_note = generate_words 5
      fill_in "additional-factors", with: dummy_note
      expect(page).to have_content(dummy_note[0..5])
      click_on "Continue"

      expect(page).to have_content(COPY::JUDGE_CHECKOUT_DISPATCH_SUCCESS_MESSAGE_TITLE % appeal.veteran_full_name)

      case_review = JudgeCaseReview.find_by(task_id: parent_task.id)
      expect(case_review.attorney).to eq attorney_user
      expect(case_review.judge).to eq judge_user
      expect(case_review.complexity).to eq "easy"
      expect(case_review.quality).to eq "does_not_meet_expectations"
      expect(case_review.one_touch_initiative).to eq false
      expect(case_review.positive_feedback).to include("logically_organized")
    end
  end

  context "given a valid legacy appeal with single issue" do
    let!(:appeal) do
      create(
        :legacy_appeal,
        :with_veteran,
        vacols_case: create(
          :case,
          :assigned,
          user: judge_user,
          assigner: attorney_user,
          case_issues: [
            create(:case_issue, :disposition_allowed),
            create(:case_issue, :disposition_granted_by_aoj)
          ],
          work_product: work_product
        )
      )
    end

    before do
      User.authenticate!(user: judge_user)
    end

    context "where work product is draft decision" do
      let(:work_product) { :draft_decision }

      scenario "starts dispatch checkout flow" do
        visit "/queue"
        click_on "#{appeal.veteran_full_name} (#{appeal.sanitized_vbms_id})"

        click_dropdown(text: Constants.TASK_ACTIONS.JUDGE_LEGACY_CHECKOUT.label)
        click_label "vamc"
        click_on "Continue"

        # Ensure we can reload the flow and the special issue is saved
        click_on "Cancel"
        click_on "Yes, cancel"

        click_dropdown(text: Constants.TASK_ACTIONS.JUDGE_LEGACY_CHECKOUT.label)

        # Vamc should still be checked
        expect(page).to have_field("vamc", checked: true, visible: false)

        # Vamc should also be marked in the database
        expect(appeal.special_issue_list.vamc).to eq(true)
        click_on "Continue"

        # one issue is decided, excluded from checkout flow
        expect(appeal.issues.length).to eq 2

        expect(page).to have_content("Review Dispositions")
        expect(page.find_all(".issue-disposition-dropdown").length).to eq 1

        click_on "Edit Issue"
        click_on "Delete Issue"
        click_on "Delete issue"

        click_on "Continue"
        expect(page).to have_content("Evaluate Decision")

        expect(page).to_not have_content("Select an action")
        expect(page).to have_content("One Touch Initiative")
        find("label", text: COPY::JUDGE_EVALUATE_DECISION_CASE_ONE_TOUCH_INITIATIVE_SUBHEAD).click

        find("label", text: Constants::JUDGE_CASE_REVIEW_OPTIONS["COMPLEXITY"]["easy"]).click
        text_to_click = "1 - #{Constants::JUDGE_CASE_REVIEW_OPTIONS['QUALITY']['does_not_meet_expectations']}"
        find("label", text: text_to_click).click

        find("#issues_are_not_addressed", visible: false).sibling("label").click

        dummy_note = generate_words 5
        fill_in "additional-factors", with: dummy_note
        expect(page).to have_content(dummy_note[0..5])

        click_on "Continue"

        expect(page).to have_content(COPY::JUDGE_CHECKOUT_DISPATCH_SUCCESS_MESSAGE_TITLE % appeal.veteran_full_name)

        expect(VACOLS::Decass.find(appeal.vacols_id).de1touch).to eq "Y"

        page.driver.go_back
        appeal_id = LegacyAppeal.last.vacols_id

        expect(page).to have_current_path("/queue/appeals/#{appeal_id}")
      end
    end
  end

  context "when an acting judge is checking out an AMA appeal" do
    let(:vacols_role_trait) { :attorney_judge_role }

    let(:appeal) do
      create(
        :appeal,
        number_of_claimants: 1,
        request_issues: build_list(:request_issue, 1)
      )
    end
    let!(:decision_issue) do
      create(:decision_issue, :imo, decision_review: appeal, request_issues: appeal.request_issues)
    end

    let(:root_task) { create(:root_task, appeal: appeal) }
    let(:judge_review_task) do
      create(
        :ama_judge_decision_review_task,
        appeal: appeal,
        parent: root_task,
        assigned_to: judge_user
      )
    end
    let!(:attorney_task) do
      create(
        :ama_attorney_task,
        appeal: appeal,
        parent: judge_review_task,
        assigned_to: attorney_user
      )
    end

    before do
      attorney_task.update!(status: Constants.TASK_STATUSES.completed)
      User.authenticate!(user: judge_user)
    end

    it "allows the acting judge to complete judge checkout" do
      step("Navigate from case details to decision issues by way of actions dropdown") do
        visit("/queue/appeals/#{appeal.external_id}")
        click_dropdown(text: Constants.TASK_ACTIONS.JUDGE_AMA_CHECKOUT.label)
        expect(page).to have_content(COPY::DECISION_ISSUE_PAGE_TITLE)
      end

      step("Navigate to remand reasons page from decision issues page") do
        click_on("Continue")
        expect(page).to have_content("Remand Reasons")
      end

      step("Navigate to evaluation page from remand reasons page") do
        click_on("Continue")
        expect(page).to have_content(COPY::EVALUATE_DECISION_PAGE_TITLE)
      end

      step("Fill out evaluation page") do
        find("label", text: Constants.JUDGE_CASE_REVIEW_OPTIONS.COMPLEXITY.medium).click
        find("label", text: "3 - #{Constants.JUDGE_CASE_REVIEW_OPTIONS.QUALITY.meets_expectations}").click
        click_on("Continue")
      end

      step("Verify that draft decision evaluation completed successfully") do
        expect(page).to have_content(COPY::JUDGE_CHECKOUT_DISPATCH_SUCCESS_MESSAGE_TITLE % appeal.veteran_full_name)
        case_review = JudgeCaseReview.find_by(task_id: judge_review_task.id)
        expect(case_review.attorney).to eq(attorney_user)
        expect(case_review.judge).to eq(judge_user)
      end
    end
  end

  context "when an acting judge is checking out a legacy appeal" do
    let(:vacols_role_trait) { :attorney_judge_role }

    let(:created_at) { "2019-02-14" }
    let(:document_id) { "02255-00000002" }
    let(:vacols_id) { appeal.vacols_id }

    let!(:case_review) do
      create(
        :attorney_case_review,
        work_product: "Decision",
        document_id: document_id,
        task_id: "#{appeal.vacols_id}-#{created_at}"
      )
    end

    let!(:appeal) do
      create(
        :legacy_appeal,
        :with_veteran,
        vacols_case: create(
          :case,
          :assigned,
          user: judge_user,
          assigner: attorney_user,
          case_issues: [
            create(:case_issue, :disposition_allowed),
            create(:case_issue, :disposition_granted_by_aoj)
          ],
          work_product: :draft_decision
        )
      )
    end

    before do
      User.authenticate!(user: judge_user)

      case_assignment = double(
        vacols_id: vacols_id,
        assigned_by_css_id: attorney_user.css_id,
        assigned_to_css_id: judge_user.css_id,
        document_id: "02255-00000002",
        work_product: :draft_decision,
        created_at: created_at.to_date
      )
      allow(VACOLS::CaseAssignment).to receive(:latest_task_for_appeal).with(vacols_id).and_return(case_assignment)
      allow(case_assignment).to receive(:valid_document_id?).and_return(true)
    end

    scenario "starts dispatch checkout flow" do
      visit "/queue"
      click_on "#{appeal.veteran_full_name} (#{appeal.sanitized_vbms_id})"

      click_dropdown(text: Constants.TASK_ACTIONS.JUDGE_LEGACY_CHECKOUT.label)
      click_label "vamc"
      click_on "Continue"

      # Ensure we can reload the flow and the special issue is saved
      click_on "Cancel"
      click_on "Yes, cancel"

      click_dropdown(text: Constants.TASK_ACTIONS.JUDGE_LEGACY_CHECKOUT.label)

      # Vamc should still be checked
      expect(page).to have_field("vamc", checked: true, visible: false)

      # Vamc should also be marked in the database
      expect(appeal.special_issue_list.vamc).to eq(true)
      click_on "Continue"

      # one issue is decided, excluded from checkout flow
      expect(appeal.issues.length).to eq 2

      expect(page.find_all(".issue-disposition-dropdown").length).to eq 1

      click_on "Edit Issue"
      click_on "Delete Issue"
      click_on "Delete issue"

      click_on "Continue"
      expect(page).to have_content("Evaluate Decision")

      expect(page).to_not have_content("Select an action")
      expect(page).to have_content("One Touch Initiative")
      find("label", text: COPY::JUDGE_EVALUATE_DECISION_CASE_ONE_TOUCH_INITIATIVE_SUBHEAD).click

      find("label", text: Constants::JUDGE_CASE_REVIEW_OPTIONS["COMPLEXITY"]["easy"]).click
      text_to_click = "1 - #{Constants::JUDGE_CASE_REVIEW_OPTIONS['QUALITY']['does_not_meet_expectations']}"
      find("label", text: text_to_click).click

      find("#issues_are_not_addressed", visible: false).sibling("label").click

      dummy_note = generate_words 5
      fill_in "additional-factors", with: dummy_note
      expect(page).to have_content(dummy_note[0..5])

      click_on "Continue"

      expect(page).to have_content(COPY::JUDGE_CHECKOUT_DISPATCH_SUCCESS_MESSAGE_TITLE % appeal.veteran_full_name)

      expect(VACOLS::Decass.find(appeal.vacols_id).de1touch).to eq "Y"

      page.driver.go_back
      appeal_id = LegacyAppeal.last.vacols_id

      expect(page).to have_current_path("/queue/appeals/#{appeal_id}")
    end
  end
end
