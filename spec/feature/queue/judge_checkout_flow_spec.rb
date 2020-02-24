# frozen_string_literal: true

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

    let(:root_task) { create(:root_task) }
    let(:parent_task) do
      create(
        :ama_judge_decision_review_task,
        :in_progress,
        assigned_to: judge_user,
        appeal: appeal,
        parent: root_task
      )
    end

    let(:child_task) do
      create(
        :ama_attorney_task,
        :in_progress,
        assigned_to: attorney_user,
        assigned_by: judge_user,
        parent: parent_task,
        appeal: appeal
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
    let(:document_id) { "12345-12345678" }
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
        document_id: "1234-567890",
        work_product: :draft_decision,
        created_at: created_at.to_date
      )
      allow(VACOLS::CaseAssignment).to receive(:latest_task_for_appeal).with(vacols_id).and_return(case_assignment)
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
