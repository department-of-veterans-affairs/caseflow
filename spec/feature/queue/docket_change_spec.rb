# frozen_string_literal: true

RSpec.feature "Docket Change", :all_dbs do
  include QueueHelpers

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
  let(:cotb_user) { create(:user, full_name: "Clark Bard") }
  let(:judge) { create(:user, :with_vacols_judge_record, full_name: "Judge the First", css_id: "JUDGE_1") }

  before do
    create(:staff, :judge_role, sdomainid: judge.css_id)
    cotb_org.add_user(cotb_user)

    appeal.reload
  end

  describe "create DocketSwitchMailTask" do
    context "with docket_change feature toggle" do
      before { FeatureToggle.enable!(:docket_change) }
      after { FeatureToggle.disable!(:docket_change) }

      it "allows Clerk of the Board users to create DocketSwitchMailTask" do
        User.authenticate!(user: cotb_user)
        visit "/queue/appeals/#{appeal.uuid}"
        find("button", text: COPY::TASK_SNAPSHOT_ADD_NEW_TASK_LABEL).click
        find(".cf-select__control", text: COPY::MAIL_TASK_DROPDOWN_TYPE_SELECTOR_LABEL).click
        find("div", class: "cf-select__option", text: COPY::DOCKET_SWITCH_MAIL_TASK_LABEL).click
        fill_in("taskInstructions", with: "Instructions for docket switch mail task")
        find("button", text: "Submit").click
        expect(page).to have_content(format(COPY::SELF_ASSIGNED_MAIL_TASK_CREATION_SUCCESS_TITLE, "Docket Switch"))
        expect(page).to have_content(COPY::SELF_ASSIGNED_MAIL_TASK_CREATION_SUCCESS_MESSAGE)
        expect(DocketSwitchMailTask.find_by(assigned_to: cotb_user)).to_not be_nil
      end
    end
  end

  describe "attorney recommend docket switch" do
    let!(:docket_switch_mail_task) do
      create(:docket_switch_mail_task, appeal: appeal, parent: root_task, assigned_to: cotb_user)
    end
    let!(:other_judges) do
      create_list(:user, 3, :with_vacols_judge_record)
    end
    let!(:judge_assign_task) { create(:ama_judge_assign_task, assigned_to: judge, parent: root_task) }

    let(:summary) { "Lorem ipsum dolor sit amet, consectetur adipiscing elit" }
    let(:hyperlink) { "https://example.com/file.txt" }
    let(:disposition) { "granted" }
    let(:timely) { "yes" }

    context "with docket_change feature toggle" do
      before { FeatureToggle.enable!(:docket_change) }
      after { FeatureToggle.disable!(:docket_change) }

      it "allows Clerk of the Board attorney to send docket switch recommendation to judge" do
        User.authenticate!(user: cotb_user)
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
  end
end
