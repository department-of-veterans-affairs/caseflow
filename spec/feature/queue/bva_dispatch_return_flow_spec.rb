# frozen_string_literal: true

feature "BVA Dispatch Return Flow", :all_dbs do
  let(:judge_user) { create(:user) }
  let!(:vacols_judge) { create(:staff, :judge_role, sdomainid: judge_user.css_id) }
  let(:judge_team) { JudgeTeam.create_for_judge(judge_user) }

  let(:attorney_user) { create(:user) }
  let!(:attorney_staff) { create(:staff, :attorney_role, user: attorney_user) }
  let!(:attorney_on_judge_team) { judge_team.add_user(attorney_user) }

  let!(:bva_dispatch_user) do
    user = create(:user)
    BvaDispatch.singleton.add_user(user)
    user
  end

  let(:veteran_first_name) { "Dorothy" }
  let(:veteran_last_name) { "Slezak" }
  let(:veteran_full_name) { "#{veteran_first_name} #{veteran_last_name}" }
  let!(:veteran) do
    create(:veteran, first_name: veteran_first_name, last_name: veteran_last_name, file_number: "989898989")
  end

  let!(:appeal) do
    create(
      :appeal,
      :at_attorney_drafting,
      docket_type: Constants.AMA_DOCKETS.direct_review,
      associated_judge: judge_user,
      associated_attorney: attorney_user,
      veteran: veteran,
      request_issues: build_list(
        :request_issue, 1,
        contested_issue_description: "Tinnitus"
      )
    )
  end

  before do
    # No catching for QualityReview
    allow(QualityReviewCaseSelector).to receive(:select_case_for_quality_review?).and_return(false)

    attorney_checkout
    judge_checkout
  end

  scenario "An appeal at BVA Dispatch is sent back" do
    step "BVA Dispatch user returns the case to the judge for correction" do
      User.authenticate!(user: bva_dispatch_user)
      visit("/queue")
      click_on veteran_full_name
      click_dropdown(prompt: "Select an action", text: "Return to judge")
      fill_in("taskInstructions", with: "Returned from BVA Dispatch to correct error")
      click_on "Submit"
      expect(page).to have_content(COPY::ASSIGN_TASK_SUCCESS_MESSAGE % judge_user.full_name)
    end
    step "Judge sends the case to the Attorney to fix the decision" do
      User.authenticate!(user: judge_user)
      visit("/queue")
      click_on veteran_full_name
      click_dropdown(prompt: "Select an action", text: "Return to attorney")
      fill_in("taskInstructions", with: "Returned from BVA Dispatch to correct error")
      click_on "Submit"
      expect(page).to have_content(COPY::ASSIGN_TASK_SUCCESS_MESSAGE % attorney_user.full_name)
    end
    step "Attorney returns the case to the judge" do
      attorney_checkout
      expect(page).to have_content(
        "Thank you for drafting #{veteran_full_name}'s decision. "\
        "It's been sent to #{judge_user.full_name} for review."
      )
    end
    step "Judge reviews the corrections and returns the case to BVA Dispatch" do
      judge_checkout
      expect(page).to have_content(COPY::JUDGE_CHECKOUT_DISPATCH_SUCCESS_MESSAGE_TITLE % appeal.veteran_full_name)
      sleep 5
    end
    step "BVA Dispatch has received the case" do
      User.authenticate!(user: bva_dispatch_user)
      visit("/queue")
      expect(page).to have_content(veteran_full_name)
    end
  end
end

def attorney_checkout
  User.authenticate!(user: attorney_user)
  visit "/queue"
  click_on veteran_full_name
  click_dropdown(prompt: "Select an action", text: "Decision ready for review")
  if !find("#no_special_issues", visible: false).checked?
    find("label", text: "No Special Issues").click
  end
  click_on "Continue"

  click_on "+ Add decision"
  fill_in "Text Box", with: "test"

  find(".cf-select__control", text: "Select disposition").click
  find("div", class: "cf-select__option", text: "Allowed").click
  click_on "Save"
  click_on "Continue"
  fill_in "Document ID:", with: "12345-12345678"
  fill_in "notes", with: "all done"
  click_on "Continue"
end

def judge_checkout
  User.authenticate!(user: judge_user)
  visit "/queue"
  click_on "(#{appeal.veteran_file_number})"
  click_dropdown(text: Constants.TASK_ACTIONS.JUDGE_AMA_CHECKOUT.label)
  click_on "Continue"
  click_on "Continue"
  find("label", text: Constants::JUDGE_CASE_REVIEW_OPTIONS["COMPLEXITY"]["easy"]).click
  text_to_click = "1 - #{Constants::JUDGE_CASE_REVIEW_OPTIONS['QUALITY']['does_not_meet_expectations']}"
  find("label", text: text_to_click).click
  find("#logically_organized", visible: false).sibling("label").click
  find("#issues_are_not_addressed", visible: false).sibling("label").click

  dummy_note = generate_words 5
  fill_in "additional-factors", with: dummy_note
  click_on "Continue"
end
