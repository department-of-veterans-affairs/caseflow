# frozen_string_literal: true

describe ChangeHearingRequestTypeTask do
  let(:task) { create(:change_hearing_request_type_task, :assigned) }
  let(:user) { create(:user, roles: ["Edit HearSched"]) }

  describe "#update_from_params" do
    subject { task.update_from_params(payload, user) }

    context "when payload has cancelled status" do
      let(:payload) do
        {
          status: Constants.TASK_STATUSES.cancelled
        }
      end

      it "cancels the task" do
        expect { subject }.to(
          change { task.reload.status }
            .from(Constants.TASK_STATUSES.assigned)
            .to(Constants.TASK_STATUSES.cancelled)
        )
      end

      context "when there's a full task tree" do
        let(:loc_schedule_hearing) { LegacyAppeal::LOCATION_CODES[:schedule_hearing] }
        let(:vacols_case) { create(:case, :travel_board_hearing, bfcurloc: loc_schedule_hearing) }
        let!(:appeal) { create(:legacy_appeal, vacols_case: vacols_case) }
        let(:root_task) { create(:root_task, appeal: appeal) }
        let(:hearing_task) { create(:hearing_task, appeal: appeal, parent: root_task) }
        let(:schedule_hearing_task) { create(:schedule_hearing_task, appeal: appeal, parent: hearing_task) }
        let!(:task) { create(:change_hearing_request_type_task, appeal: appeal, parent: schedule_hearing_task) }

        it "cancels the hearing task tree without triggering callbacks" do
          expect(hearing_task).to_not receive(:when_child_task_completed)

          subject

          expect(task.reload.status).to eq(Constants.TASK_STATUSES.cancelled)
          expect(schedule_hearing_task.reload.status).to eq(Constants.TASK_STATUSES.cancelled)
          expect(hearing_task.reload.status).to eq(Constants.TASK_STATUSES.cancelled)
          expect(vacols_case.reload.bfcurloc).to eq(loc_schedule_hearing)
        end
      end
    end
  end
end
