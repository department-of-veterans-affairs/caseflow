# frozen_string_literal: true

RSpec.feature "Motion to vacate", :all_dbs do
  include QueueHelpers

  let!(:lit_support_team) { LitigationSupport.singleton }
  let(:colocated_org) { Colocated.singleton }
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
  let!(:root_task) { create(:root_task, :completed, appeal: appeal) }
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

    let(:atty_disposition) { "granted" }
    let(:atty_notes) { "Here is some context from Attorney to the judge" }
    let(:atty_hyperlinks) { generate_atty_hyperlinks(atty_disposition) }
    let(:atty_instructions) do
      format_mtv_attorney_instructions(
        notes: atty_notes,
        disposition: atty_disposition,
        hyperlinks: atty_hyperlinks
      )
    end

    before do
      create(:staff, :judge_role, sdomainid: judge2.css_id)
      create(:staff, :judge_role, sdomainid: judge3.css_id)
      mail_team.add_user(mail_user)
      lit_support_team.add_user(lit_support_user)
      FeatureToggle.enable!(:review_motion_to_vacate)
    end

    after { FeatureToggle.disable!(:review_motion_to_vacate) }

    context "When the appeal is not outcoded" do
      let!(:root_task) { create(:root_task, appeal: appeal) }

      it "does not show option to create a VacateMotionMailTask" do
        User.authenticate!(user: mail_user)
        visit "/queue/appeals/#{appeal.uuid}"
        find("button", text: COPY::TASK_SNAPSHOT_ADD_NEW_TASK_LABEL).click
        find(".cf-select__control", text: COPY::MAIL_TASK_DROPDOWN_TYPE_SELECTOR_LABEL).click
        expect(page).to have_content(COPY::ADDRESS_CHANGE_MAIL_TASK_LABEL)
        expect(page).to_not have_content(COPY::VACATE_MOTION_MAIL_TASK_LABEL)
      end
    end

    it "gets assigned to Litigation Support" do
      # When mail team creates VacateMotionMailTask, it gets assigned to the lit support organization
      User.authenticate!(user: mail_user)
      visit "/queue/appeals/#{appeal.uuid}"
      find("button", text: COPY::TASK_SNAPSHOT_ADD_NEW_TASK_LABEL).click
      find(".cf-select__control", text: COPY::MAIL_TASK_DROPDOWN_TYPE_SELECTOR_LABEL).click
      find("div", class: "cf-select__option", text: COPY::VACATE_MOTION_MAIL_TASK_LABEL).click
      fill_in("taskInstructions", with: "Instructions for motion to vacate mail task")
      find("button", text: "Submit").click
      expect(page).to have_content("Created Motion to vacate task")
      expect(VacateMotionMailTask.find_by(assigned_to: lit_support_team)).to_not be_nil

      # Lit support user can assign task to a motions attorney
      User.authenticate!(user: lit_support_user)
      visit "/queue/appeals/#{appeal.uuid}"
      find(".cf-select__control", text: COPY::TASK_ACTION_DROPDOWN_BOX_LABEL).click
      find("div", class: "cf-select__option", text: "Assign to person").click
      find(".cf-modal .cf-select__control").click
      find("div", class: "cf-select__option", text: "Motions attorney").click
      click_button(text: "Submit")
      expect(page).to have_content("Task assigned to Motions attorney")
      motions_attorney_task = VacateMotionMailTask.find_by(assigned_to: motions_attorney)
      expect(motions_attorney_task).to_not be_nil

      # Motions attorney can send to judge
      User.authenticate!(user: motions_attorney)
      visit "/queue/appeals/#{appeal.uuid}"
      find(".cf-select__control", text: COPY::TASK_ACTION_DROPDOWN_BOX_LABEL).click
      find("div", class: "cf-select__option", text: "Send to judge").click
      expect(page.current_path).to eq("/queue/appeals/#{appeal.uuid}/tasks/#{motions_attorney_task.id}/send_to_judge")
    end

    context "motions attorney reviews case" do
      let!(:motions_attorney_task) do
        create(:vacate_motion_mail_task, assigned_to: motions_attorney, parent: root_task)
      end

      context "recommends a disposition of granted" do
        let(:atty_disposition) { "granted" }

        it "processes correctly" do
          send_to_judge(user: motions_attorney, appeal: appeal, motions_attorney_task: motions_attorney_task)

          find("label[for=disposition_granted]").click
          fill_in("instructions", with: atty_notes)

          fill_in("motionFile", with: atty_hyperlinks[0][:link])

          # verify hyperlink modal works
          check_hyperlink_modal

          fill_and_check_other_hyperlinks(atty_hyperlinks)

          # Ensure it has pre-selected judge previously assigned to case
          expect(dropdown_selected_value(find(".dropdown-judge"))).to eq judge2.display_name

          task = submit_and_fetch_task(judge2)
          expect(task.instructions.first).to include("I recommend granting a vacatur")
          expect(task[:instructions]).to eq [atty_instructions]
        end
      end

      context "recommends a partial vacatur" do
        let(:atty_disposition) { "partially_granted" }

        it "processes correctly" do
          send_to_judge(user: motions_attorney, appeal: appeal, motions_attorney_task: motions_attorney_task)

          find("label[for=disposition_partially_granted]").click
          fill_in("instructions", with: atty_notes)

          fill_in("motionFile", with: atty_hyperlinks[0][:link])

          fill_and_check_other_hyperlinks(atty_hyperlinks)

          # Ensure it has pre-selected judge previously assigned to case
          expect(dropdown_selected_value(find(".dropdown-judge"))).to eq judge2.display_name

          task = submit_and_fetch_task(judge2)
          expect(task.instructions.first).to include("I recommend granting a partial vacatur")
          expect(task[:instructions]).to eq [atty_instructions]
        end
      end

      context "recommends a denial of vacatur" do
        let(:atty_disposition) { "denied" }

        it "processes correctly" do
          send_to_judge(user: motions_attorney, appeal: appeal, motions_attorney_task: motions_attorney_task)
          find("label[for=disposition_denied]").click
          expect(page).to have_content("Optional")

          fill_in("instructions", with: atty_notes)

          fill_in("decisionDraft", with: atty_hyperlinks[1][:link])

          fill_in("motionFile", with: atty_hyperlinks[0][:link])

          fill_and_check_other_hyperlinks(atty_hyperlinks)

          click_dropdown(text: judge2.display_name)

          task = submit_and_fetch_task(judge2)
          expect(task.instructions.first).to include("I recommend denial")
          expect(task[:instructions]).to eq [atty_instructions]
        end
      end

      it "motions attorney triggers Pulac-Cerullo" do
        User.authenticate!(user: motions_attorney)
        visit "/queue/appeals/#{appeal.uuid}"

        find(".cf-select__control", text: COPY::TASK_ACTION_DROPDOWN_BOX_LABEL).click
        find("div", class: "cf-select__option", text: Constants.TASK_ACTIONS.LIT_SUPPORT_PULAC_CERULLO.label).click
        expect(page).to have_content(COPY::PULAC_CERULLO_MODAL_TITLE)
        expect(page).to have_content(COPY::PULAC_CERULLO_MODAL_BODY_1)
        expect(page).to have_content(COPY::PULAC_CERULLO_MODAL_BODY_2)
        find("button", class: "usa-button", text: "Notify").click

        expect(page).to have_content(COPY::PULAC_CERULLO_SUCCESS_TITLE)
        expect(page).to have_content(COPY::PULAC_CERULLO_SUCCESS_DETAIL.gsub("%s", appeal.veteran_full_name))
      end

      def submit_and_fetch_task(judge)
        click_button(text: "Submit")

        # Return back to user's queue
        expect(page).to have_current_path("/queue")

        expect(page).to have_content(format(COPY::MOTIONS_ATTORNEY_REVIEW_MTV_SUCCESS_TITLE, judge.display_name))
        expect(page).to have_content(COPY::MOTIONS_ATTORNEY_REVIEW_MTV_SUCCESS_DETAIL)

        # Verify new task was created
        judge_task = JudgeAddressMotionToVacateTask.find_by(assigned_to: judge)
        expect(judge_task).to_not be_nil
        judge_task
      end
    end
  end

  describe "JudgeAddressMotionToVacateTask" do
    let(:judge_team) { JudgeTeam.create_for_judge(judge) }
    let(:drafting_attorney) { create(:user, full_name: "Drafty McDrafter") }

    let!(:orig_atty_task) do
      create(:ama_attorney_task, :completed,
             assigned_to: drafting_attorney, appeal: appeal, created_at: receipt_date + 1.day, parent: root_task)
    end
    let(:judge_review_task) do
      create(:ama_judge_decision_review_task, :completed,
             assigned_to: judge, appeal: appeal, created_at: receipt_date + 3.days, parent: root_task)
    end
    let(:vacate_motion_mail_task) do
      create(:vacate_motion_mail_task,
             appeal: appeal,
             assigned_to: motions_attorney,
             parent: root_task,
             instructions: ["Initial instructions"])
    end
    let(:atty_notes) { "Notes from attorney" }
    let(:atty_disposition) { "granted" }
    let(:atty_hyperlinks) { generate_atty_hyperlinks(atty_disposition) }
    let(:atty_instructions) do
      format_mtv_attorney_instructions(
        notes: atty_notes,
        disposition: atty_disposition,
        hyperlinks: atty_hyperlinks
      )
    end
    let(:judge_address_motion_to_vacate_task) do
      create(:judge_address_motion_to_vacate_task,
             appeal: appeal,
             assigned_to: judge,
             assigned_at: Time.zone.now,
             instructions: [atty_instructions],
             parent: vacate_motion_mail_task)
    end
    let(:atty_option_txt) { "#{drafting_attorney.full_name} (Orig. Attorney)" }
    let(:judge_notes) { "Here's why I made my decision..." }
    let(:return_to_lit_support_instructions) { "\n\nYou forgot the decision draft" }

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
      # Ensure the task exists
      judge_address_motion_to_vacate_task.reload

      User.authenticate!(user: judge)
      visit "/queue"
      expect(page).to have_content(COPY::JUDGE_ADDRESS_MOTION_TO_VACATE_TASK_LABEL)
    end

    it "judge grants motion to vacate (vacate & readjudication)" do
      # Ensure the task exists
      judge_address_motion_to_vacate_task.reload

      address_motion_to_vacate(user: judge, appeal: appeal, judge_task: judge_address_motion_to_vacate_task)
      find("label[for=disposition_granted]").click
      find("label[for=vacate-type_vacate_and_readjudication]").click
      fill_in("instructions", with: judge_notes)

      # Ensure it has pre-selected attorney previously assigned to case
      expect(dropdown_selected_value(find(".dropdown-attorney"))).to eq atty_option_txt

      click_button(text: "Submit")

      # Return back to user's queue
      expect(page).to have_current_path("/queue")
      expect(page).to have_content(format(COPY::JUDGE_ADDRESS_MTV_SUCCESS_TITLE_GRANTED, appeal.veteran_full_name))
      expect(page).to have_content(COPY::JUDGE_ADDRESS_MTV_SUCCESS_DETAIL_GRANTED)

      # Verify PostDecisionMotion is created
      motion = PostDecisionMotion.find_by(task: judge_address_motion_to_vacate_task)
      expect(motion).to_not be_nil
      expect(motion.disposition).to eq("granted")

      visit_vacate_stream
    end

    it "judge grants motion to vacate (straight vacate)" do
      # Ensure the task exists
      judge_address_motion_to_vacate_task.reload

      address_motion_to_vacate(user: judge, appeal: appeal, judge_task: judge_address_motion_to_vacate_task)
      find("label[for=disposition_granted]").click
      find("label[for=vacate-type_straight_vacate]").click
      fill_in("instructions", with: judge_notes)

      # Ensure it has pre-selected attorney previously assigned to case
      expect(dropdown_selected_value(find(".dropdown-attorney"))).to eq atty_option_txt

      click_button(text: "Submit")

      # Return back to user's queue
      expect(page).to have_current_path("/queue")
      expect(page).to have_content(format(COPY::JUDGE_ADDRESS_MTV_SUCCESS_TITLE_GRANTED, appeal.veteran_full_name))
      expect(page).to have_content(COPY::JUDGE_ADDRESS_MTV_SUCCESS_DETAIL_GRANTED)

      # Verify PostDecisionMotion is created
      motion = PostDecisionMotion.find_by(task: judge_address_motion_to_vacate_task)
      expect(motion).to_not be_nil
      expect(motion.disposition).to eq("granted")

      visit_vacate_stream
    end

    it "judge grants motion to vacate (vacate & de novo)" do
      # Ensure the task exists
      judge_address_motion_to_vacate_task.reload

      address_motion_to_vacate(user: judge, appeal: appeal, judge_task: judge_address_motion_to_vacate_task)
      find("label[for=disposition_granted]").click
      find("label[for=vacate-type_vacate_and_de_novo]").click
      fill_in("instructions", with: judge_notes)

      # Ensure it has pre-selected attorney previously assigned to case
      expect(dropdown_selected_value(find(".dropdown-attorney"))).to eq atty_option_txt

      click_button(text: "Submit")

      # Return back to user's queue
      expect(page).to have_current_path("/queue")
      expect(page).to have_content(format(COPY::JUDGE_ADDRESS_MTV_SUCCESS_TITLE_GRANTED, appeal.veteran_full_name))
      expect(page).to have_content(COPY::JUDGE_ADDRESS_MTV_SUCCESS_DETAIL_GRANTED)

      # Verify PostDecisionMotion is created
      motion = PostDecisionMotion.find_by(task: judge_address_motion_to_vacate_task)
      expect(motion).to_not be_nil
      expect(motion.disposition).to eq("granted")
      expect(motion.vacated_decision_issue_ids.length).to eq(appeal.decision_issues.length)
      expect(motion.vacated_decision_issue_ids).to include(*appeal.decision_issues.map(&:id))

      visit_vacate_stream
    end

    it "judge grants partial vacatur (vacate & readjudication)" do
      # Ensure the task exists
      judge_address_motion_to_vacate_task.reload

      address_motion_to_vacate(user: judge, appeal: appeal, judge_task: judge_address_motion_to_vacate_task)
      find("label[for=disposition_partially_granted]").click
      find("label[for=vacate-type_vacate_and_readjudication]").click
      fill_in("instructions", with: judge_notes)

      # Ensure it has pre-selected attorney previously assigned to case
      expect(dropdown_selected_value(find(".dropdown-attorney"))).to eq atty_option_txt

      issues_to_select = [1, 3]
      issues_to_select.each { |idx| select_issue_for_vacatur(idx) }

      click_button(text: "Submit")

      # Return back to user's queue
      expect(page).to have_current_path("/queue")
      expect(page).to have_content(format(COPY::JUDGE_ADDRESS_MTV_SUCCESS_TITLE_GRANTED, appeal.veteran_full_name))
      expect(page).to have_content(COPY::JUDGE_ADDRESS_MTV_SUCCESS_DETAIL_GRANTED)

      # Verify PostDecisionMotion is created
      motion = PostDecisionMotion.find_by(task: judge_address_motion_to_vacate_task)
      expect(motion).to_not be_nil
      expect(motion.disposition).to eq("partially_granted")
      expect(motion.decision_issues_for_vacatur.length).to eq(issues_to_select.length)

      visit_vacate_stream
    end

    context "denial" do
      let(:atty_disposition) { "denied" }
      let(:atty_hyperlink) { "https://efolder.link/file" }

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
        expect(page).to have_content(
          format(COPY::JUDGE_ADDRESS_MTV_SUCCESS_TITLE_DENIED, appeal.veteran_full_name, "denied")
        )
        expect(page).to have_content(COPY::JUDGE_ADDRESS_MTV_SUCCESS_DETAIL_DENIED)

        # Verify PostDecisionMotion is created
        motion = PostDecisionMotion.find_by(task: judge_address_motion_to_vacate_task)
        expect(motion).to_not be_nil
        expect(motion.disposition).to eq("denied")

        # Verify new task creation
        instructions = format_mtv_judge_instructions(
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
    end

    context "dismissal" do
      let(:atty_disposition) { "dismissed" }
      let(:atty_hyperlink) { "https://efolder.link/file" }

      it "judge dismisses motion to vacate" do
        address_motion_to_vacate(user: judge, appeal: appeal, judge_task: judge_address_motion_to_vacate_task)
        find("label[for=disposition_dismissed]").click
        expect(page).to have_content("Optional")
        expect(page).to have_content(
          format(COPY::JUDGE_ADDRESS_MTV_HYPERLINK_LABEL, "dismissal")
        )
        fill_in("instructions", with: judge_notes)
        fill_in("hyperlink", with: hyperlink)

        # Ensure we don't show attorney selection for this disposition
        expect(page).not_to have_selector("input#attorney")

        click_button(text: "Submit")

        # Return back to user's queue
        expect(page).to have_current_path("/queue")
        expect(page).to have_content(
          format(COPY::JUDGE_ADDRESS_MTV_SUCCESS_TITLE_DENIED, appeal.veteran_full_name, "dismissed")
        )
        expect(page).to have_content(COPY::JUDGE_ADDRESS_MTV_SUCCESS_DETAIL_DENIED)

        # Verify PostDecisionMotion is created; should ultimately also check new tasks
        motion = PostDecisionMotion.find_by(task: judge_address_motion_to_vacate_task)
        expect(motion).to_not be_nil
        expect(motion.disposition).to eq("dismissed")

        # Verify new task creation
        instructions = format_mtv_judge_instructions(
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

    describe "judge returns case to lit support" do
      context "disposition: granted" do
        let(:disposition) { "granted" }

        it "allows proper return to lit support" do
          return_to_lit_support(disposition: disposition)
        end
      end

      context "disposition: denied" do
        let(:disposition) { "denied" }

        it "allows proper return to lit support" do
          return_to_lit_support(disposition: disposition)
        end
      end

      def return_to_lit_support(disposition:)
        address_motion_to_vacate(user: judge, appeal: appeal, judge_task: judge_address_motion_to_vacate_task)
        find("label[for=disposition_#{disposition}]").click

        find("a", text: "return to the motions attorney").click

        expect(page).to have_content(COPY::RETURN_TO_LIT_SUPPORT_MODAL_TITLE)
        expect(page).to have_content(COPY::RETURN_TO_LIT_SUPPORT_MODAL_DEFAULT_INSTRUCTIONS)
        find("div.cf-modal-body").fill_in("instructions",
                                          with: return_to_lit_support_instructions,
                                          fill_options: { clear: :none })

        click_button(text: "Submit")

        # Return back to user's queue
        expect(page).to have_current_path("/queue")
        expect(page).to have_content(
          format(COPY::RETURN_TO_LIT_SUPPORT_SUCCESS_TITLE, appeal.veteran_full_name)
        )
        expect(page).to have_content(COPY::RETURN_TO_LIT_SUPPORT_SUCCESS_DETAIL)

        motion = PostDecisionMotion.find_by(task: judge_address_motion_to_vacate_task)
        expect(motion).to be_nil

        expect(judge_address_motion_to_vacate_task.reload.status).to eq Constants.TASK_STATUSES.cancelled

        expect(vacate_motion_mail_task.reload.status).to eq Constants.TASK_STATUSES.assigned
        expect(vacate_motion_mail_task.instructions.length).to eq 2

        expected_instructions = COPY::RETURN_TO_LIT_SUPPORT_MODAL_DEFAULT_INSTRUCTIONS +
                                return_to_lit_support_instructions
        expect(vacate_motion_mail_task.instructions).to include(expected_instructions)
      end
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
      create(:vacate_motion_mail_task, assigned_to: motions_attorney, parent: root_task)
    end
    let(:judge_address_motion_to_vacate_task) do
      create(:judge_address_motion_to_vacate_task,
             appeal: appeal,
             assigned_to: judge,
             parent: vacate_motion_mail_task)
    end
    let(:abstract_motion_to_vacate_task) do
      create(:abstract_motion_to_vacate_task, parent: vacate_motion_mail_task)
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
    let(:vacate_stream) do
      Appeal.find_by(stream_docket_number: appeal.docket_number, stream_type: Constants.AMA_STREAM_TYPES.vacate)
    end
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

    let(:remand_reasons_path) do
      [
        "/queue/appeals/#{vacate_stream.uuid}/tasks/#{attorney_task.id}",
        "motion_to_vacate_checkout/remand_reasons"
      ].join("/")
    end

    let(:admin_actions_path) do
      [
        "/queue/appeals/#{vacate_stream.uuid}/tasks/#{attorney_task.id}",
        "motion_to_vacate_checkout/admin_actions"
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

        check_cavc_alert
        verify_cavc_conflict_action

        find(".cf-select__control", text: COPY::TASK_ACTION_DROPDOWN_BOX_LABEL).click
        find("div", class: "cf-select__option", text: Constants.TASK_ACTIONS.REVIEW_VACATE_DECISION.label).click

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
        click_on "Submit"

        expect(page).to have_content(
          "Thank you for drafting #{appeal.veteran_full_name}'s decision. It's been "\
          "sent to #{judge.full_name} for review."
        )
      end

      it "correctly handles return to judge" do
        User.authenticate!(user: drafting_attorney)

        visit "/queue/appeals/#{vacate_stream.uuid}"

        check_cavc_alert
        verify_cavc_conflict_action

        expect(PostDecisionMotion.all.size).to eq(1)
        expect(JudgeAddressMotionToVacateTask.all.size).to eq(1)

        find(".cf-select__control", text: COPY::TASK_ACTION_DROPDOWN_BOX_LABEL).click
        find("div", class: "cf-select__option", text: Constants.TASK_ACTIONS.REVIEW_VACATE_DECISION.label).click

        expect(page.current_path).to eq(review_decisions_path)

        find(".usa-alert-text").find("a").click

        expect(page).to have_content(COPY::MTV_CHECKOUT_RETURN_TO_JUDGE_MODAL_TITLE)
        expect(page).to have_content(COPY::MTV_CHECKOUT_RETURN_TO_JUDGE_MODAL_DESCRIPTION)

        fill_in("instructions", with: "Context for the return to judge")
        find("button", text: "Submit").click

        # Return back to user's queue
        expect(page).to have_current_path("/queue")
        expect(page).to have_content(
          format(
            COPY::MTV_CHECKOUT_RETURN_TO_JUDGE_SUCCESS_TITLE, appeal.veteran_full_name, judge.full_name
          )
        )
        expect(page).to have_content(COPY::MTV_CHECKOUT_RETURN_TO_JUDGE_SUCCESS_DETAILS)

        expect(PostDecisionMotion.all.size).to eq(0)
        expect(JudgeAddressMotionToVacateTask.all.size).to eq(2)
        expect { vacate_stream.reload }.to raise_error ActiveRecord::RecordNotFound
      end
    end

    context "Vacate & Readjudicate" do
      let(:vacate_type) { "vacate_and_readjudication" }

      context "without remanded decision" do
        it "correctly handles checkout flow" do
          User.authenticate!(user: drafting_attorney)

          visit "/queue/appeals/#{vacate_stream.uuid}"

          check_cavc_alert
          verify_cavc_conflict_action

          find(".cf-select__control", text: COPY::TASK_ACTION_DROPDOWN_BOX_LABEL).click
          find("div", class: "cf-select__option", text: Constants.TASK_ACTIONS.REVIEW_VACATE_DECISION.label).click

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

          find(".cf-select__control", text: "Select disposition").click
          find("div", class: "cf-select__option", text: "Allowed").click

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

          click_on "Submit"

          expect(page).to have_content(
            "Thank you for drafting #{appeal.veteran_full_name}'s decision. It's been "\
            "sent to #{judge.full_name} for review."
          )

          expect(vacate_stream.decision_issues.size).to eq(4)
        end
      end

      context "with remanded decision" do
        it "correctly handles checkout flow" do
          User.authenticate!(user: drafting_attorney)

          visit "/queue/appeals/#{vacate_stream.uuid}"

          check_cavc_alert
          verify_cavc_conflict_action

          find(".cf-select__control", text: COPY::TASK_ACTION_DROPDOWN_BOX_LABEL).click
          find("div", class: "cf-select__option", text: Constants.TASK_ACTIONS.REVIEW_VACATE_DECISION.label).click

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
          add_decision_to_issue(0, "Allowed", "test")

          # Add a remanded decision issue
          add_decision_to_issue(1, "Remanded", "remanded test")
          add_decision_to_issue(2, "Remanded", "remanded test 2")

          # Next should be remand reasons
          safe_click "#button-next-button"

          expect(page.current_path).to eq(remand_reasons_path)
          expect(page).to have_selector(".remand-reasons-form", maximum: 1)

          # Add remand reasons for issue 1
          within all("div.remand-reasons-form")[0] do
            find_field("Service treatment records", visible: false).sibling("label").click
            find_field("Post AOJ", visible: false).sibling("label").click
          end

          safe_click "#button-next-button"

          # Should still be on remand reasons page, but should have added second issue form
          expect(page.current_path).to eq(remand_reasons_path)
          expect(page).to have_selector(".remand-reasons-form", minimum: 2)

          # Add remand reasons for issue 2
          within all("div.remand-reasons-form")[1] do
            find_field("Medical examinations", visible: false).sibling("label").click
            find_field("Pre AOJ", visible: false).sibling("label").click
          end

          safe_click "#button-next-button"

          expect(page.current_path).to eq(submit_decisions_path)

          safe_click "#button-back-button"

          # Going back should return to add_decisions, not remand_reasons

          expect(page.current_path).to eq(add_decisions_path)

          safe_click "#button-next-button"

          expect(page.current_path).to eq(remand_reasons_path)

          # Need to press continue twice, due to two issues
          safe_click "#button-next-button"
          safe_click "#button-next-button"

          expect(page.current_path).to eq(submit_decisions_path)

          expect(page).to have_content("Submit Draft Decision for Review")

          expect(page).to have_css(".cf-progress-bar-activated", text: "1. Review Vacated Decision Issues")
          expect(page).to have_css(".cf-progress-bar-activated", text: "2. Add Decisions")
          expect(page).to have_css(".cf-progress-bar-activated", text: "3. Submit Draft Decision for Review")

          fill_in "Document ID:", with: valid_document_id
          expect(page).to have_content(judge.full_name)
          fill_in "notes", with: "all done"

          click_on "Submit"

          expect(page).to have_content(
            "Thank you for drafting #{appeal.veteran_full_name}'s decision. It's been "\
            "sent to #{judge.full_name} for review."
          )

          expect(vacate_stream.decision_issues.size).to eq(6)

          remanded = vacate_stream.decision_issues.select { |di| di.remanded? }
          remanded1 = remanded.find { |di| di.description.eql? "remanded test" }
          remanded2 = remanded.find { |di| di.description.eql? "remanded test 2" }

          expect(remanded1.remand_reasons.size).to eq(1)
          expect(remanded1.remand_reasons.first).to have_attributes(code: "service_treatment_records")

          expect(remanded2.remand_reasons.size).to eq(1)
          expect(remanded2.remand_reasons.first).to have_attributes(code: "medical_examinations")
        end
      end

      def add_decision_to_issue(idx, disposition, description)
        all("button", text: "+ Add decision", count: 3)[idx].click
        expect(page).to have_content COPY::DECISION_ISSUE_MODAL_TITLE

        fill_in "Text Box", with: description

        find(".cf-select__control", text: "Select disposition").click
        find("div", class: "cf-select__option", text: disposition).click

        click_on "Add Issue"
      end
    end

    context "Vacate & de Novo" do
      let(:vacate_type) { "vacate_and_de_novo" }

      before do
        add_colocated_users
      end

      it "correctly handles checkout flow" do
        User.authenticate!(user: drafting_attorney)

        visit "/queue/appeals/#{vacate_stream.uuid}"

        check_cavc_alert
        verify_cavc_conflict_action

        find(".cf-select__control", text: COPY::TASK_ACTION_DROPDOWN_BOX_LABEL).click
        find("div", class: "cf-select__option", text: Constants.TASK_ACTIONS.REVIEW_VACATE_DECISION.label).click

        expect(page.current_path).to eq(review_decisions_path)

        expect(page).to have_css(".cf-progress-bar-activated", text: "1. Review Vacated Decision Issues")
        expect(page).to have_css(".cf-progress-bar-not-activated", text: "2. Admin Actions")
        expect(page).to have_css(".cf-progress-bar-not-activated", text: "3. Submit Draft Decision for Review")

        safe_click "#button-next-button"

        expect(page.current_path).to eq(admin_actions_path)

        safe_click "#button-back-button"

        expect(page.current_path).to eq(review_decisions_path)

        safe_click "#button-next-button"

        expect(page.current_path).to eq(admin_actions_path)

        expect(page).to have_css(".cf-progress-bar-activated", text: "1. Review Vacated Decision Issues")
        expect(page).to have_css(".cf-progress-bar-activated", text: "2. Admin Actions")
        expect(page).to have_css(".cf-progress-bar-not-activated", text: "3. Submit Draft Decision for Review")

        expect(page).to have_content(COPY::ADD_COLOCATED_TASK_SUBHEAD)

        # step "fills in and submits the form for two identical admin actions"
        action = ColocatedTask.actions_assigned_to_colocated.sample
        action_class = ColocatedTask.find_subclass_by_action(action).name
        selected_opt_0 = Constants::CO_LOCATED_ADMIN_ACTIONS[action]
        instructions = generate_words(5)

        click_dropdown(text: selected_opt_0) do
          visible_options = page.find_all(".cf-select__option")
          expect(visible_options.length).to eq Constants::CO_LOCATED_ADMIN_ACTIONS.length
        end

        fill_in COPY::ADD_COLOCATED_TASK_INSTRUCTIONS_LABEL, with: instructions

        click_on COPY::ADD_COLOCATED_TASK_ANOTHER_BUTTON_LABEL

        expect(all("div.admin-action-item").count).to eq 2

        within all("div.admin-action-item")[1] do
          click_dropdown(text: selected_opt_0)
          fill_in COPY::ADD_COLOCATED_TASK_INSTRUCTIONS_LABEL, with: instructions
        end

        expect(page).to have_content("Duplicate admin actions detected")

        # step "removes the duplicate and submits the form for a new admin action"

        within all("div.admin-action-item")[1] do
          click_on COPY::ADD_COLOCATED_TASK_REMOVE_BUTTON_LABEL
        end

        # Time to move to step 3

        # Verify navigation
        safe_click "#button-next-button"

        expect(page.current_path).to eq(submit_decisions_path)

        safe_click "#button-back-button"

        expect(page.current_path).to eq(admin_actions_path)

        safe_click "#button-next-button"

        expect(page.current_path).to eq(submit_decisions_path)

        expect(page).to have_content("Submit Draft Decision for Review")

        expect(page).to have_css(".cf-progress-bar-activated", text: "1. Review Vacated Decision Issues")
        expect(page).to have_css(".cf-progress-bar-activated", text: "2. Admin Actions")
        expect(page).to have_css(".cf-progress-bar-activated", text: "3. Submit Draft Decision for Review")

        fill_in "Document ID:", with: valid_document_id
        expect(page).to have_content(judge.full_name)
        fill_in "notes", with: "all done"

        click_on "Submit"

        expect(page).to have_content(
          "Thank you for drafting #{appeal.veteran_full_name}'s decision. It's been "\
          "sent to #{judge.full_name} for review."
        )

        judge_task = vacate_stream.tasks.find_by(type: 'JudgeDecisionReviewTask');

        expect(vacate_stream.decision_issues.size).to eq(3)
        expect(vacate_stream.tasks.size).to eq(5)
        expect(vacate_stream.tasks.find { |item| item[:type] == action_class }).to_not be_nil
        expect(judge_task.status).to eq(Constants.TASK_STATUSES.on_hold)
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
      create(:vacate_motion_mail_task, assigned_to: motions_attorney, parent: root_task)
    end
    let(:judge_address_motion_to_vacate_task) do
      create(:judge_address_motion_to_vacate_task, assigned_to: judge, parent: vacate_motion_mail_task)
    end
    let(:abstract_motion_to_vacate_task) do
      create(:abstract_motion_to_vacate_task, parent: vacate_motion_mail_task)
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
    vacate_stream = Appeal.find_by(
      stream_docket_number: appeal.docket_number, stream_type: Constants.AMA_STREAM_TYPES.vacate
    )
    visit "/queue/appeals/#{vacate_stream.uuid}"
    expect(page).to have_content("Vacate")
    find("span", text: "View all cases").click
    expect(find_by_id("table-row-2")).to have_content("Vacate", appeal.docket_number)
  end

  def send_to_judge(user:, appeal:, motions_attorney_task:)
    User.authenticate!(user: user)
    visit "/queue/appeals/#{appeal.uuid}"

    check_cavc_alert
    verify_cavc_conflict_action

    find(".cf-select__control", text: COPY::TASK_ACTION_DROPDOWN_BOX_LABEL).click
    find("div", class: "cf-select__option", text: "Send to judge").click
    expect(page.current_path).to eq("/queue/appeals/#{appeal.uuid}/tasks/#{motions_attorney_task.id}/send_to_judge")
  end

  def address_motion_to_vacate(user:, appeal:, judge_task:)
    User.authenticate!(user: user)
    visit "/queue/appeals/#{appeal.uuid}"

    check_cavc_alert
    verify_cavc_conflict_action

    find(".cf-select__control", text: COPY::TASK_ACTION_DROPDOWN_BOX_LABEL).click
    find("div", class: "cf-select__option", text: "Address Motion to Vacate").click
    expect(page.current_path).to eq("/queue/appeals/#{appeal.uuid}/tasks/#{judge_task.id}/address_motion_to_vacate")
  end

  def judge_send_to_dispatch(user:, appeal:)
    User.authenticate!(user: user)
    visit "/queue/appeals/#{appeal.uuid}"

    check_cavc_alert
    verify_cavc_conflict_action

    find(".cf-select__control", text: COPY::TASK_ACTION_DROPDOWN_BOX_LABEL).click
    find("div", class: "cf-select__option", text: "Ready for Dispatch").click
  end

  def complete_motion_to_vacate(user:, appeal:, task:)
    User.authenticate!(user: user)
    visit "/queue/appeals/#{appeal.uuid}"

    find(".cf-select__control", text: COPY::TASK_ACTION_DROPDOWN_BOX_LABEL).click
    find("div", class: "cf-select__option", text: Constants.TASK_ACTIONS.MARK_COMPLETE.label).click

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
    expect(alert).to have_content(
      [
        "If there is a Notice of Appeal (NOA) on file at the CAVC website,",
        "use the Actions Menu to notify Litigation Support."
      ].join(" ")
    )
  end

  def verify_cavc_conflict_action
    # Open dropdown
    action_dropdown = find(".cf-select__control", text: COPY::TASK_ACTION_DROPDOWN_BOX_LABEL).click
    expect(page).to have_content(Constants.TASK_ACTIONS.LIT_SUPPORT_PULAC_CERULLO.label)
    # Close dropdown
    action_dropdown.click
  end

  def select_issue_for_vacatur(issue_id)
    find(".checkbox-wrapper-issues").find("label[for=\"#{issue_id}\"]").click
  end

  def valid_document_id
    "12345-12345678"
  end

  def add_colocated_users
    create_list(:user, 6).each do |user|
      colocated_org.add_user(user)
    end
  end

  def generate_atty_hyperlinks(disposition)
    [
      {
        type: "draft of the motion",
        link: "https://example.com/motion_file.pdf"
      },
      {
        type: "draft of the %s",
        link: %w[denied dismissed].include?(disposition) ? "https://example.com/decision_draft.pdf" : ""
      },
      {
        type: "Supplementary File 1",
        link: "https://example.com/file1.pdf"
      },
      {
        type: "Supplementary File 2",
        link: "https://example.com/file2.pdf"
      }
    ]
  end

  def check_hyperlink_modal
    click_button(text: "+ Add hyperlink")
    expect(page).to have_content(COPY::MOTIONS_ATTORNEY_REVIEW_MTV_HYPERLINK_MODAL_TITLE)
    expect(page).to have_content(COPY::MOTIONS_ATTORNEY_REVIEW_MTV_HYPERLINK_MODAL_INSTRUCTIONS)
    find("#Add-hyperlink-button-id-0").click
    expect(page).to_not have_content(COPY::MOTIONS_ATTORNEY_REVIEW_MTV_HYPERLINK_MODAL_INSTRUCTIONS)
  end

  def fill_and_check_other_hyperlinks(atty_hyperlinks)
    atty_hyperlinks[2..3].each do |item|
      click_button(text: "+ Add hyperlink")
      fill_in("type", with: item[:type])
      fill_in("link", with: item[:link])
      click_button(text: "Save")
      expect(page).to have_content(item[:type])
      expect(page).to have_content(item[:link])
    end
  end
end
