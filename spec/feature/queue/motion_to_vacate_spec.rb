# frozen_string_literal: true

require "support/vacols_database_cleaner"
require "rails_helper"

RSpec.feature "Motion to vacate", :all_dbs do
  let!(:lit_support_team) { LitigationSupport.singleton }
  let(:appeal) { create(:appeal) }

  describe "Motion to vacate mail task" do
    let(:mail_user) { create(:user, full_name: "Mail user") }
    let!(:mail_team) { MailTeam.singleton }
    let(:lit_support_user) { create(:user, full_name: "Lit support user") }
    let(:motions_attorney) { create(:user, full_name: "Motions attorney") }
    let(:judge1) { create(:user, full_name: "Judge the First", css_id: "JUDGE_1") }
    let(:judge2) { create(:user, full_name: "Judge the Second", css_id: "JUDGE_2") }
    let(:judge3) { create(:user, full_name: "Judge the Third", css_id: "JUDGE_3") }

    before do
      create(:staff, :judge_role, sdomainid: judge1.css_id)
      create(:staff, :judge_role, sdomainid: judge2.css_id)
      create(:staff, :judge_role, sdomainid: judge3.css_id)
      OrganizationsUser.add_user_to_organization(mail_user, mail_team)
      OrganizationsUser.add_user_to_organization(lit_support_user, lit_support_team)
      OrganizationsUser.add_user_to_organization(motions_attorney, lit_support_team)
      FeatureToggle.enable!(:review_motion_to_vacate)
    end

    after { FeatureToggle.disable!(:review_motion_to_vacate) }

    it "gets assigned to Litigation Support" do
      # When mail team creates VacateMotionMailTask, it gets assigned to the lit support organization
      User.authenticate!(user: mail_user)
      visit "/queue/appeals/#{appeal.uuid}"
      find("button", text: COPY::TASK_SNAPSHOT_ADD_NEW_TASK_LABEL).click
      find(".Select-control", text: COPY::MAIL_TASK_DROPDOWN_TYPE_SELECTOR_LABEL).click
      find("div", class: "Select-option", text: COPY::VACATE_MOTION_MAIL_TASK_LABEL).click
      fill_in("taskInstructions", with: "Instructions for motion to vacate mail task")
      find("button", text: "Submit").click
      expect(page).to have_content("Created Motion to vacate task")
      expect(VacateMotionMailTask.find_by(assigned_to: lit_support_team)).to_not be_nil

      # Lit support user can assign task to a motions attorney
      User.authenticate!(user: lit_support_user)
      visit "/queue/appeals/#{appeal.uuid}"
      find(".Select-placeholder", text: COPY::TASK_ACTION_DROPDOWN_BOX_LABEL).click
      find("div", class: "Select-option", text: "Assign to person").click
      find(".Select-value").click
      find("div", class: "Select-option", text: "Motions attorney").click
      click_button(text: "Submit")
      expect(page).to have_content("Task assigned to Motions attorney")
      motions_attorney_task = VacateMotionMailTask.find_by(assigned_to: motions_attorney)
      expect(motions_attorney_task).to_not be_nil

      # Motions attorney can send to judge
      User.authenticate!(user: motions_attorney)
      visit "/queue/appeals/#{appeal.uuid}"
      find(".Select-placeholder", text: COPY::TASK_ACTION_DROPDOWN_BOX_LABEL).click
      find("div", class: "Select-option", text: "Send to judge").click
      expect(page.current_path).to eq("/queue/appeals/#{appeal.uuid}/tasks/#{motions_attorney_task.id}/send_to_judge")
    end

    context "motions attorney reviews case" do
      let!(:motions_attorney_task) { create(:vacate_motion_mail_task, appeal: appeal, assigned_to: motions_attorney) }

      it "motions attorney recommends grant decision to judge" do
        send_to_judge(user: motions_attorney, appeal: appeal, motions_attorney_task: motions_attorney_task)

        find("label[for=disposition_granted]").click
        fill_in("instructions", with: "Attorney context/instructions for judge")
        click_dropdown(text: judge2.display_name)
        click_button(text: "Submit")

        # Should this go back to user's queue...?
        expect(page.current_path).to eq("/queue")
        # expect(page).to have_content("Your Queue")

        # Enable test once backend truly supports
        judge_task = JudgeAddressMotionToVacateTask.find_by(assigned_to: judge2)
        expect(judge_task).to_not be_nil
      end

      it "motions attorney recommends denied decision to judge and fills in hyperlink" do
        send_to_judge(user: motions_attorney, appeal: appeal, motions_attorney_task: motions_attorney_task)

        find("label[for=disposition_denied]").click
        fill_in("hyperlink", with: "https://va.gov/fake-link-to-file")
        fill_in("instructions", with: "Attorney context/instructions for judge")
        click_dropdown(text: judge2.display_name)
        click_button(text: "Submit")

        # Should this go back to user's queue...?
        expect(page.current_path).to eq("/queue")

        # Enable test once backend truly supports
        judge_task = JudgeAddressMotionToVacateTask.find_by(assigned_to: judge2)
        expect(judge_task).to_not be_nil
      end
    end
  end

  def send_to_judge(user:, appeal:, motions_attorney_task:)
    User.authenticate!(user: user)
    visit "/queue/appeals/#{appeal.uuid}"
    find(".Select-placeholder", text: COPY::TASK_ACTION_DROPDOWN_BOX_LABEL).click
    find("div", class: "Select-option", text: "Send to judge").click
    expect(page.current_path).to eq("/queue/appeals/#{appeal.uuid}/tasks/#{motions_attorney_task.id}/send_to_judge")
  end
end
