# frozen_string_literal: true

describe NotificationInitializationJob, type: :job do
  include ActiveJob::TestHelper

  before { Seeds::NotificationEvents.new.seed! }

  let(:user) { create(:user) }

  subject do
    NotificationInitializationJob.perform_now(
      appeal_id: appeal_state.appeal_id,
      appeal_type: appeal_state.appeal_type,
      template_name: Constants.EVENT_TYPE_FILTERS.appeal_docketed,
      appeal_status: nil
    )
  end

  context "When an appeal does not exist for an appeal state" do
    let(:appeal_state) do
      create(
        :appeal_state,
        appeal_id: 99_999,
        appeal_type: "Appeal",
        created_by_id: user.id,
        updated_by_id: user.id,
        appeal_docketed: true
      )
    end

    it "An AppealNotError exception is raised" do
      expect_any_instance_of(NotificationInitializationJob).to receive(:log_error).with(
        instance_of(Caseflow::Error::AppealNotFound)
      )

      subject
    end
  end

  context "When an appeal exists for an appeal state" do
    context "The appeal is an AMA appeal" do
      let(:appeal_state) do
        create(
          :appeal_state,
          :ama,
          created_by_id: user.id,
          updated_by_id: user.id,
          appeal_docketed: true
        )
      end

      before do
        InitialTasksFactory.new(appeal_state.appeal).create_root_and_sub_tasks!
      end

      it "enqueues an SendNotificationJob" do
        expect { subject }.to have_enqueued_job(SendNotificationJob)
      end
    end

    context "The appeal is a legacy appeal" do
      before { FeatureToggle.enable!(:appeal_docketed_event) }
      after { FeatureToggle.disable!(:appeal_docketed_event) }

      let(:appeal_state) do
        create(
          :appeal_state,
          :legacy,
          created_by_id: user.id,
          updated_by_id: user.id,
          appeal_docketed: true
        )
      end

      it "enqueues an SendNotificationJob" do
        expect { subject }.to have_enqueued_job(SendNotificationJob)
      end
    end
  end
end
