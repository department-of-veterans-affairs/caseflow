# frozen_string_literal: true

RSpec.feature "CAVC-related tasks queue", :all_dbs do
  let!(:org_admin) do
    create(:user, full_name: "Adminy CacvRemandy") do |u|
      OrganizationsUser.make_user_admin(u, CavcLitigationSupport.singleton)
    end
  end
  let!(:org_nonadmin) { create(:user, full_name: "Woney Remandy") { |u| CavcLitigationSupport.singleton.add_user(u) } }
  let!(:org_nonadmin2) { create(:user, full_name: "Tooey Remandy") { |u| CavcLitigationSupport.singleton.add_user(u) } }
  let!(:other_user) { create(:user, full_name: "Othery Usery") }

  context "when intaking a cavc remand" do
    before { BvaDispatch.singleton.add_user(create(:user)) }

    let(:appeal) { create(:appeal, :dispatched) }

    let(:notes) { "Pain disorder with 100\% evaluation per examination" }
    let(:description) { "Service connection for pain disorder is granted at 70\% effective May 1 2011" }
    let!(:decision_issues) do
      create_list(
        :decision_issue,
        3,
        :rating,
        decision_review: appeal,
        disposition: "denied",
        description: description,
        decision_text: notes
      )
    end

    let(:docket_number) { "12-1234" }
    let(:date) { "11/11/2020" }
    let(:judge_name) { Constants::CAVC_JUDGE_FULL_NAMES.first }
    let(:decision_type) { Constants.CAVC_DECISION_TYPES.remand.titleize }

    shared_examples "does not display the add remand button" do
      it "does not display the add remand button" do
        visit "queue/appeals/#{appeal.external_id}"
        expect(page).to have_no_content "+ Add CAVC Remand"
      end
    end

    context "when feature toggle is not on" do
      before { User.authenticate!(user: org_admin) }

      it_behaves_like "does not display the add remand button"
    end

    context "when the signed in user is not on cavc litigation support" do
      before do
        User.authenticate!(user: create(:user))
        FeatureToggle.enable!(:cavc_remand)
      end
      after { FeatureToggle.disable!(:cavc_remand) }

      it_behaves_like "does not display the add remand button"
    end

    context "when the signed in user is not on cavc litigation support and the feature toggle is on" do
      before do
        FeatureToggle.enable!(:cavc_remand)
        User.authenticate!(user: org_admin)
      end
      after { FeatureToggle.disable!(:cavc_remand) }

      it "allows the user to intake a cavc remand" do
        visit "queue/appeals/#{appeal.external_id}"
        page.find("button", text: "+ Add CAVC Remand").click

        # Field validation
        page.find("button", text: "Submit").click
        expect(page).to have_content COPY::CAVC_DOCKET_NUMBER_ERROR
        expect(page).to have_content COPY::CAVC_JUDGE_ERROR
        expect(page).to have_content COPY::CAVC_DECISION_DATE_ERROR
        expect(page).to have_content COPY::CAVC_JUDGEMENT_DATE_ERROR
        expect(page).to have_content COPY::CAVC_MANDATE_DATE_ERROR
        expect(page).to have_content COPY::CAVC_INSTRUCTIONS_ERROR

        fill_in "docket-number", with: "bad docket number"
        expect(page).to have_content COPY::CAVC_DOCKET_NUMBER_ERROR

        fill_in "docket-number", with: docket_number
        expect(page).to have_no_content COPY::CAVC_DOCKET_NUMBER_ERROR

        click_dropdown(text: judge_name)
        expect(page).to have_no_content COPY::CAVC_JUDGE_ERROR

        page.find("label", text: Constants.CAVC_DECISION_TYPES.death_dismissal.titleize).click
        expect(page).to have_no_content COPY::CAVC_SUB_TYPE_LABEL
        page.find("label", text: decision_type).click
        expect(page).to have_content COPY::CAVC_SUB_TYPE_LABEL

        fill_in "decision-date", with: date
        fill_in "judgement-date", with: date
        fill_in "mandate-date", with: date
        expect(page).to have_no_content COPY::CAVC_DECISION_DATE_ERROR
        expect(page).to have_no_content COPY::CAVC_JUDGEMENT_DATE_ERROR
        expect(page).to have_no_content COPY::CAVC_MANDATE_DATE_ERROR

        decision_issues.each { |issue| expect(find_field(description, id: issue.id, visible: false)).to be_checked }

        fill_in "context-and-instructions-textBox", with: "Please process this remand"
        expect(page).to have_no_content COPY::CAVC_INSTRUCTIONS_ERROR

        page.find("button", text: "Submit").click

        expect(page).to have_content COPY::CAVC_REMAND_CREATED_TITLE
        expect(page).to have_content COPY::CAVC_REMAND_CREATED_DETAIL

        expect(page).to have_content "APPEAL STREAM TYPE\nCAVC"
        expect(page).to have_content "DOCKET\nE\n#{appeal.docket_number}"
        expect(page).to have_content "TASK\n#{SendCavcRemandProcessedLetterTask.label}"
        expect(page).to have_content "ASSIGNED TO\n#{CavcLitigationSupport.singleton.name}"

        expect(page).to have_content "CAVC Remand"
        expect(page).to have_content "#{COPY::CASE_DETAILS_CAVC_DOCKET_NUMBER}: #{docket_number}"
        expect(page).to have_content "#{COPY::CASE_DETAILS_CAVC_ATTORNEY}: Yes"
        expect(page).to have_content "#{COPY::CASE_DETAILS_CAVC_JUDGE}: #{judge_name}"
        expect(page).to have_content "#{COPY::CASE_DETAILS_CAVC_PROCEDURE}: #{decision_type}"
        expect(page).to have_content "#{COPY::CASE_DETAILS_CAVC_TYPE}: #{Constants.CAVC_REMAND_SUBTYPE_NAMES.jmr}"
        expect(page).to have_content "#{COPY::CASE_DETAILS_CAVC_DECISION_DATE}: #{date}"
        expect(page).to have_content "#{COPY::CASE_DETAILS_CAVC_JUDGEMENT_DATE}: #{date}"
        expect(page).to have_content "#{COPY::CASE_DETAILS_CAVC_MANDATE_DATE}: #{date}"
      end
    end
  end

  context "when CAVC Lit Support is assigned SendCavcRemandProcessedLetterTask" do
    let!(:send_task) { create(:send_cavc_remand_processed_letter_task) }

    it "allows admin to assign SendCavcRemandProcessedLetterTask to user" do
      # Logged in as CAVC Lit Support admin
      User.authenticate!(user: org_admin)
      visit "queue/appeals/#{send_task.appeal.external_id}"

      find(".cf-select__control", text: "Select an action").click
      find("div", class: "cf-select__option", text: Constants.TASK_ACTIONS.ASSIGN_TO_PERSON.label).click

      find(".cf-select__control", text: org_admin.full_name).click
      find("div", class: "cf-select__option", text: org_nonadmin.full_name).click
      fill_in "taskInstructions", with: "Confirm info and send letter to Veteran."
      click_on "Submit"
      expect(page).to have_content COPY::ASSIGN_TASK_SUCCESS_MESSAGE % org_nonadmin.full_name

      # Logged in as first user assignee
      User.authenticate!(user: org_nonadmin)
      visit "queue/appeals/#{send_task.appeal.external_id}"

      find(".cf-select__control", text: "Select an action").click
      expect(page).to have_content Constants.TASK_ACTIONS.MARK_COMPLETE.label
      expect(page).to have_content Constants.TASK_ACTIONS.REASSIGN_TO_PERSON.label

      find("div", class: "cf-select__option", text: Constants.TASK_ACTIONS.REASSIGN_TO_PERSON.label).click
      find(".cf-select__control", text: COPY::ASSIGN_WIDGET_DROPDOWN_PLACEHOLDER).click
      find("div", class: "cf-select__option", text: org_nonadmin2.full_name).click
      fill_in "taskInstructions", with: "Going fishing. Handing off to you."
      click_on "Submit"
      expect(page).to have_content COPY::REASSIGN_TASK_SUCCESS_MESSAGE % org_nonadmin2.full_name

      # Logged in as second user assignee (due to reassignment)
      User.authenticate!(user: org_nonadmin2)
      visit "queue/appeals/#{send_task.appeal.external_id}"

      find(".cf-select__control", text: "Select an action").click
      find("div", class: "cf-select__option", text: Constants.TASK_ACTIONS.MARK_COMPLETE.label).click
      fill_in "completeTaskInstructions", with: "Letter sent."
      click_on COPY::MARK_TASK_COMPLETE_BUTTON
      expect(page).to have_content COPY::MARK_TASK_COMPLETE_CONFIRMATION % send_task.appeal.veteran_full_name
    end
  end
end
