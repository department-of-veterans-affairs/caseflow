# frozen_string_literal: true

describe ChangeHearingRequestTypeTask do
  let(:task) { create(:changed_hearing_request_type, :assigned) }
  let(:user) { create(:user, roles: ["Edit HearSched"]) }

  before { FeatureToggle.enable!(:convert_travel_board_to_video_or_virtual) }
  after { FeatureToggle.disable!(:convert_travel_board_to_video_or_virtual) }

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
          change { task.status }
            .from(Constants.TASK_STATUSES.assigned)
            .to(Constants.TASK_STATUSES.cancelled)
        )
      end
    end
  end
end
