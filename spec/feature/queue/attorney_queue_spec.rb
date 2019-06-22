# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Attorney queue" do
  let(:judge) { FactoryBot.create(:user) }
  let!(:vacols_judge) { FactoryBot.create(:staff, :judge_role, user: judge) }

  let(:attorney) { FactoryBot.create(:user) }
  let!(:vacols_attorney) { FactoryBot.create(:staff, :attorney_role, user: attorney) }

  let!(:judge_team) do
    JudgeTeam.create_for_judge(judge).tap { |jt| OrganizationsUser.add_user_to_organization(attorney, jt) }
  end

  before do
    User.authenticate!(user: attorney)
  end

  describe "assigning admin actions to VLJ support staff" do
    let!(:colocated_team) do
      Colocated.singleton.tap { |org| OrganizationsUser.add_user_to_organization(FactoryBot.create(:user), org) }
    end

    context "for AMA appeals" do
      let(:appeal) { FactoryBot.create(:appeal) }
      let(:root_task) { FactoryBot.create(:root_task, appeal: appeal) }
      let(:judge_task) do
        FactoryBot.create(
          :ama_judge_decision_review_task,
          appeal: appeal,
          assigned_to: judge,
          parent: root_task
        )
      end
      let(:attorney_task) do
        FactoryBot.create(
          :ama_attorney_task,
          appeal: appeal,
          assigned_by: judge,
          assigned_to: attorney,
          parent: judge_task,
          status: Constants.TASK_STATUSES.on_hold
        )
      end
      let!(:colocated_task) do
        FactoryBot.create(
          :ama_colocated_task,
          appeal: appeal,
          assigned_by: attorney,
          assigned_to: colocated_team,
          parent: attorney_task
        )
      end

      it "the case only appears once in the on hold tab" do
        visit("/queue")

        expect(page).to have_content(format(COPY::QUEUE_PAGE_ON_HOLD_TAB_TITLE, 1))
        find("button", text: format(COPY::QUEUE_PAGE_ON_HOLD_TAB_TITLE, 1)).click

        expect(find("tbody").find_all("tr").length).to eq(1)
      end

      it "displays a Task(s) column" do
        visit("/queue")

        expect(page).to have_content(format(COPY::CASE_LIST_TABLE_TASKS_COLUMN_TITLE), 1)
      end
    end
  end

  describe "timed holds" do
    let(:appeal) { FactoryBot.create(:appeal) }
    let(:root_task) { FactoryBot.create(:root_task, appeal: appeal) }
    let(:judge_task) do
      FactoryBot.create(
        :ama_judge_decision_review_task,
        appeal: appeal,
        assigned_to: judge,
        parent: root_task
      )
    end
    let!(:attorney_task) do
      FactoryBot.create(
        :ama_attorney_task,
        appeal: appeal,
        assigned_by: judge,
        assigned_to: attorney,
        parent: judge_task,
        status: task_status
      )
    end

    context "when the task is active" do
      let(:task_status) { Constants.TASK_STATUSES.in_progress }

      it "allows us to add a timed hold for an AttorneyTask" do
        visit("/queue/appeals/#{appeal.external_id}")

        click_dropdown(
          prompt: COPY::TASK_ACTION_DROPDOWN_BOX_LABEL,
          text: Constants.TASK_ACTIONS.PLACE_TIMED_HOLD.label
        )

        hold_length = 30
        click_dropdown(prompt: COPY::COLOCATED_ACTION_PLACE_HOLD_LENGTH_SELECTOR_LABEL, text: "#{hold_length} days")

        instructions_text = generate_words(5)
        fill_in("instructions", with: instructions_text)
        click_on(COPY::MODAL_SUBMIT_BUTTON)

        expect(page).to have_content(
          format(COPY::COLOCATED_ACTION_PLACE_HOLD_CONFIRMATION, appeal.veteran_full_name, hold_length)
        )
        expect(TimedHoldTask.where(appeal: appeal).length).to eq(1)

        attorney_task.reload
        expect(attorney_task.calculated_on_hold_duration).to eq(hold_length)
        expect(attorney_task.instructions.last).to eq(instructions_text)
        expect(attorney_task.status).to eq(Constants.TASK_STATUSES.on_hold)
      end
    end

    context "when the task is already on a timed hold" do
      let(:task_status) { Constants.TASK_STATUSES.in_progress }

      before { TimedHoldTask.create_from_parent(attorney_task, days_on_hold: 15) }

      it "allows us to remove the hold from the AttorneyTask" do
        visit("/queue/appeals/#{appeal.external_id}")

        expect(attorney_task.reload.status).to eq(Constants.TASK_STATUSES.on_hold)

        click_dropdown(prompt: COPY::TASK_ACTION_DROPDOWN_BOX_LABEL, text: Constants.TASK_ACTIONS.END_TIMED_HOLD.label)
        click_on(COPY::MODAL_SUBMIT_BUTTON)

        expect(page).to have_content(COPY::END_HOLD_SUCCESS_MESSAGE_TITLE)
        expect(attorney_task.reload.status).to eq(Constants.TASK_STATUSES.assigned)
      end
    end

    context "when the AttorneyTask is on hold because it has a child task" do
      let(:task_status) { Constants.TASK_STATUSES.on_hold }

      before { FactoryBot.create(:ama_colocated_task, appeal: appeal, parent: attorney_task) }

      it "cannot have any action taken on it" do
        visit("/queue/appeals/#{appeal.external_id}")

        expect(page).to_not have_content(COPY::TASK_ACTION_DROPDOWN_BOX_LABEL)
      end
    end
  end

  describe "on hold tab contents" do
    context "when an AMA appeal has a ColocatedTask" do
      let(:appeal) { FactoryBot.create(:appeal) }
      let(:root_task) { FactoryBot.create(:root_task, appeal: appeal) }
      let(:judge_task) do
        FactoryBot.create(
          :ama_judge_decision_review_task,
          appeal: appeal,
          assigned_to: judge,
          parent: root_task
        )
      end
      let(:attorney_task) do
        FactoryBot.create(
          :ama_attorney_task,
          appeal: appeal,
          assigned_by: judge,
          assigned_to: attorney,
          parent: judge_task
        )
      end
      let!(:colocated_users) do
        3.times { OrganizationsUser.add_user_to_organization(FactoryBot.create(:user), Colocated.singleton) }
      end
      let!(:colocated_org_task) do
        FactoryBot.create(
          :colocated_task,
          appeal: appeal,
          assigned_by: attorney,
          assigned_to: Colocated.singleton,
          parent: attorney_task
        )
      end

      it "displays a single row for the appeal in the attorney's on hold tab" do
        visit("/queue")

        click_on(format(COPY::QUEUE_PAGE_ON_HOLD_TAB_TITLE, 1))

        expect(page).to have_content(appeal.veteran_full_name)
        expect(page).to have_content(attorney_task.label)
      end
    end

    context "when a LegacyAppeal has a ColocatedTask" do
      let(:appeal) { FactoryBot.create(:legacy_appeal, vacols_case: FactoryBot.create(:case)) }
      let!(:colocated_users) do
        3.times { OrganizationsUser.add_user_to_organization(FactoryBot.create(:user), Colocated.singleton) }
      end
      let!(:colocated_org_task) do
        FactoryBot.create(
          :colocated_task,
          appeal: appeal,
          assigned_by: attorney,
          assigned_to: Colocated.singleton
        )
      end

      it "displays a single row for the appeal in the attorney's on hold tab" do
        visit("/queue")

        click_on(format(COPY::QUEUE_PAGE_ON_HOLD_TAB_TITLE, 1))

        expect(page).to have_content(appeal.veteran_full_name)
        expect(page).to have_content(Constants::CO_LOCATED_ADMIN_ACTIONS[colocated_org_task.label])
      end
    end

    context "when a LegacyAppeal's ColocatedTask is re-assigned from one member of the VLJ support staff to another" do
      let(:appeal) { FactoryBot.create(:legacy_appeal, vacols_case: FactoryBot.create(:case)) }
      let!(:colocated_users) do
        3.times { OrganizationsUser.add_user_to_organization(FactoryBot.create(:user), Colocated.singleton) }
      end
      let(:colocated_org_task) do
        FactoryBot.create(
          :colocated_task,
          appeal: appeal,
          assigned_by: attorney,
          assigned_to: Colocated.singleton
        )
      end
      let(:colocated_person_task) { colocated_org_task.children.first }

      before do
        reassign_params = {
          assigned_to_type: User.name,
          assigned_to_id: ColocatedTaskDistributor.new.next_assignee.id
        }
        colocated_person_task.reassign(reassign_params, colocated_person_task.assigned_to)
      end

      it "still displays the ColocatedTask in the attorney's on hold tab" do
        visit("/queue")

        click_on(format(COPY::QUEUE_PAGE_ON_HOLD_TAB_TITLE, 1))

        expect(page).to have_content(appeal.veteran_full_name)
        expect(page).to have_content(Constants::CO_LOCATED_ADMIN_ACTIONS[colocated_org_task.label])
      end
    end
  end
end
