# frozen_string_literal: true

describe AttorneyLegacyTask, :postgres do
  before do
    Timecop.freeze(Time.utc(2015, 1, 30, 12, 0, 0))
  end

  context "#from_vacols" do
    subject { AttorneyLegacyTask.from_vacols(case_assignment, appeal, user) }

    let(:vacols_id) { "1111" }
    let(:appeal) { LegacyAppeal.create(vacols_id: vacols_id) }
    let(:user) { create(:user) }
    let(:judge) { Judge.new(create(:user)) }
    let!(:attorney) { create(:user) }
    let!(:assigning_judge) { create(:user) }
    let!(:reviewing_judge) { create(:user) }
    let(:root_task) { create(:root_task, appeal: appeal) }
    let!(:parent) do
      create(
        :ama_judge_decision_review_task,
        assigned_by: assigning_judge,
        assigned_to: reviewing_judge,
        parent: root_task
      )
    end
    let(:case_assignment) do
      OpenStruct.new(
        vacols_id: vacols_id,
        date_due: 1.day.ago,
        assigned_to_location_date: 5.days.ago,
        created_at: 6.days.ago,
        docket_date: nil
      )
    end

    context "when there is information about the case assignment" do
      it "sets all the fields correctly" do
        expect(subject.user_id).to eq(user.css_id)
        expect(subject.id).to eq(vacols_id)
        expect(subject.assigned_on).to eq 5.days.ago.to_datetime
        expect(subject.task_id).to eq "1111-2015-01-24"
        expect(subject.started_at).to eq nil
      end

      context "when the user has viewed the appeal before" do
        before { AppealView.create(appeal: appeal, user: user, created_at: 5.days.ago) }

        it "sets the started_at timetamp" do
          expect(subject.started_at).to eq 5.days.ago
        end
      end
    end

    context ".available_actions for attroney role" do
      let(:task) do
        AttorneyLegacyTask.from_vacols(case_assignment, appeal, user)
      end
      let(:user) { attorney }

      subject { task.available_actions(user, "attorney") }

      it "includes actions to submit review decision, sumbit OMO request, admin action and assign to attorney" do
        expected_actions = [
          Constants.TASK_ACTIONS.REVIEW_LEGACY_DECISION.to_h,
          Constants.TASK_ACTIONS.SUBMIT_OMO_REQUEST_FOR_REVIEW.to_h,
          Constants.TASK_ACTIONS.ADD_ADMIN_ACTION.to_h
        ]

        expect(subject).to eq(expected_actions)
      end
    end
  end
end
