# frozen_string_literal: true

RSpec.feature "Docket Switch", :all_dbs do
  include QueueHelpers
  before do
    FeatureToggle.enable!(:docket_switch)
    cotb_org.add_user(cotb_attorney)
    cotb_org.add_user(cotb_non_attorney)
    create(:staff, :judge_role, sdomainid: judge.css_id)
  end
  after { FeatureToggle.disable!(:docket_switch) }

  let(:cotb_org) { ClerkOfTheBoard.singleton }
  let(:receipt_date) { Time.zone.today - 20 }
  let(:appeal) do
    create(:appeal, receipt_date: receipt_date)
  end
  let(:decision_issues) do
    3.times do |idx|
      create(
        :decision_issue,
        :rating,
        decision_review: appeal,
        disposition: "denied",
        description: "Decision issue description #{idx}",
        decision_text: "decision issue"
      )
    end
  end
  let(:root_task) { create(:root_task, :completed, appeal: appeal) }
  let(:cotb_attorney) { create(:user, :with_vacols_attorney_record, full_name: "Clark Bard") }
  let!(:cotb_non_attorney) { create(:user, full_name: "Aang Bender") }
  let(:judge) { create(:user, :with_vacols_judge_record, full_name: "Judge the First", css_id: "JUDGE_1") }

  describe "create DocketSwitchMailTask" do
    it "allows Clerk of the Board users to create DocketSwitchMailTask" do
      User.authenticate!(user: cotb_attorney)
      visit "/queue/appeals/#{appeal.uuid}"
      find("button", text: COPY::TASK_SNAPSHOT_ADD_NEW_TASK_LABEL).click
      find(".cf-select__control", text: COPY::MAIL_TASK_DROPDOWN_TYPE_SELECTOR_LABEL).click
      find("div", class: "cf-select__option", text: COPY::DOCKET_SWITCH_MAIL_TASK_LABEL).click
      fill_in("taskInstructions", with: "Instructions for docket switch mail task")
      find("button", text: "Submit").click
      expect(page).to have_content(format(COPY::SELF_ASSIGNED_MAIL_TASK_CREATION_SUCCESS_TITLE, "Docket Switch"))
      expect(page).to have_content(COPY::SELF_ASSIGNED_MAIL_TASK_CREATION_SUCCESS_MESSAGE)
      expect(DocketSwitchMailTask.find_by(assigned_to: cotb_attorney)).to_not be_nil
    end
  end

  describe "attorney recommend docket switch" do
    let!(:docket_switch_mail_task) do
      create(:docket_switch_mail_task, appeal: appeal, parent: root_task, assigned_to: cotb_attorney)
    end
    let!(:judge_assign_task) { create(:ama_judge_assign_task, assigned_to: judge, parent: root_task) }
    let!(:other_judges) do
      create_list(:user, 3, :with_vacols_judge_record)
    end

    let(:summary) { "Lorem ipsum dolor sit amet, consectetur adipiscing elit" }
    let(:hyperlink) { "https://example.com/file.txt" }
    let(:disposition) { "granted" }
    let(:timely) { "yes" }

    it "allows Clerk of the Board attorney to send docket switch recommendation to judge" do
      User.authenticate!(user: cotb_attorney)
      visit "/queue/appeals/#{appeal.uuid}"
      find(".cf-select__control", text: COPY::TASK_ACTION_DROPDOWN_BOX_LABEL).click
      find("div", class: "cf-select__option", text: Constants.TASK_ACTIONS.DOCKET_SWITCH_SEND_TO_JUDGE.label).click

      expect(page).to have_content(format(COPY::DOCKET_SWITCH_RECOMMENDATION_TITLE, appeal.claimant.name))
      expect(page).to have_content(COPY::DOCKET_SWITCH_RECOMMENDATION_INSTRUCTIONS)

      # Fill out form
      fill_in("summary", with: summary)
      find("label[for=timely_#{timely}]").click
      find("label[for=disposition_#{disposition}]").click
      fill_in("hyperlink", with: hyperlink)

      # The previously assigned judge should be selected
      expect(page).to have_content(judge_assign_task.assigned_to.display_name)

      click_button(text: "Submit")

      # Return back to user's queue
      expect(page).to have_current_path("/queue")

      # Success banner
      expect(page).to have_content(COPY::DOCKET_SWITCH_RECOMMENDATION_SUCCESS_MESSAGE)

      judge_task = DocketSwitchRulingTask.find_by(assigned_to: judge)
      expect(judge_task).to_not be_nil

      # Switch to judge to verify instructions
      User.authenticate!(user: judge)
      visit "/queue/appeals/#{appeal.uuid}"
      find("button", text: COPY::TASK_SNAPSHOT_VIEW_TASK_INSTRUCTIONS_LABEL).click

      expect(page).to have_content "Summary: #{summary}"
      expect(page).to have_content "Is this a timely request: #{timely.capitalize}"
      expect(page).to have_content "Recommendation: Grant all issues"
      expect(page).to have_content "Draft letter: #{hyperlink}"
    end
  end

  describe "judge completes docket switch ruling" do
    let!(:docket_switch_ruling_task) do
      create(
        :docket_switch_ruling_task,
        appeal: appeal,
        parent: root_task,
        assigned_to: judge,
        assigned_by: cotb_attorney
      )
    end
    let(:context) { "Lorem ipsum dolor sit amet, consectetur adipiscing elit" }
    let(:hyperlink) { "https://example.com/file.txt" }

    # Checks granted, partially_granted, and denied dispositions
    Constants::DOCKET_SWITCH.each_key do |disposition|
      context "given disposition #{disposition}" do
        it "creates the next docket switch task (granted or denied) assigned to a COTB attorney" do
          User.authenticate!(user: judge)
          visit "/queue/appeals/#{appeal.uuid}"
          find(".cf-select__control", text: COPY::TASK_ACTION_DROPDOWN_BOX_LABEL).click
          find("div", class: "cf-select__option", text: Constants.TASK_ACTIONS.DOCKET_SWITCH_JUDGE_RULING.label).click

          expect(page).to have_content(format(COPY::DOCKET_SWITCH_RULING_TITLE, appeal.claimant.name))

          # Fill out form
          fill_in("context", with: context)
          find("label[for=disposition_#{disposition}]").click
          fill_in("hyperlink", with: hyperlink)

          # The previously assigned COTB attorney should be selected
          expect(page).to have_content(cotb_attorney.full_name)
          expect(page).to_not have_content(cotb_non_attorney.full_name)
          click_button(text: "Submit")

          # Return back to user's queue
          expect(page).to have_current_path("/queue")
          # Success banner
          disposition_type = Constants::DOCKET_SWITCH[disposition]["dispositionType"]
          expect(page).to have_content(
            format(COPY::DOCKET_SWITCH_RULING_SUCCESS_TITLE, disposition_type.downcase, appeal.claimant.name)
          )

          next_task = Object.const_get("DocketSwitch#{disposition_type}Task").find_by(assigned_to: cotb_attorney)
          expect(next_task).to_not be_nil

          # Check that task got created and shows instructions on Case Details
          User.authenticate!(user: cotb_attorney)
          visit "/queue/appeals/#{appeal.uuid}"
          find("button", text: COPY::TASK_SNAPSHOT_VIEW_TASK_INSTRUCTIONS_LABEL).click
          judge_ruling_text = Constants::DOCKET_SWITCH[disposition]["judgeRulingText"]

          expect(page).to have_content "I am proceeding with a #{judge_ruling_text}"
          expect(page).to have_content "Signed ruling letter:\n#{hyperlink}"
          expect(page).to have_content(context)
        end
      end
    end
  end

  describe "COTB attorney completes docket switch denial" do
    let!(:docket_switch_denied_task) do
      create(
        :docket_switch_denied_task,
        appeal: appeal,
        parent: root_task,
        assigned_to: cotb_attorney,
        assigned_by: judge
      )
    end
    let(:receipt_date) { Time.zone.today - 5.days }
    let(:context) { "Lorem ipsum dolor sit amet, consectetur adipiscing elit" }

    it "allows attorney to complete the docket switch denial" do
      User.authenticate!(user: cotb_attorney)
      visit "/queue/appeals/#{appeal.uuid}"
      find(".cf-select__control", text: COPY::TASK_ACTION_DROPDOWN_BOX_LABEL).click
      find("div", class: "cf-select__option", text: Constants.TASK_ACTIONS.DOCKET_SWITCH_DENIED.label).click

      expect(page).to have_content(format(COPY::DOCKET_SWITCH_DENIAL_TITLE, appeal.claimant.name))
      expect(page).to have_content(COPY::DOCKET_SWITCH_DENIAL_INSTRUCTIONS)

      fill_in "What is the Receipt Date of the docket switch request?", with: receipt_date
      fill_in("context", with: context)

      click_button(text: "Confirm")

      # Redirect to Case Details Page
      expect(page).to have_current_path("/queue/appeals/#{appeal.uuid}")

      # Verify correct success alert
      expect(page).to have_content(format(COPY::DOCKET_SWITCH_DENIAL_SUCCESS_TITLE, appeal.claimant.name))
      # Verify that denial completed correctly
      expect(docket_switch_denied_task.reload.status).to eq(Constants.TASK_STATUSES.completed)
      docket_switch = DocketSwitch.find_by(old_docket_stream_id: appeal.id)
      expect(docket_switch).to_not be_nil
    end
  end
end
