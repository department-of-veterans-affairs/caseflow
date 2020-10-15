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
  let(:judge) { create(:user, full_name: "Judge the First", css_id: "JUDGE_1") }

  before do
    create(:staff, :judge_role, sdomainid: judge.css_id)
    cotb_org.add_user(cotb_user)

    appeal.reload
  end

  describe "create DocketSwitchMailTask" do
    context "with docket_change feature toggle" do
      before { FeatureToggle.enable!(:docket_chage) }
      after { FeatureToggle.disable!(:docket_chage) }

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
end
