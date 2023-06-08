# frozen_string_literal: true

describe JudgeLegacyTask, :postgres do
  before do
    Timecop.freeze(Time.utc(2015, 1, 30, 12, 0, 0))
  end

  let(:vacols_id) { "1111" }
  let(:document_id) { "173341517.524" }
  let(:assigned_by_first_name) { "Joe" }
  let(:assigned_by_last_name) { "Snuffy" }
  let(:reassigned_to_judge_date) { nil }
  let(:assigned_to_attorney_date) { nil }
  let(:legacy_judge_task) do
    JudgeLegacyTask.from_vacols(
      case_assignment,
      LegacyAppeal.create(vacols_id: vacols_id),
      judge
    )
  end
  let(:case_assignment) do
    OpenStruct.new(vacols_id: vacols_id,
                   date_due: 1.day.ago,
                   reassigned_to_judge_date: reassigned_to_judge_date,
                   docket_date: nil,
                   created_at: 5.days.ago,
                   assigned_to_location_date: 3.days.ago,
                   assigned_to_attorney_date: assigned_to_attorney_date,
                   document_id: document_id,
                   assigned_by: OpenStruct.new(first_name: assigned_by_first_name, last_name: assigned_by_last_name))
  end
  let(:judge) { create(:user).tap { |user| create(:staff, :judge_role, user: user) } }
  let(:user) { judge }

  context "#from_vacols" do
    subject { legacy_judge_task }

    context "when a case is ready to be assigned to an attorney" do
      it "sets all the fields correctly" do
        expect(subject.user_id).to eq user.css_id
        expect(subject.id).to eq vacols_id
        expect(subject.label).to eq COPY::JUDGE_ASSIGN_TASK_LABEL
        expect(subject.assigned_on).to eq 3.days.ago.to_datetime
        expect(subject.task_id).to eq "#{vacols_id}-2015-01-25"
        expect(subject.previous_task).to eq nil
      end
    end

    context "when a case has been reaasigned back to judge" do
      let(:reassigned_to_judge_date) { 5.days.ago }
      let(:assigned_to_attorney_date) { 10.days.ago }

      it "sets all the fields correctly" do
        expect(subject.user_id).to eq user.css_id
        expect(subject.id).to eq vacols_id
        expect(subject.label).to eq COPY::JUDGE_DECISION_REVIEW_TASK_LABEL
        expect(subject.timeline_title).to eq COPY::CASE_TIMELINE_JUDGE_TASK
        expect(subject.assigned_on).to eq 3.days.ago.to_datetime
        expect(subject.task_id).to eq "#{vacols_id}-2015-01-25"
        expect(subject.document_id).to eq document_id
        expect(subject.assigned_by_first_name).to eq assigned_by_first_name
        expect(subject.assigned_by_last_name).to eq assigned_by_last_name
        expect(subject.previous_task.assigned_at).to eq 10.days.ago.to_datetime
      end
    end
  end

  context ".available_actions" do
    subject { legacy_judge_task.available_actions(user, "judge") }

    context "when the task is at judge assign" do
      context "when the user is not the assignee" do
        let(:user) { create(:user) }

        it "returns no actions" do
          expect(subject).to eq []
        end
      end

      context "when the user is the assignee" do
        it "returns all judge actions" do
          expect(subject).to match_array [
            Constants.TASK_ACTIONS.ADD_ADMIN_ACTION.to_h,
            Constants.TASK_ACTIONS.ASSIGN_TO_ATTORNEY.to_h,
            Constants.TASK_ACTIONS.REASSIGN_TO_LEGACY_JUDGE.to_h
          ]
        end
      end

      context "when the user is on the special case movement team" do
        let(:user) { create(:user).tap { |scm_user| SpecialCaseMovementTeam.singleton.add_user(scm_user) } }

        it "returns only case movement actions" do
          expect(subject).to match_array [
            Constants.TASK_ACTIONS.REASSIGN_TO_LEGACY_JUDGE.to_h,
            Constants.TASK_ACTIONS.ASSIGN_TO_ATTORNEY.to_h
          ]
        end
      end

      context "when the user is on the special case movement team" do
        let(:user) { create(:user).tap { |scm_user| SpecialCaseMovementTeam.singleton.add_user(scm_user) } }

        it "returns only case movement actions" do
          expect(subject).to match_array [
            Constants.TASK_ACTIONS.REASSIGN_TO_LEGACY_JUDGE.to_h,
            Constants.TASK_ACTIONS.ASSIGN_TO_ATTORNEY.to_h
          ]
        end
      end
    end

    context "when the task is at judge review" do
      let(:reassigned_to_judge_date) { 5.days.ago }
      let(:assigned_to_attorney_date) { 10.days.ago }

      context "when the user is the assignee" do
        it "returns all judge actions" do
          expect(subject).to match_array [
            Constants.TASK_ACTIONS.ADD_ADMIN_ACTION.to_h,
            Constants.TASK_ACTIONS.JUDGE_LEGACY_CHECKOUT.to_h,
            Constants.TASK_ACTIONS.JUDGE_LEGACY_RETURN_TO_ATTORNEY.to_h,
            Constants.TASK_ACTIONS.REASSIGN_TO_LEGACY_JUDGE.to_h
          ]
        end
      end
    end
  end
end
