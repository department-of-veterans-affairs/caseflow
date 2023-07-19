# frozen_string_literal: true

describe HearingPostponementRequestMailTask, :postgres do
  let(:user) { create(:user) }

  describe ".available_actions" do
    let(:task_actions) do
      [
        Constants.TASK_ACTIONS.CHANGE_TASK_TYPE.to_h,
        Constants.TASK_ACTIONS.COMPLETE_AND_POSTPONE.to_h,
        Constants.TASK_ACTIONS.ASSIGN_TO_TEAM.to_h,
        Constants.TASK_ACTIONS.ASSIGN_TO_PERSON.to_h,
        Constants.TASK_ACTIONS.CANCEL_TASK.to_h
      ]
    end
    let(:reduced_task_actions) do
      [
        Constants.TASK_ACTIONS.CHANGE_TASK_TYPE.to_h,
        Constants.TASK_ACTIONS.CANCEL_TASK.to_h
      ]
    end

    context "when user does not belong to the hearing admin team" do
      it "returns an empty array" do
        expect(subject.available_actions(user).length).to eq(0)
      end
    end

    context "when user belongs to the hearing admin team" do
      before { HearingAdmin.singleton.add_user(user) }

      shared_examples "returns appropriate task actions" do
        it "returns appropriate task actions" do
          expect(hpr.available_actions(user).length).to eq(5)
          expect(hpr.available_actions(user)).to eq(task_actions)
        end
      end

      shared_examples "returns appropriate reduced task actions" do
        it "returns appropriate reduced task actions" do
          expect(hpr.available_actions(user).length).to eq(2)
          expect(hpr.available_actions(user)).to eq(reduced_task_actions)
        end
      end

      context "when there is an active ScheduleHearingTask in the appeal's task tree" do
        let(:hpr) { create(:hearing_postponement_request_mail_task, :with_unscheduled_hearing) }

        include_examples "returns appropriate task actions"
      end

      context "when there is an open AssignHearingDispositionTask in the appeal's task tree" do
        let(:hpr) { create(:hearing_postponement_request_mail_task, :with_scheduled_hearing) }

        context "when the hearing is scheduled in the past" do
          before do
            allow_any_instance_of(Hearing).to receive(:scheduled_for).and_return(Time.zone.yesterday)
          end

          include_examples "returns appropriate reduced task actions"
        end

        context "when the hearing is not scheduled in the past" do
          before do
            allow_any_instance_of(Hearing).to receive(:scheduled_for).and_return(Time.zone.tomorrow)
          end

          include_examples "returns appropriate task actions"
        end
      end

      context "when there is neither an active ScheduleHearingTask " \
              "nor an open AssignHearingDispositionTask in the appeal's task tree" do
        let(:hpr) { create(:hearing_postponement_request_mail_task, :with_unscheduled_hearing) }
        before do
          task = hpr.appeal.tasks.find_by(type: ScheduleHearingTask.name)
          task.cancel_task_and_child_subtasks
        end

        include_examples "returns appropriate reduced task actions"
      end
    end
  end
end
