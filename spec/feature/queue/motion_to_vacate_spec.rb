# frozen_string_literal: true

RSpec.feature "Motion to vacate", :all_dbs do
  include QueueHelpers

  let!(:lit_support_team) { LitigationSupport.singleton }
  let(:receipt_date) { Time.zone.today - 20 }
  let!(:appeal) do
    create(:appeal, receipt_date: receipt_date)
  end
  let!(:decision_issues) do
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
  let!(:root_task) { create(:root_task, appeal: appeal) }
  let!(:motions_attorney) { create(:user, full_name: "Motions attorney") }
  let!(:judge) { create(:user, full_name: "Judge the First", css_id: "JUDGE_1") }
  let!(:hyperlink) { "https://va.gov/fake-link-to-file" }

  before do
    create(:staff, :judge_role, sdomainid: judge.css_id)
    lit_support_team.add_user(motions_attorney)

    appeal.reload
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
      mail_team.add_user(mail_user)
      lit_support_team.add_user(lit_support_user)
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

      it "motions attorney triggers Pulac-Cerullo" do
        User.authenticate!(user: motions_attorney)
        visit "/queue/appeals/#{appeal.uuid}"

        find(".Select-placeholder", text: COPY::TASK_ACTION_DROPDOWN_BOX_LABEL).click
        find("div", class: "Select-option", text: Constants.TASK_ACTIONS.LIT_SUPPORT_PULAC_CERULLO.label).click
        expect(page).to have_content(COPY::PULAC_CERULLO_MODAL_BODY_1)
        expect(page).to have_content(COPY::PULAC_CERULLO_MODAL_BODY_2)
        find("button", class: "usa-button", text: "Notify").click

        expect(page).to have_content(COPY::PULAC_CERULLO_SUCCESS_TITLE)
        expect(page).to have_content(COPY::PULAC_CERULLO_SUCCESS_DETAIL.gsub("%s", appeal.veteran_full_name))
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
    let!(:vacate_motion_mail_task) do
      create(:vacate_motion_mail_task,
             appeal: appeal,
             assigned_to: motions_attorney,
             parent: root_task,
             instructions: ["Initial instructions"])
    end
    let!(:judge_address_motion_to_vacate_task) do
      create(:judge_address_motion_to_vacate_task,
             appeal: appeal,
             assigned_to: judge,
             assigned_at: Time.zone.now,
             parent: vacate_motion_mail_task)
    end
    let!(:atty_option_txt) { "#{drafting_attorney.full_name} (Orig. Attorney)" }
    let!(:judge_notes) { "Here's why I made my decision..." }
    let!(:return_to_lit_support_instructions) { "\n\nYou forgot the denial draft" }

    before do
      create(:staff, :judge_role, sdomainid: judge.css_id)
      lit_support_team.add_user(motions_attorney)
      judge_team.add_user(drafting_attorney)
      ["John Doe", "Jane Doe"].map do |name|
        judge_team.add_user(create(:user, full_name: name))
      end
      FeatureToggle.enable!(:review_motion_to_vacate)
    end

    after { FeatureToggle.disable!(:review_motion_to_vacate) }

    it "task shows up in judge's queue" do
      User.authenticate!(user: judge)
      visit "/queue"
      expect(page).to have_content(COPY::JUDGE_ADDRESS_MOTION_TO_VACATE_TASK_LABEL)
    end

    it "judge grants motion to vacate (vacate & readjudication)" do
      address_motion_to_vacate(user: judge, appeal: appeal, judge_task: judge_address_motion_to_vacate_task)
      find("label[for=disposition_granted]").click
      find("label[for=vacate-type_vacate_and_readjudication]").click
      fill_in("instructions", with: judge_notes)

      # Ensure it has pre-selected attorney previously assigned to case
      expect(dropdown_selected_value(find(".dropdown-attorney"))).to eq atty_option_txt

      click_button(text: "Submit")

      # Return back to user's queue
      expect(page).to have_current_path("/queue")

      # Verify PostDecisionMotion is created
      motion = PostDecisionMotion.find_by(task: judge_address_motion_to_vacate_task)
      expect(motion).to_not be_nil
      expect(motion.disposition).to eq("granted")

      visit_vacate_stream
    end

    it "judge grants motion to vacate (straight vacate)" do
      address_motion_to_vacate(user: judge, appeal: appeal, judge_task: judge_address_motion_to_vacate_task)
      find("label[for=disposition_granted]").click
      find("label[for=vacate-type_straight_vacate]").click
      fill_in("instructions", with: judge_notes)

      # Ensure it has pre-selected attorney previously assigned to case
      expect(dropdown_selected_value(find(".dropdown-attorney"))).to eq atty_option_txt

      click_button(text: "Submit")

      # Return back to user's queue
      expect(page).to have_current_path("/queue")

      # Verify PostDecisionMotion is created
      motion = PostDecisionMotion.find_by(task: judge_address_motion_to_vacate_task)
      expect(motion).to_not be_nil
      expect(motion.disposition).to eq("granted")

      visit_vacate_stream
    end

    it "judge grants motion to vacate (vacate & de novo)" do
      address_motion_to_vacate(user: judge, appeal: appeal, judge_task: judge_address_motion_to_vacate_task)
      find("label[for=disposition_granted]").click
      find("label[for=vacate-type_vacate_and_de_novo]").click
      fill_in("instructions", with: judge_notes)

      # Ensure it has pre-selected attorney previously assigned to case
      expect(dropdown_selected_value(find(".dropdown-attorney"))).to eq atty_option_txt

      click_button(text: "Submit")

      # Return back to user's queue
      expect(page).to have_current_path("/queue")

      # Verify PostDecisionMotion is created
      motion = PostDecisionMotion.find_by(task: judge_address_motion_to_vacate_task)
      expect(motion).to_not be_nil
      expect(motion.disposition).to eq("granted")
      expect(motion.vacated_decision_issue_ids.length).to eq(appeal.decision_issues.length)
      expect(motion.vacated_decision_issue_ids).to include(*appeal.decision_issues.map(&:id))

      visit_vacate_stream
    end

    it "judge grants partial vacatur (vacate & readjudication)" do
      address_motion_to_vacate(user: judge, appeal: appeal, judge_task: judge_address_motion_to_vacate_task)
      find("label[for=disposition_partially_granted]").click
      find("label[for=vacate-type_vacate_and_readjudication]").click
      fill_in("instructions", with: judge_notes)

      # Ensure it has pre-selected attorney previously assigned to case
      expect(dropdown_selected_value(find(".dropdown-attorney"))).to eq atty_option_txt

      issues_to_select = [1, 3]
      issues_to_select.each { |idx| select_issue_for_vacature(idx) }

      click_button(text: "Submit")

      # Return back to user's queue
      expect(page).to have_current_path("/queue")

      # Verify PostDecisionMotion is created
      motion = PostDecisionMotion.find_by(task: judge_address_motion_to_vacate_task)
      expect(motion).to_not be_nil
      expect(motion.disposition).to eq("partially_granted")
      expect(motion.decision_issues_for_vacatur.length).to eq(issues_to_select.length)

      visit_vacate_stream
    end

    it "judge denies motion to vacate" do
      address_motion_to_vacate(user: judge, appeal: appeal, judge_task: judge_address_motion_to_vacate_task)
      find("label[for=disposition_denied]").click
      fill_in("instructions", with: judge_notes)
      fill_in("hyperlink", with: hyperlink)

      # Ensure we don't show attorney selection for this disposition
      expect(page).not_to have_selector("input#attorney")

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
      new_task = DeniedMotionToVacateTask.find_by(assigned_to: motions_attorney)
      expect(new_task).to_not be_nil
      expect(new_task.label).to eq COPY::DENIED_MOTION_TO_VACATE_TASK_LABEL
      expect(new_task.available_actions(motions_attorney)).to include(
        Constants.TASK_ACTIONS.LIT_SUPPORT_PULAC_CERULLO.to_h
      )
      expect(new_task.instructions.join("")).to eq(instructions)
    end

    it "judge returns to lit support due to missing denial draft" do
      address_motion_to_vacate(user: judge, appeal: appeal, judge_task: judge_address_motion_to_vacate_task)
      find("label[for=disposition_denied]").click

      find("a", text: "return to the motions attorney").click

      expect(page).to have_content(COPY::RETURN_TO_LIT_SUPPORT_MODAL_TITLE)
      expect(page).to have_content(COPY::RETURN_TO_LIT_SUPPORT_MODAL_DEFAULT_INSTRUCTIONS)
      find("div.cf-modal-body").fill_in("instructions",
                                        with: return_to_lit_support_instructions,
                                        fill_options: { clear: :none })

      click_button(text: "Submit")

      # Return back to user's queue
      expect(page).to have_current_path("/queue")

      motion = PostDecisionMotion.find_by(task: judge_address_motion_to_vacate_task)
      expect(motion).to be_nil

      expect(judge_address_motion_to_vacate_task.reload.status).to eq Constants.TASK_STATUSES.cancelled

      expect(vacate_motion_mail_task.reload.status).to eq Constants.TASK_STATUSES.assigned
      expect(vacate_motion_mail_task.instructions.length).to eq 2

      expected_instructions = COPY::RETURN_TO_LIT_SUPPORT_MODAL_DEFAULT_INSTRUCTIONS +
                              return_to_lit_support_instructions
      expect(vacate_motion_mail_task.instructions).to include(expected_instructions)
    end

    it "judge dismisses motion to vacate" do
      address_motion_to_vacate(user: judge, appeal: appeal, judge_task: judge_address_motion_to_vacate_task)
      find("label[for=disposition_dismissed]").click
      fill_in("instructions", with: judge_notes)
      fill_in("hyperlink", with: hyperlink)

      # Ensure we don't show attorney selection for this disposition
      expect(page).not_to have_selector("input#attorney")

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
      new_task = DismissedMotionToVacateTask.find_by(assigned_to: motions_attorney)
      expect(new_task).to_not be_nil
      expect(new_task.label).to eq COPY::DISMISSED_MOTION_TO_VACATE_TASK_LABEL
      expect(new_task.available_actions(motions_attorney)).to include(
        Constants.TASK_ACTIONS.LIT_SUPPORT_PULAC_CERULLO.to_h
      )
      expect(new_task.instructions.join("")).to eq(instructions)
    end
  end

  describe "Attorney Completes Motion to Vacate Checkout Task" do
    let(:judge_team) { JudgeTeam.create_for_judge(judge) }
    let(:drafting_attorney) { create(:user, full_name: "Drafty McDrafter") }
    let!(:attorney_staff) { create(:staff, :attorney_role, sdomainid: drafting_attorney.css_id) }

    let(:orig_atty_task) do
      create(:ama_attorney_task, :completed,
             assigned_to: drafting_attorney, appeal: appeal, created_at: receipt_date + 1.day, parent: root_task)
    end
    let(:judge_review_task) do
      create(:ama_judge_decision_review_task, :completed,
             assigned_to: judge, appeal: appeal, created_at: receipt_date + 3.days, parent: root_task)
    end
    let(:vacate_motion_mail_task) do
      create(:vacate_motion_mail_task, appeal: appeal, assigned_to: motions_attorney, parent: root_task)
    end
    let(:judge_address_motion_to_vacate_task) do
      create(:judge_address_motion_to_vacate_task,
             appeal: appeal,
             assigned_to: judge,
             parent: vacate_motion_mail_task)
    end
    let(:abstract_motion_to_vacate_task) do
      create(:abstract_motion_to_vacate_task, appeal: appeal, parent: vacate_motion_mail_task)
    end

    let(:vacate_type) { "straight_vacate" }

    let(:post_decision_motion_params) do
      {
        instructions: "I am granting this",
        disposition: "granted",
        vacate_type: vacate_type,
        assigned_to_id: drafting_attorney
      }
    end
    let(:post_decision_motion_updater) do
      PostDecisionMotionUpdater.new(judge_address_motion_to_vacate_task, post_decision_motion_params)
    end
    let!(:post_decision_motion) { post_decision_motion_updater.process }
    let(:vacate_stream) { Appeal.find_by(stream_docket_number: appeal.docket_number, stream_type: "vacate") }
    let(:attorney_task) { AttorneyTask.find_by(assigned_to: drafting_attorney) }

    let(:review_decisions_path) do
      [
        "/queue/appeals/#{vacate_stream.uuid}/tasks/#{attorney_task.id}",
        "motion_to_vacate_checkout/review_vacatures"
      ].join("/")
    end

    let(:add_decisions_path) do
      [
        "/queue/appeals/#{vacate_stream.uuid}/tasks/#{attorney_task.id}",
        "motion_to_vacate_checkout/add_decisions"
      ].join("/")
    end

    let(:submit_decisions_path) do
      [
        "/queue/appeals/#{vacate_stream.uuid}/tasks/#{attorney_task.id}",
        "motion_to_vacate_checkout/submit"
      ].join("/")
    end

    before do
      judge_team.add_user(drafting_attorney)
      FeatureToggle.enable!(:review_motion_to_vacate)

      judge_address_motion_to_vacate_task.update(status: Constants.TASK_STATUSES.completed)
    end

    after { FeatureToggle.disable!(:review_motion_to_vacate) }

    context "Straight Vacate" do
      let(:vacate_type) { "straight_vacate" }

      it "correctly handles checkout flow" do
        User.authenticate!(user: drafting_attorney)

        visit "/queue/appeals/#{vacate_stream.uuid}"

        find(".Select-placeholder", text: COPY::TASK_ACTION_DROPDOWN_BOX_LABEL).click
        find("div", class: "Select-option", text: Constants.TASK_ACTIONS.REVIEW_VACATE_DECISION.label).click

        expect(page.current_path).to eq(review_decisions_path)

        expect(page).to have_css(".cf-progress-bar-activated", text: "1. Review Vacated Decision Issues")
        expect(page).to have_css(".cf-progress-bar-not-activated", text: "2. Submit Draft Decision for Review")

        safe_click "#button-next-button"

        expect(page.current_path).to eq(submit_decisions_path)

        safe_click "#button-back-button"

        expect(page.current_path).to eq(review_decisions_path)

        safe_click "#button-next-button"

        expect(page.current_path).to eq(submit_decisions_path)

        expect(page).to have_css(".cf-progress-bar-activated", text: "1. Review Vacated Decision Issues")
        expect(page).to have_css(".cf-progress-bar-activated", text: "2. Submit Draft Decision for Review")

        expect(page).to have_content("Submit Draft Decision for Review")
        fill_in "Document ID:", with: valid_document_id
        expect(page).to have_content(judge.full_name)
        fill_in "notes", with: "all done"

        click_on "Continue"

        expect(page).to have_content(
          "Thank you for drafting #{appeal.veteran_full_name}'s decision. It's been "\
          "sent to #{judge.full_name} for review."
        )
      end
    end

    context "Vacate & Readjudicate" do
      let(:vacate_type) { "vacate_and_readjudication" }

      it "correctly handles checkout flow" do
        User.authenticate!(user: drafting_attorney)

        visit "/queue/appeals/#{vacate_stream.uuid}"

        find(".Select-placeholder", text: COPY::TASK_ACTION_DROPDOWN_BOX_LABEL).click
        find("div", class: "Select-option", text: Constants.TASK_ACTIONS.REVIEW_VACATE_DECISION.label).click

        expect(page.current_path).to eq(review_decisions_path)

        expect(page).to have_css(".cf-progress-bar-activated", text: "1. Review Vacated Decision Issues")
        expect(page).to have_css(".cf-progress-bar-not-activated", text: "2. Add Decisions")
        expect(page).to have_css(".cf-progress-bar-not-activated", text: "3. Submit Draft Decision for Review")

        safe_click "#button-next-button"

        expect(page.current_path).to eq(add_decisions_path)

        safe_click "#button-back-button"

        expect(page.current_path).to eq(review_decisions_path)

        safe_click "#button-next-button"

        expect(page.current_path).to eq(add_decisions_path)

        expect(page).to have_css(".cf-progress-bar-activated", text: "1. Review Vacated Decision Issues")
        expect(page).to have_css(".cf-progress-bar-activated", text: "2. Add Decisions")
        expect(page).to have_css(".cf-progress-bar-not-activated", text: "3. Submit Draft Decision for Review")

        # Add a first decision issue
        all("button", text: "+ Add decision", count: 3)[0].click
        expect(page).to have_content COPY::DECISION_ISSUE_MODAL_TITLE

        fill_in "Text Box", with: "test"

        find(".Select-control", text: "Select disposition").click
        find("div", class: "Select-option", text: "Allowed").click

        click_on "Add Issue"

        safe_click "#button-next-button"

        expect(page.current_path).to eq(submit_decisions_path)

        safe_click "#button-back-button"

        expect(page.current_path).to eq(add_decisions_path)

        safe_click "#button-next-button"

        expect(page.current_path).to eq(submit_decisions_path)

        expect(page).to have_content("Submit Draft Decision for Review")

        expect(page).to have_css(".cf-progress-bar-activated", text: "1. Review Vacated Decision Issues")
        expect(page).to have_css(".cf-progress-bar-activated", text: "2. Add Decisions")
        expect(page).to have_css(".cf-progress-bar-activated", text: "3. Submit Draft Decision for Review")

        fill_in "Document ID:", with: valid_document_id
        expect(page).to have_content(judge.full_name)
        fill_in "notes", with: "all done"

        click_on "Continue"

        expect(page).to have_content(
          "Thank you for drafting #{appeal.veteran_full_name}'s decision. It's been "\
          "sent to #{judge.full_name} for review."
        )
      end
    end
  end

  describe "Attorney Completes Denied / Dismissed Motion to Vacate Task" do
    let(:judge_team) { JudgeTeam.create_for_judge(judge) }
    let(:drafting_attorney) { create(:user, full_name: "Drafty McDrafter") }

    let(:orig_atty_task) do
      create(:ama_attorney_task, :completed,
             assigned_to: drafting_attorney, appeal: appeal, created_at: receipt_date + 1.day, parent: root_task)
    end
    let(:judge_review_task) do
      create(:ama_judge_decision_review_task, :completed,
             assigned_to: judge, appeal: appeal, created_at: receipt_date + 3.days, parent: root_task)
    end
    let(:vacate_motion_mail_task) do
      create(:vacate_motion_mail_task, appeal: appeal, assigned_to: motions_attorney, parent: root_task)
    end
    let(:judge_address_motion_to_vacate_task) do
      create(:judge_address_motion_to_vacate_task, appeal: appeal, assigned_to: judge, parent: vacate_motion_mail_task)
    end
    let(:abstract_motion_to_vacate_task) do
      create(:abstract_motion_to_vacate_task, appeal: appeal, parent: vacate_motion_mail_task)
    end
    let(:denied_motion_to_vacate_task) do
      create(
        :denied_motion_to_vacate_task,
        appeal: appeal,
        assigned_by: judge,
        assigned_to: motions_attorney,
        parent: abstract_motion_to_vacate_task
      )
    end
    let(:dismissed_motion_to_vacate_task) do
      create(
        :dismissed_motion_to_vacate_task,
        appeal: appeal,
        assigned_by: judge,
        assigned_to: motions_attorney,
        parent: abstract_motion_to_vacate_task
      )
    end

    before do
      lit_support_team.add_user(motions_attorney)
      FeatureToggle.enable!(:review_motion_to_vacate)

      judge_address_motion_to_vacate_task.update(status: Constants.TASK_STATUSES.completed)
    end

    after { FeatureToggle.disable!(:review_motion_to_vacate) }

    it "completes MTV workflow for denied disposition and closes relevant tasks" do
      complete_motion_to_vacate(user: motions_attorney, appeal: appeal, task: denied_motion_to_vacate_task)
    end

    it "completes MTV workflow for dismissed disposition and closes relevant tasks" do
      complete_motion_to_vacate(user: motions_attorney, appeal: appeal, task: dismissed_motion_to_vacate_task)
    end
  end

  def visit_vacate_stream
    vacate_stream = Appeal.find_by(stream_docket_number: appeal.docket_number, stream_type: "vacate")
    visit "/queue/appeals/#{vacate_stream.uuid}"
    expect(page).to have_content("Vacate")
  end

  def send_to_judge(user:, appeal:, motions_attorney_task:)
    User.authenticate!(user: user)
    visit "/queue/appeals/#{appeal.uuid}"

    check_cavc_alert
    verify_cavc_conflict_action

    find(".Select-placeholder", text: COPY::TASK_ACTION_DROPDOWN_BOX_LABEL).click
    find("div", class: "Select-option", text: "Send to judge").click
    expect(page.current_path).to eq("/queue/appeals/#{appeal.uuid}/tasks/#{motions_attorney_task.id}/send_to_judge")
  end

  def address_motion_to_vacate(user:, appeal:, judge_task:)
    User.authenticate!(user: user)
    visit "/queue/appeals/#{appeal.uuid}"

    check_cavc_alert
    verify_cavc_conflict_action

    find(".Select-placeholder", text: COPY::TASK_ACTION_DROPDOWN_BOX_LABEL).click
    find("div", class: "Select-option", text: "Address Motion to Vacate").click
    expect(page.current_path).to eq("/queue/appeals/#{appeal.uuid}/tasks/#{judge_task.id}/address_motion_to_vacate")
  end

  def judge_send_to_dispatch(user:, appeal:)
    User.authenticate!(user: user)
    visit "/queue/appeals/#{appeal.uuid}"

    check_cavc_alert
    verify_cavc_conflict_action

    find(".Select-placeholder", text: COPY::TASK_ACTION_DROPDOWN_BOX_LABEL).click
    find("div", class: "Select-option", text: "Ready for Dispatch").click
  end

  def complete_motion_to_vacate(user:, appeal:, task:)
    User.authenticate!(user: user)
    visit "/queue/appeals/#{appeal.uuid}"

    find(".Select-placeholder", text: COPY::TASK_ACTION_DROPDOWN_BOX_LABEL).click
    find("div", class: "Select-option", text: Constants.TASK_ACTIONS.MARK_COMPLETE.label).click

    expect(page.current_path).to eq("/queue/appeals/#{appeal.uuid}/tasks/#{task.id}/modal/mark_task_complete")

    click_on "Mark complete"

    expect(page).to have_content(format(COPY::MARK_TASK_COMPLETE_CONFIRMATION_DETAIL, task.completion_contact))

    expect(task.reload.status).to eq Constants.TASK_STATUSES.completed

    org_task = task.reload.parent
    expect(org_task.status).to eq Constants.TASK_STATUSES.completed

    expect(abstract_motion_to_vacate_task.reload.status).to eq Constants.TASK_STATUSES.completed
    expect(vacate_motion_mail_task.reload.status).to eq Constants.TASK_STATUSES.completed
  end

  def check_cavc_alert
    expect(page).to have_css(".usa-alert-warning")
    alert = find(".usa-alert-warning")
    expect(alert).to have_content("Check CAVC for conflict of jurisdiction")
  end

  def verify_cavc_conflict_action
    # Open dropdown
    action_dropdown = find(".Select-placeholder", text: COPY::TASK_ACTION_DROPDOWN_BOX_LABEL).click
    expect(page).to have_content(Constants.TASK_ACTIONS.LIT_SUPPORT_PULAC_CERULLO.label)
    # Close dropdown
    action_dropdown.click
  end

  def select_issue_for_vacature(issue_id)
    find(".checkbox-wrapper-issues").find("label[for=\"#{issue_id}\"]").click
  end

  def valid_document_id
    "12345-12345678"
  end
end
