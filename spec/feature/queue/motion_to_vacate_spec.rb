# frozen_string_literal: true

require "support/vacols_database_cleaner"
require "rails_helper"

DISPOSITION_TEXT = {
  granted: "grant or partial vacature",
  denied: "denial of all issues for vacature",
  dismissed: "dismissal"
}.freeze

VACATE_TYPE_TEXT = {
  straight_vacate_and_readjudication: "Straight Vacate and Readjudication",
  vacate_and_de_novo: "Vacate and De Novo"
}.freeze

RSpec.feature "Motion to vacate", :all_dbs do
  include QueueHelpers

  let!(:lit_support_team) { LitigationSupport.singleton }
  let(:receipt_date) { Time.zone.today - 20 }
  let!(:appeal) { create(:appeal, receipt_date: receipt_date) }
  let!(:root_task) { create(:root_task, appeal: appeal) }
  let!(:motions_attorney) { create(:user, full_name: "Motions attorney") }
  let!(:judge) { create(:user, full_name: "Judge the First", css_id: "JUDGE_1") }
  let!(:hyperlink) { "https://va.gov/fake-link-to-file" }

  before do
    create(:staff, :judge_role, sdomainid: judge.css_id)
    OrganizationsUser.add_user_to_organization(motions_attorney, lit_support_team)
  end

  describe "Motion to vacate mail task" do
    let!(:mail_user) { create(:user, full_name: "Mail user") }
    let!(:mail_team) { MailTeam.singleton }
    let!(:lit_support_user) { create(:user, full_name: "Lit support user") }

    let!(:judge2) { create(:user, full_name: "Judge the Second", css_id: "JUDGE_2") }
    let!(:judge3) { create(:user, full_name: "Judge the Third", css_id: "JUDGE_3") }

    let!(:judge_review_task) do
      create(:ama_judge_decision_review_task, :completed,
             assigned_to: judge2, appeal: appeal, created_at: receipt_date + 3.days, parent: root_task)
    end

    before do
      create(:staff, :judge_role, sdomainid: judge2.css_id)
      create(:staff, :judge_role, sdomainid: judge3.css_id)
      OrganizationsUser.add_user_to_organization(mail_user, mail_team)
      OrganizationsUser.add_user_to_organization(lit_support_user, lit_support_team)
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
      let!(:motions_attorney_task) do
        create(:vacate_motion_mail_task, appeal: appeal, assigned_to: motions_attorney, parent: root_task)
      end

      it "motions attorney recommends grant decision to judge" do
        send_to_judge(user: motions_attorney, appeal: appeal, motions_attorney_task: motions_attorney_task)

        find("label[for=disposition_granted]").click
        fill_in("instructions", with: "Attorney context/instructions for judge")

        # Ensure it has pre-selected judge previously assigned to case
        expect(dropdown_selected_value(find(".dropdown-judge"))).to eq judge2.display_name

        click_button(text: "Submit")

        # Return back to user's queue
        expect(page).to have_current_path("/queue")

        # Verify new task was created
        judge_task = JudgeAddressMotionToVacateTask.find_by(assigned_to: judge2)
        expect(judge_task).to_not be_nil
      end

      it "motions attorney recommends denied decision to judge and fills in hyperlink" do
        send_to_judge(user: motions_attorney, appeal: appeal, motions_attorney_task: motions_attorney_task)

        find("label[for=disposition_denied]").click
        fill_in("hyperlink", with: hyperlink)
        fill_in("instructions", with: "Attorney context/instructions for judge")
        click_dropdown(text: judge2.display_name)
        click_button(text: "Submit")

        # Return back to user's queue
        expect(page).to have_current_path("/queue")

        # Verify new task was created
        judge_task = JudgeAddressMotionToVacateTask.find_by(assigned_to: judge2)
        expect(judge_task).to_not be_nil
      end
    end
  end

  describe "JudgeAddressMotionToVacateTask" do
    let!(:judge_team) { JudgeTeam.create_for_judge(judge) }
    let!(:drafting_attorney) { create(:user, full_name: "Drafty McDrafter") }

    let!(:orig_atty_task) do
      create(:ama_attorney_task, :completed,
             assigned_to: drafting_attorney, appeal: appeal, created_at: receipt_date + 1.day, parent: root_task)
    end
    let!(:judge_review_task) do
      create(:ama_judge_decision_review_task, :completed,
             assigned_to: judge, appeal: appeal, created_at: receipt_date + 3.days, parent: root_task)
    end
    let!(:judge_address_motion_to_vacate_task) do
      create(:judge_address_motion_to_vacate_task, appeal: appeal, assigned_to: judge)
    end
    let!(:atty_option_txt) { "#{drafting_attorney.full_name} (Orig. Attorney)" }
    let!(:judge_notes) { "Here's why I made my decision..." }

    before do
      create(:staff, :judge_role, sdomainid: judge.css_id)
      OrganizationsUser.add_user_to_organization(motions_attorney, lit_support_team)
      OrganizationsUser.add_user_to_organization(drafting_attorney, judge_team)
      ["John Doe", "Jane Doe"].map do |name|
        OrganizationsUser.add_user_to_organization(create(:user, full_name: name), judge_team)
      end
      FeatureToggle.enable!(:review_motion_to_vacate)
    end

    after { FeatureToggle.disable!(:review_motion_to_vacate) }

    it "judge grants motion to vacate (straight vacate)" do
      address_motion_to_vacate(user: judge, appeal: appeal, judge_task: judge_address_motion_to_vacate_task)
      find("label[for=disposition_granted]").click
      find("label[for=vacate-type_straight_vacate_and_readjudication]").click
      fill_in("instructions", with: judge_notes)

      # Ensure it has pre-selected judge previously assigned to case
      expect(dropdown_selected_value(find(".dropdown-attorney"))).to eq atty_option_txt

      click_button(text: "Submit")

      # Return back to user's queue
      expect(page).to have_current_path("/queue")

      # Verify PostDecisionMotion is created
      motion = PostDecisionMotion.find_by(task: judge_address_motion_to_vacate_task)
      expect(motion).to_not be_nil
      expect(motion.disposition).to eq("granted")

      # Verify new task creation
      instructions = format_judge_instructions(
        notes: judge_notes,
        disposition: "granted",
        vacate_type: "straight_vacate_and_readjudication"
      )
      new_task = StraightVacateAndReadjudicationTask.find_by(assigned_to: drafting_attorney)
      expect(new_task).to_not be_nil
      expect(new_task.instructions.join("")).to eq(instructions)
    end

    it "judge grants motion to vacate (vacate & de novo)" do
      address_motion_to_vacate(user: judge, appeal: appeal, judge_task: judge_address_motion_to_vacate_task)
      find("label[for=disposition_granted]").click
      find("label[for=vacate-type_vacate_and_de_novo]").click
      fill_in("instructions", with: judge_notes)

      # Ensure it has pre-selected judge previously assigned to case
      expect(dropdown_selected_value(find(".dropdown-attorney"))).to eq atty_option_txt

      click_button(text: "Submit")

      # Return back to user's queue
      expect(page).to have_current_path("/queue")

      # Verify PostDecisionMotion is created
      motion = PostDecisionMotion.find_by(task: judge_address_motion_to_vacate_task)
      expect(motion).to_not be_nil
      expect(motion.disposition).to eq("granted")

      # Verify new task creation
      instructions = format_judge_instructions(
        notes: judge_notes,
        disposition: "granted",
        vacate_type: "vacate_and_de_novo"
      )
      new_task = VacateAndDeNovoTask.find_by(assigned_to: drafting_attorney)
      expect(new_task).to_not be_nil
      expect(new_task.instructions.join("")).to eq(instructions)
    end

    it "judge denies motion to vacate" do
      address_motion_to_vacate(user: judge, appeal: appeal, judge_task: judge_address_motion_to_vacate_task)
      find("label[for=disposition_denied]").click
      fill_in("instructions", with: judge_notes)
      fill_in("hyperlink", with: hyperlink)

      # Ensure it has pre-selected judge previously assigned to case
      expect(dropdown_selected_value(find(".dropdown-attorney"))).to eq atty_option_txt
      click_button(text: "Submit")

      # Return back to user's queue
      expect(page).to have_current_path("/queue")

      # Verify PostDecisionMotion is created; should ultimately also check new tasks
      motion = PostDecisionMotion.find_by(task: judge_address_motion_to_vacate_task)
      expect(motion).to_not be_nil
      expect(motion.disposition).to eq("denied")

      # Verify new task creation
      instructions = format_judge_instructions(
        notes: judge_notes,
        disposition: "denied",
        hyperlink: hyperlink
      )
      new_task = DeniedMotionToVacateTask.find_by(assigned_to: drafting_attorney)
      expect(new_task).to_not be_nil
      expect(new_task.instructions.join("")).to eq(instructions)
    end

    it "judge dismisses motion to vacate" do
      address_motion_to_vacate(user: judge, appeal: appeal, judge_task: judge_address_motion_to_vacate_task)
      find("label[for=disposition_dismissed]").click
      fill_in("instructions", with: judge_notes)
      fill_in("hyperlink", with: hyperlink)

      # Ensure it has pre-selected judge previously assigned to case
      expect(dropdown_selected_value(find(".dropdown-attorney"))).to eq atty_option_txt

      click_button(text: "Submit")

      # Return back to user's queue
      expect(page).to have_current_path("/queue")

      # Verify PostDecisionMotion is created; should ultimately also check new tasks
      motion = PostDecisionMotion.find_by(task: judge_address_motion_to_vacate_task)
      expect(motion).to_not be_nil
      expect(motion.disposition).to eq("dismissed")

      # Verify new task creation
      instructions = format_judge_instructions(
        notes: judge_notes,
        disposition: "dismissed",
        hyperlink: hyperlink
      )
      new_task = DismissedMotionToVacateTask.find_by(assigned_to: drafting_attorney)
      expect(new_task).to_not be_nil
      expect(new_task.instructions.join("")).to eq(instructions)
    end
  end

  def send_to_judge(user:, appeal:, motions_attorney_task:)
    User.authenticate!(user: user)
    visit "/queue/appeals/#{appeal.uuid}"
    find(".Select-placeholder", text: COPY::TASK_ACTION_DROPDOWN_BOX_LABEL).click
    find("div", class: "Select-option", text: "Send to judge").click
    expect(page.current_path).to eq("/queue/appeals/#{appeal.uuid}/tasks/#{motions_attorney_task.id}/send_to_judge")
  end

  def address_motion_to_vacate(user:, appeal:, judge_task:)
    User.authenticate!(user: user)
    visit "/queue/appeals/#{appeal.uuid}"
    find(".Select-placeholder", text: COPY::TASK_ACTION_DROPDOWN_BOX_LABEL).click
    find("div", class: "Select-option", text: "Address Motion to Vacate").click
    expect(page.current_path).to eq("/queue/appeals/#{appeal.uuid}/tasks/#{judge_task.id}/address_motion_to_vacate")
  end
end
