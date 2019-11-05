# frozen_string_literal: true

require "support/vacols_database_cleaner"
require "rails_helper"

RSpec.feature "ColocatedTask", :all_dbs do
  let(:vlj_support_staff) { create(:user) }

  before { Colocated.singleton.add_user(vlj_support_staff) }

  describe "attorney assigns task to vlj support staff, vlj returns it to attorney after completion" do
    let(:judge_user) { create(:user) }
    let!(:vacols_judge) { create(:staff, :judge_role, sdomainid: judge_user.css_id) }

    let(:attorney_user) { create(:user) }
    let!(:vacols_atty) { create(:staff, :attorney_role, sdomainid: attorney_user.css_id) }

    let(:root_task) { create(:root_task) }
    let(:appeal) { root_task.appeal }

    let!(:atty_task) do
      create(
        :ama_attorney_task,
        appeal: appeal,
        parent: root_task,
        assigned_by: judge_user,
        assigned_to: attorney_user
      )
    end

    it "should return attorney task to active state" do
      # Attorney assigns task to VLJ support staff.
      User.authenticate!(user: attorney_user)
      visit("/queue/appeals/#{appeal.uuid}")

      find(".Select-control", text: "Select an action…").click
      find("div", class: "Select-option", text: Constants.TASK_ACTIONS.ADD_ADMIN_ACTION.to_h[:label]).click

      # Redirected to assign colocated action page
      action = Constants.CO_LOCATED_ADMIN_ACTIONS.poa_clarification
      find(".Select-control", text: "Select an action").click
      find("div", class: "Select-option", text: action).click
      fill_in(COPY::ADD_COLOCATED_TASK_INSTRUCTIONS_LABEL, with: "note")
      find("button", text: COPY::ADD_COLOCATED_TASK_SUBMIT_BUTTON_LABEL).click

      # Redirected to personal queue page. Assignment succeeds.
      expect(page).to have_content("You have assigned an administrative action (#{action})")

      # Visit case details page for VLJ support staff.
      User.authenticate!(user: vlj_support_staff)
      visit("/queue/appeals/#{appeal.uuid}")

      # Return case to attorney.
      find(".Select-control", text: "Select an action…").click
      find("div", class: "Select-option", text: Constants.TASK_ACTIONS.COLOCATED_RETURN_TO_ATTORNEY.to_h[:label]).click
      fill_in("instructions", with: "INSTRUCTIONS FROM VLJ")
      find("button", text: COPY::MARK_TASK_COMPLETE_BUTTON).click

      # Redirected to personal queue page. Return to attorney succeeds.
      expect(page).to have_content(
        format(COPY::MARK_TASK_COMPLETE_CONFIRMATION, appeal.veteran.name.formatted(:readable_full))
      )

      # View attorney personal queue page. Should see appeal in assigned active queue.
      User.authenticate!(user: attorney_user)
      visit("/queue")

      # Click into case details page. Expect to see draft decision option.
      click_on(appeal.veteran.name.formatted(:readable_full))
      # verify that the instructions from the VLJ appear on the case timeline
      scroll_to("#case_timeline-section")
      view_text = COPY::TASK_SNAPSHOT_VIEW_TASK_INSTRUCTIONS_LABEL
      page.find_all("table#case-timeline-table button", text: view_text).each(&:click)
      expect(page).to have_content(
        "INSTRUCTIONS FROM VLJ"
      )
      find(".Select-control", text: "Select an action…").click
      expect(page).to have_content(Constants.TASK_ACTIONS.REVIEW_AMA_DECISION.to_h[:label])

      # ColocatedTask assigned to organization should have status completed.
      expect(atty_task.children.first.status).to eq(Constants.TASK_STATUSES.completed)
    end
  end

  describe "vlj support staff places the task on hold" do
    let(:root_task) { create(:root_task) }
    let(:appeal) { root_task.appeal }
    let(:veteran_name) { appeal.veteran.name.formatted(:readable_full) }

    context "when ColocatedTask is in progress" do
      let(:hold_duration_days) { 15 }
      let!(:colocated_task) do
        create(
          :ama_colocated_task,
          appeal: appeal,
          parent: root_task
        )
      end
      let(:individual_task) { colocated_task.children.first }

      it "is successfully placed on hold" do
        # Visit case details page for VLJ support staff.
        User.authenticate!(user: vlj_support_staff)
        visit("/queue/appeals/#{appeal.uuid}")

        # Attempt to put the task on hold.
        click_dropdown(text: Constants.TASK_ACTIONS.PLACE_TIMED_HOLD.label)

        # Modal appears.
        expect(page).to have_content(Constants.TASK_ACTIONS.PLACE_TIMED_HOLD.label)

        # Attempt to place the task on hold without including notes.
        find(".Select-control", text: COPY::COLOCATED_ACTION_PLACE_HOLD_LENGTH_SELECTOR_LABEL).click
        find("div", class: "Select-option", text: "#{hold_duration_days} days").click
        click_on(COPY::MODAL_SUBMIT_BUTTON)

        # Instructions field is required
        expect(page).to have_content(COPY::FORM_ERROR_FIELD_REQUIRED)

        # Add instructions and try again
        fill_in("instructions", with: "some text")
        click_on(COPY::MODAL_SUBMIT_BUTTON)

        # We should see a success message and remain on the case details page.
        expect(page).to have_content(
          format(COPY::COLOCATED_ACTION_PLACE_HOLD_CONFIRMATION, veteran_name, hold_duration_days)
        )
        expect(page).to have_current_path("/queue/appeals/#{appeal.uuid}")

        # Task snapshot updated with new hold information
        expect(page).to have_content("0 of #{hold_duration_days}")
      end
    end

    context "when ColocatedTask on old-style hold is updated with a later hold expiration date" do
      let(:old_hold_started) { 3.days.ago }
      let(:old_hold_duration_days) { 15 }
      let(:new_hold_duration_days) { 60 }

      let(:colocated_org_task) do
        create(
          :ama_colocated_task,
          appeal: appeal,
          parent: root_task
        )
      end
      let(:colocated_individual_task) { colocated_org_task.children.first }

      before do
        colocated_individual_task.update!(
          status: Constants.TASK_STATUSES.on_hold,
          on_hold_duration: old_hold_duration_days
        )

        # Update the placed_on_hold_at value in a different statement to avoid it being overwritten by set_timestamps.
        colocated_individual_task.update!(placed_on_hold_at: old_hold_started)
      end

      it "wipes out the old hold and updates the task with new hold information" do
        User.authenticate!(user: vlj_support_staff)
        visit("/queue/appeals/#{appeal.uuid}")

        # Confirm old hold information is set.
        expect(colocated_individual_task.status).to eq(Constants.TASK_STATUSES.on_hold)
        expect(colocated_individual_task.calculated_placed_on_hold_at).to eq(old_hold_started)
        expect(colocated_individual_task.calculated_on_hold_duration).to eq(old_hold_duration_days)

        # Place task on hold again.
        click_dropdown(text: Constants.TASK_ACTIONS.PLACE_TIMED_HOLD.label)
        expect(page).to have_content(Constants.TASK_ACTIONS.PLACE_TIMED_HOLD.label)
        click_dropdown(
          prompt: COPY::COLOCATED_ACTION_PLACE_HOLD_LENGTH_SELECTOR_LABEL,
          text: "#{new_hold_duration_days} days"
        )
        fill_in("instructions", with: "some text")
        click_on(COPY::MODAL_SUBMIT_BUTTON)

        expect(page).to have_content(
          format(COPY::COLOCATED_ACTION_PLACE_HOLD_CONFIRMATION, veteran_name, new_hold_duration_days)
        )
        expect(page).to have_current_path("/queue/appeals/#{appeal.uuid}")

        # Task snapshot updated with new hold information
        expect(page).to have_content("0 of #{new_hold_duration_days}")
      end
    end

    context "when ColocatedTask on old-style hold is updated with an earlier hold expiration date" do
      let(:old_hold_started) { 3.days.ago }
      let(:old_hold_duration_days) { 90 }
      let(:new_hold_duration_days) { 45 }

      let(:colocated_org_task) do
        create(
          :ama_colocated_task,
          appeal: appeal,
          parent: root_task
        )
      end
      let(:colocated_individual_task) { colocated_org_task.children.first }

      before do
        colocated_individual_task.update!(
          status: Constants.TASK_STATUSES.on_hold,
          on_hold_duration: old_hold_duration_days
        )

        # Update the placed_on_hold_at value in a different statement to avoid it being overwritten by set_timestamps.
        colocated_individual_task.update!(placed_on_hold_at: old_hold_started)
      end

      it "wipes out the old hold and updates the task with new hold information" do
        User.authenticate!(user: vlj_support_staff)
        visit("/queue/appeals/#{appeal.uuid}")

        # Confirm old hold information is set.
        expect(colocated_individual_task.status).to eq(Constants.TASK_STATUSES.on_hold)
        expect(colocated_individual_task.calculated_placed_on_hold_at).to eq(old_hold_started)
        expect(colocated_individual_task.calculated_on_hold_duration).to eq(old_hold_duration_days)

        # Place task on hold again.
        click_dropdown(text: Constants.TASK_ACTIONS.PLACE_TIMED_HOLD.label)
        expect(page).to have_content(Constants.TASK_ACTIONS.PLACE_TIMED_HOLD.label)
        click_dropdown(
          prompt: COPY::COLOCATED_ACTION_PLACE_HOLD_LENGTH_SELECTOR_LABEL,
          text: "#{new_hold_duration_days} days"
        )
        fill_in("instructions", with: "some text")
        click_on(COPY::MODAL_SUBMIT_BUTTON)

        expect(page).to have_content(
          format(COPY::COLOCATED_ACTION_PLACE_HOLD_CONFIRMATION, veteran_name, new_hold_duration_days)
        )
        expect(page).to have_current_path("/queue/appeals/#{appeal.uuid}")

        # Values in database are correct.
        colocated_individual_task.reload
        expect(colocated_individual_task.status).to eq(Constants.TASK_STATUSES.on_hold)
        expect(colocated_individual_task.calculated_placed_on_hold_at).to_not eq(old_hold_started)
        expect(colocated_individual_task.calculated_on_hold_duration).to eq(new_hold_duration_days)

        # Task snapshot updated with new hold information
        expect(page).to have_content("0 of #{new_hold_duration_days}")
      end
    end
  end

  describe "vlj support staff changes task type" do
    let(:root_task) { create(:root_task) }
    let(:appeal) { root_task.appeal }
    let!(:colocated_task) do
      create(
        :ama_colocated_task,
        :other,
        appeal: appeal,
        parent: root_task,
        assigned_to: vlj_support_staff
      )
    end

    let(:new_task_type) { IhpColocatedTask }

    it "should update the task type" do
      # Visit case details page for VLJ support staff.
      User.authenticate!(user: vlj_support_staff)
      visit "/queue"
      click_on "#{appeal.veteran_full_name} (#{appeal.veteran_file_number})"

      # Navigate to the change task type modal
      find(".Select-control", text: COPY::TASK_ACTION_DROPDOWN_BOX_LABEL).click
      find("div", class: "Select-option", text: Constants.TASK_ACTIONS.CHANGE_TASK_TYPE.to_h[:label]).click

      expect(page).to have_content(COPY::CHANGE_TASK_TYPE_SUBHEAD)

      # Ensure all admin actions are available
      find(".Select-control", text: "Select an action type").click do
        visible_options = page.find_all(".Select-option")
        expect(visible_options.length).to eq Constants::CO_LOCATED_ADMIN_ACTIONS.length
      end

      # Attempt to change task type without including instuctions.
      find("div", class: "Select-option", text: new_task_type.label).click
      find("button", text: COPY::CHANGE_TASK_TYPE_SUBHEAD).click

      # Instructions field is required
      expect(page).to have_content(COPY::FORM_ERROR_FIELD_REQUIRED)

      # Add instructions and try again
      instructions = generate_words(5)
      fill_in("instructions", with: instructions)
      find("button", text: COPY::CHANGE_TASK_TYPE_SUBHEAD).click

      # We should see a success message but remain on the case details page
      expect(page).to have_content(
        format(
          COPY::CHANGE_TASK_TYPE_CONFIRMATION_TITLE,
          Constants::CO_LOCATED_ADMIN_ACTIONS.values.last,
          new_task_type.label
        )
      )

      # Ensure the task has been updated
      expect(page).to have_content(format("TASK\n%<label>s", label: new_task_type.label))
      page.find("#currently-active-tasks button", text: COPY::TASK_SNAPSHOT_VIEW_TASK_INSTRUCTIONS_LABEL).click
      expect(page).to have_content(instructions)
    end
  end
end
