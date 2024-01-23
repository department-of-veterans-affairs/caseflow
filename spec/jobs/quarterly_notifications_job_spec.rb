# frozen_string_literal: true

describe QuarterlyNotificationsJob, type: :job do
  include ActiveJob::TestHelper
  let(:appeal) { create(:appeal, :active) }
  let(:legacy_appeal) { create(:legacy_appeal, vacols_case: vacols_case) }
  let(:vacols_case) { create(:case)}
  let(:user) { create(:user) }
  subject { QuarterlyNotificationsJob.perform_now }
  describe "#perform" do
    context "appeal is nil" do
      let!(:appeal_state) do
        create(
          :appeal_state,
          appeal_id: 2,
          appeal_type: "Appeal",
          created_by_id: user.id,
          updated_by_id: user.id
        )
      end
      it "does not push a new message" do
        expect { subject }.not_to have_enqueued_job(SendNotificationJob)
      end
      it "rescues and logs error" do
        expect(Rails.logger).to receive(:error)
        subject
      end
    end
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
        expect { subject }.not_to have_enqueued_job(SendNotificationJob)
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
        subject
        expect(SendNotificationJob).to have_been_enqueued.exactly(:once)
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
        subject
        expect(SendNotificationJob).to have_been_enqueued.exactly(:once)
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
        subject
        expect(SendNotificationJob).to have_been_enqueued.exactly(:once)
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
        subject
        expect(SendNotificationJob).to have_been_enqueued.exactly(:once)
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
          hearing_withdrawn: true,
          scheduled_in_error: true
        )
      end
      it "pushes a new message" do
        subject
        expect(SendNotificationJob).to have_been_enqueued.exactly(:once)
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
        subject
        expect(SendNotificationJob).to have_been_enqueued.exactly(:once)
      end
    end
    context "Hearing Scheduled / Privacy Act Pending with ihp task" do
      let!(:appeal_state) do
        create(
          :appeal_state,
          appeal_id: appeal.id,
          appeal_type: "Appeal",
          created_by_id: user.id,
          updated_by_id: user.id,
          appeal_docketed: true,
          hearing_scheduled: true,
          privacy_act_pending: true,
          vso_ihp_pending: true
        )
      end
      it "pushes a new message" do
        subject
        expect(SendNotificationJob).to have_been_enqueued.exactly(:once)
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
        subject
        expect(SendNotificationJob).to have_been_enqueued.exactly(:once)
      end
    end
    context "Hearing Scheduled with ihp task pending" do
      let!(:appeal_state) do
        create(
          :appeal_state,
          appeal_id: appeal.id,
          appeal_type: "Appeal",
          created_by_id: user.id,
          updated_by_id: user.id,
          appeal_docketed: true,
          hearing_scheduled: true,
          vso_ihp_pending: true
        )
      end
      it "pushes a new message" do
        subject
        expect(SendNotificationJob).to have_been_enqueued.exactly(:once)
      end
    end
    context "Hearing Scheduled / Privacy Act Pending" do
      let!(:appeal_state) do
        create(
          :appeal_state,
          appeal_id: appeal.id,
          appeal_type: "Appeal",
          created_by_id: user.id,
          updated_by_id: user.id,
          appeal_docketed: true,
          hearing_scheduled: true,
          privacy_act_pending: true
        )
      end
      it "pushes a new message" do
        subject
        expect(SendNotificationJob).to have_been_enqueued.exactly(:once)
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
        subject
        expect(SendNotificationJob).to have_been_enqueued.exactly(:once)
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
        subject
        expect(SendNotificationJob).to have_been_enqueued.exactly(:once)
      end
    end
    context "Hearing Scheduled" do
      let!(:appeal_state) do
        create(
          :appeal_state,
          appeal_id: legacy_appeal.id,
          appeal_type: "LegacyAppeal",
          created_by_id: user.id,
          updated_by_id: user.id,
          appeal_docketed: true,
          hearing_scheduled: true
        )
      end
      it "pushes a new message" do
        subject
        expect(SendNotificationJob).to have_been_enqueued.exactly(:once)
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
        subject
        expect { subject }.not_to have_enqueued_job(SendNotificationJob)
      end
    end
  end
end
