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

      it "displays a Tasks column" do
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
      let!(:colocated_person_task) do
        create(:colocated_task, appeal: appeal, parent: colocated_org_task, assigned_to: create(:user))
      end

      before do
        new_user = create(:user, :vlj_support_user)
        reassign_params = {
          assigned_to_type: User.name,
          assigned_to_id: new_user.id
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
  end

  describe "returning to sct queue action process" do
    let(:sct_task) { create(:specialty_case_team_assign_task, :completed) }
    let(:appeal) { sct_task.appeal }
    let(:attorney) { appeal.tasks.of_type(:AttorneyTask).first.assigned_to }
    let(:sct_user) { create(:user) }
    let(:sct_org) { SpecialtyCaseTeam.singleton }

    before { sct_org.add_user(sct_user) }

    shared_examples "attorney or judge return to sct queue" do
      it "attorney can view sct appeal in queue and return it back to sct queue" do
        step "shows the sct appeal in the attorney's queue" do
          visit "/queue"
          expect(page).to have_content(appeal.veteran_full_name)
        end

        step "start the return to sct queue process" do
          visit "/queue/appeals/#{appeal.uuid}"
          click_dropdown(text: Constants.TASK_ACTIONS.CANCEL_TASK_AND_RETURN_TO_SCT_QUEUE.label)
          expect(page).to have_content(COPY::RETURN_TO_SCT_MODAL_TITLE)
          expect(page).to have_content(COPY::RETURN_TO_SCT_MODAL_BODY)
          expect(page).to have_button(COPY::MODAL_RETURN_BUTTON, disabled: true)

          fill_in(COPY::PROVIDE_INSTRUCTIONS_AND_CONTEXT_LABEL, with: "Return this case to SCT please.")
          expect(page).to have_button(COPY::MODAL_RETURN_BUTTON, disabled: false)
          find("button", text: COPY::MODAL_RETURN_BUTTON).click
          expect(page).to have_content(format(COPY::RETURN_TO_SCT_SUCCESS_BANNER_TITLE, appeal.claimant.name))
          expect(page).to have_content(COPY::RETURN_TO_SCT_SUCCESS_BANNER_DETAIL)
        end

        step "the returned appeal shows in the sct queue action required tab" do
          User.authenticate!(user: sct_user)
          visit "/organizations/#{sct_org.url}"
          expect(page).to have_content("#{appeal.veteran_full_name} (#{appeal.veteran_file_number})")
        end
      end
    end

    include_examples "attorney or judge return to sct queue"

    context "when the attorney can act as a judge" do
      before do
        SpecialCaseMovementTeam.singleton.add_user(attorney)
        attorney.reload
      end

      include_examples "attorney or judge return to sct queue"
    end
  end
end
