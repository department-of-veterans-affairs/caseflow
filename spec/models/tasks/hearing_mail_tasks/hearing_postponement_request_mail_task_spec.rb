# frozen_string_literal: true

describe HearingPostponementRequestMailTask, :postgres do
  let(:user) { create(:user) }
  let(:hpr) { create(:hearing_postponement_request_mail_task, :postponement_request_with_scheduled_hearing) }

  describe "#available_actions" do
    let(:task_actions) do
      [
        Constants.TASK_ACTIONS.CHANGE_TASK_TYPE.to_h,
        Constants.TASK_ACTIONS.COMPLETE_AND_POSTPONE.to_h,
        Constants.TASK_ACTIONS.ASSIGN_TO_TEAM.to_h,
        Constants.TASK_ACTIONS.ASSIGN_TO_PERSON.to_h,
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

      it "returns appropriate task actions" do
        expect(hpr.available_actions(user).length).to eq(5)
        expect(hpr.available_actions(user)).to eq(task_actions)
      end
    end
  end

  describe "hearing postponed through completion of alternate task" do
    let(:appeal) { hpr.appeal }
    let(:child_hpr) { hpr.children.first }
    let(:formatted_date) { hpr.updated_at.strftime("%m/%d/%Y") }
    let(:disposition_task) { appeal.tasks.where(type: AssignHearingDispositionTask.name).first }

    before do
      HearingAdmin.singleton.add_user(user)
      RequestStore[:current_user] = user
    end

    shared_examples "cancels hpr mail tasks" do
      it "cancels open HearingPostponementRequestMailTasks" do
        expect(hpr.status).to eq(Constants.TASK_STATUSES.cancelled)
        expect(child_hpr.status).to eq(Constants.TASK_STATUSES.cancelled)
        expect(child_hpr.cancelled_by).to eq(user)
        expect(child_hpr.instructions.last).to eq(
          "##### REASON FOR CANCELLATION:\n" \
          "Hearing postponed when #{task.type} was completed on #{formatted_date}"
        )
      end
    end

    context "hearing postponed through AssignHearingDispositionTask#postpone!" do
      let(:task) { disposition_task }

      before do
        task.hearing.update!(disposition: Constants.HEARING_DISPOSITION_TYPES.postponed)
        task.postpone!
        hpr.reload
      end

      include_examples "cancels hpr mail tasks"
    end

    context "hearing postponed through NoShowHearingTask#reschedule_hearing" do
      let(:task) { appeal.tasks.where(type: NoShowHearingTask.name).first }

      before do
        disposition_task.hearing.update!(disposition: Constants.HEARING_DISPOSITION_TYPES.no_show)
        disposition_task.no_show!
        task.reschedule_hearing
        hpr.reload
      end

      include_examples "cancels hpr mail tasks"
    end

    context "hearing postponed through #update_from_params" do
      let(:params) do
        {
          status: Constants.TASK_STATUSES.cancelled,
          instructions: "instructions",
          business_payloads: {
            values: {
              disposition: Constants.HEARING_DISPOSITION_TYPES.postponed,
              after_disposition_update: { action: "schedule_later" }
            }
          }
        }
      end

      before do
        task.update_from_params(params, user)
        hpr.reload
      end

      context "hearing postponed through AssignHearingDispositionTask#update_from_params" do
        let(:task) { disposition_task }

        include_examples "cancels hpr mail tasks"
      end

      context "hearing postponed through ChangeHearingDispositionTask#update_from_params" do
        let(:task) { create(:change_hearing_disposition_task, parent: disposition_task.parent) }

        include_examples "cancels hpr mail tasks"
      end
    end
  end
end
