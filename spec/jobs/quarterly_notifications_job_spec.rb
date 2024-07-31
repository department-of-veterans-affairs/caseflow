# frozen_string_literal: true

describe QuarterlyNotificationsJob, type: :job do
  include ActiveJob::TestHelper

  let(:appeal) { create(:appeal, :active) }
  let(:legacy_appeal) { create(:legacy_appeal, vacols_case: vacols_case) }
  let(:vacols_case) { create(:case) }
  let(:user) { create(:user) }
  subject { QuarterlyNotificationsJob.perform_now }
  describe "#perform" do
    context "Appeal Decision Mailed" do
      let!(:appeal_state) do
        create(
          :appeal_state,
          appeal_id: 2,
          appeal_type: "Appeal",
          created_by_id: user.id,
          updated_by_id: user.id,
          decision_mailed: true
        )
      end

      it "does not push a new message" do
        expect_message_to_not_be_enqueued

        subject
      end
    end

    context "job setup" do
      it "sets the current user for BGS calls" do
        subject
        expect(RequestStore[:current_user]).to eq(User.system_user)
      end
    end

    context "Appeal Docketed" do
      let!(:appeal_state) do
        create(
          :appeal_state,
          appeal_id: appeal.id,
          appeal_type: "Appeal",
          created_by_id: user.id,
          updated_by_id: user.id,
          appeal_docketed: true
        )
      end

      it "pushes a new message" do
        expect_message_to_be_queued
        expect_message_to_have_status("docketed")

        subject
      end
    end

    context "Appeal Docketed with withdrawn hearing" do
      let!(:appeal_state) do
        create(
          :appeal_state,
          appeal_id: appeal.id,
          appeal_type: "Appeal",
          created_by_id: user.id,
          updated_by_id: user.id,
          appeal_docketed: true,
          hearing_withdrawn: true
        )
      end

      it "pushes a new message" do
        expect_message_to_be_queued
        expect_message_to_have_status("docketed")

        subject
      end
    end

    context "Hearing to be Rescheduled / Privacy Act Pending for hearing postponed" do
      let!(:appeal_state) do
        create(
          :appeal_state,
          appeal_id: appeal.id,
          appeal_type: "Appeal",
          created_by_id: user.id,
          updated_by_id: user.id,
          appeal_docketed: true,
          hearing_postponed: true,
          privacy_act_pending: true
        )
      end

      it "pushes a new message" do
        expect_message_to_be_queued
        expect_message_to_have_status("Privacy Act Pending")

        subject
      end
    end

    context "Hearing to be Rescheduled for hearing postponed" do
      let!(:appeal_state) do
        create(
          :appeal_state,
          appeal_id: appeal.id,
          appeal_type: "Appeal",
          created_by_id: user.id,
          updated_by_id: user.id,
          appeal_docketed: true,
          hearing_postponed: true
        )
      end

      it "pushes a new message" do
        expect_message_to_be_queued
        expect_message_to_have_status("docketed")

        subject
      end
    end

    context "Hearing to be Rescheduled / Privacy Act Pending for scheduled in error" do
      let!(:appeal_state) do
        create(
          :appeal_state,
          appeal_id: appeal.id,
          appeal_type: "Appeal",
          created_by_id: user.id,
          updated_by_id: user.id,
          appeal_docketed: true,
          scheduled_in_error: true,
          privacy_act_pending: true
        )
      end

      it "pushes a new message" do
        expect_message_to_be_queued
        expect_message_to_have_status("Privacy Act Pending")

        subject
      end
    end

    context "Hearing to be Rescheduled for scheduled in error" do
      let!(:appeal_state) do
        create(
          :appeal_state,
          appeal_id: appeal.id,
          appeal_type: "Appeal",
          created_by_id: user.id,
          updated_by_id: user.id,
          appeal_docketed: true,
          scheduled_in_error: true
        )
      end

      it "pushes a new message" do
        expect_message_to_be_queued
        expect_message_to_have_status("docketed")

        subject
      end
    end

    context "VSO IHP Pending / Privacy Act Pending" do
      let!(:appeal_state) do
        create(
          :appeal_state,
          appeal_id: appeal.id,
          appeal_type: "Appeal",
          created_by_id: user.id,
          updated_by_id: user.id,
          appeal_docketed: true,
          privacy_act_pending: true,
          vso_ihp_pending: true
        )
      end

      it "pushes a new message" do
        expect_message_to_be_queued
        expect_message_to_have_status("VSO IHP Pending / Privacy Act Pending")

        subject
      end
    end

    context "Hearing Scheduled / Privacy Act Pending" do
      let(:hearing) { create(:hearing, :with_tasks) }
      let!(:appeal_state) do
        hearing.appeal.appeal_state.tap do
          _1.update!(
            appeal_docketed: true,
            hearing_scheduled: true,
            privacy_act_pending: true
          )
        end
      end

      it "pushes a new message" do
        expect_message_to_be_queued
        expect_message_to_have_status("Hearing Scheduled /  Privacy Act Pending")

        subject
      end
    end

    context "Privacy Act Pending" do
      let!(:appeal_state) do
        create(
          :appeal_state,
          appeal_id: appeal.id,
          appeal_type: "Appeal",
          created_by_id: user.id,
          updated_by_id: user.id,
          appeal_docketed: true,
          privacy_act_pending: true
        )
      end

      it "pushes a new message" do
        expect_message_to_be_queued
        expect_message_to_have_status("Privacy Act Pending")

        subject
      end
    end

    context "VSO IHP Pending" do
      let!(:appeal_state) do
        create(
          :appeal_state,
          appeal_id: appeal.id,
          appeal_type: "Appeal",
          created_by_id: user.id,
          updated_by_id: user.id,
          appeal_docketed: true,
          vso_ihp_pending: true
        )
      end

      it "pushes a new message" do
        expect_message_to_be_queued
        expect_message_to_have_status("VSO IHP Pending")

        subject
      end
    end

    context "Hearing Scheduled" do
      let(:legacy_hearing) { create(:legacy_hearing) }
      let!(:appeal_state) do
        legacy_hearing.appeal.appeal_state.tap do
          _1.update!(
            appeal_docketed: true,
            hearing_scheduled: true
          )
        end

        it "pushes a new message" do
          expect_message_to_be_queued
          expect_message_to_have_status("Hearing Scheduled")

          subject
        end
      end
    end

    context "cancelled appeal" do
      let!(:appeal_state) do
        create(
          :appeal_state,
          appeal_id: appeal.id,
          appeal_type: "Appeal",
          created_by_id: user.id,
          updated_by_id: user.id,
          appeal_cancelled: true
        )
      end

      it "does not push a new message" do
        subject
        expect { subject }.not_to have_enqueued_job(SendNotificationJob)
      end
    end

    context "decision mailed" do
      let!(:appeal_state) do
        create(
          :appeal_state,
          appeal_id: appeal.id,
          appeal_type: "Appeal",
          created_by_id: user.id,
          updated_by_id: user.id,
          decision_mailed: true
        )
      end
      it "does not push a new message" do
        expect_message_to_not_be_enqueued

        subject
      end
    end
  end

  def expect_message_to_be_queued
    expect_any_instance_of(QuarterlyNotificationsJob)
      .to receive(:enqueue_init_jobs)
      .with(
        array_including(
          instance_of(NotificationInitializationJob)
        )
      )
  end

  def expect_message_to_have_status(status)
    expect_any_instance_of(NotificationInitializationJob)
      .to receive(:initialize)
      .with({
              appeal_id: appeal_state.appeal_id,
              appeal_type: appeal_state.appeal_type,
              template_name: Constants.EVENT_TYPE_FILTERS.quarterly_notification,
              appeal_status: status
            })
  end

  def expect_message_to_not_be_enqueued
    expect_any_instance_of(QuarterlyNotificationsJob)
      .to_not receive(:enqueue_init_jobs)
  end
end
