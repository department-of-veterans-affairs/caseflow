# frozen_string_literal: true

RSpec.feature "Attorney queue", :all_dbs do
  let(:judge) { create(:user) }
  let!(:vacols_judge) { create(:staff, :judge_role, user: judge) }

  let(:attorney) { create(:user) }
  let!(:vacols_attorney) { create(:staff, :attorney_role, user: attorney) }

  let!(:judge_team) do
    JudgeTeam.create_for_judge(judge).tap { |jt| jt.add_user(attorney) }
  end

  before do
    User.authenticate!(user: attorney)
  end

  describe "assigning admin actions to VLJ support staff" do
    let!(:colocated_team) do
      Colocated.singleton.tap { |org| org.add_user(create(:user)) }
    end

    context "for AMA appeals" do
      let(:appeal) { create(:appeal) }
      let(:root_task) { create(:root_task, appeal: appeal) }
      let(:judge_task) do
        create(
          :ama_judge_decision_review_task,
          appeal: appeal,
          assigned_to: judge,
          parent: root_task
        )
      end
      let(:attorney_task) do
        create(
          :ama_attorney_task,
          appeal: appeal,
          assigned_by: judge,
          assigned_to: attorney,
          parent: judge_task
        )
      end
      let!(:colocated_task) do
        create(
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

  describe "on hold tab contents" do
    context "when an AMA appeal has a ColocatedTask" do
      let(:appeal) { create(:appeal) }
      let(:root_task) { create(:root_task, appeal: appeal) }
      let(:judge_task) do
        create(
          :ama_judge_decision_review_task,
          appeal: appeal,
          assigned_to: judge,
          parent: root_task
        )
      end
      let(:attorney_task) do
        create(
          :ama_attorney_task,
          appeal: appeal,
          assigned_by: judge,
          assigned_to: attorney,
          parent: judge_task
        )
      end
      let!(:colocated_user) { Colocated.singleton.add_user(create(:user)) }
      let!(:colocated_org_task) do
        create(
          :colocated_task,
          appeal: appeal,
          assigned_by: attorney,
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
      let(:appeal) { create(:legacy_appeal, vacols_case: create(:case)) }
      let!(:colocated_user) { Colocated.singleton.add_user(create(:user)) }
      let!(:colocated_org_task) do
        create(
          :colocated_task,
          appeal: appeal,
          assigned_by: attorney
        )
      end

      it "displays a single row for the appeal in the attorney's on hold tab" do
        visit("/queue")

        click_on(format(COPY::QUEUE_PAGE_ON_HOLD_TAB_TITLE, 1))

        expect(page).to have_content(appeal.veteran_full_name)
        expect(page).to have_content(colocated_org_task.label)
      end
    end

    context "when a LegacyAppeal's ColocatedTask is re-assigned from one member of the VLJ support staff to another" do
      let(:appeal) { create(:legacy_appeal, vacols_case: create(:case)) }
      let!(:colocated_user) { Colocated.singleton.add_user(create(:user)) }
      let(:colocated_org_task) do
        create(
          :colocated_task,
          appeal: appeal,
          assigned_by: attorney
        )
      end
      let!(:colocated_person_task) { colocated_org_task.children.first }

      before do
        Colocated.singleton.add_user(create(:user))
        reassign_params = {
          assigned_to_type: User.name,
          assigned_to_id: Colocated.singleton.next_assignee.id
        }
        colocated_person_task.reassign(reassign_params, colocated_person_task.assigned_to)
      end

      it "still displays the ColocatedTask in the attorney's on hold tab" do
        visit("/queue")

        click_on(format(COPY::QUEUE_PAGE_ON_HOLD_TAB_TITLE, 1))

        expect(page).to have_content(appeal.veteran_full_name)
        expect(page).to have_content(colocated_org_task.label)
      end
    end

    context "when the attorney has an on hold legacy ColocatedTask assigned to them" do
      let(:appeal) { create(:legacy_appeal, vacols_case: create(:case)) }
      let!(:colocated_user) { Colocated.singleton.add_user(create(:user)) }
      let!(:colocated_org_task) do
        create(
          :colocated_task,
          appeal: appeal,
          assigned_by: attorney
        )
      end

      before { colocated_org_task.children.first.update!(assigned_to: attorney, status: :on_hold) }

      it "displays a single row for the appeal in the attorney's on hold tab" do
        visit("/queue")

        click_on(format(COPY::QUEUE_PAGE_ON_HOLD_TAB_TITLE, 1))

        expect(page).to have_content(format(COPY::QUEUE_PAGE_ASSIGNED_TAB_TITLE, 0))
        expect(page).to have_content(appeal.veteran_full_name)
        expect(page).to have_content(colocated_org_task.label)
      end
    end
  end
end
