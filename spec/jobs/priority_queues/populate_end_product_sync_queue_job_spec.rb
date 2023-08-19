# frozen_string_literal: true

describe PopulateEndProductSyncQueueJob, type: :job do
  include ActiveJob::TestHelper

  let(:slack_service) { SlackService.new(url: "http://www.example.com") }

  let!(:epes_to_be_queued) do
    create_list(:end_product_establishment, 2, :active_hlr_with_cleared_vbms_ext_claim)
  end

  let!(:not_found_epe) do
    create(:end_product_establishment, :active_hlr_with_active_vbms_ext_claim)
  end

  subject do
    # Changing the sleep duration to 0 enables suite to run faster
    stub_const("PopulateEndProductSyncQueueJob::SLEEP_DURATION", 0)
    # Batch limit changes to 1 to test PopulateEndProductSyncQueueJob loop
    stub_const("PopulateEndProductSyncQueueJob::BATCH_LIMIT", 1)

    @job = PopulateEndProductSyncQueueJob.perform_later
  end

  describe "#perform" do
    context "when all records sync successfully" do
      before do
        allow(SlackService).to receive(:new).with(url: anything).and_return(slack_service)
        allow(slack_service).to receive(:send_notification) { |_, first_arg| @slack_msg = first_arg }
        perform_enqueued_jobs do
          subject
        end
      end

      it "adds the 2 unsynced epes to the end product synce queue" do
        expect(PriorityEndProductSyncQueue.count).to eq 2
      end

      it "the current user is set to a system user" do
        expect(RequestStore.store[:current_user].id).to eq(User.system_user.id)
      end

      it "adds the epes to the priority end product sync queue table" do
        expect(PriorityEndProductSyncQueue.first.end_product_establishment_id).to eq epes_to_be_queued.first.id
        expect(PriorityEndProductSyncQueue.second.end_product_establishment_id).to eq epes_to_be_queued.second.id
      end

      it "the epes are associated with a vbms_ext_claim record" do
        expect(EndProductEstablishment.find(PriorityEndProductSyncQueue.first.end_product_establishment_id).reference_id).to eq (epes_to_be_queued.first.vbms_ext_claim.claim_id.to_s)
        expect(EndProductEstablishment.find(PriorityEndProductSyncQueue.second.end_product_establishment_id).reference_id).to eq (epes_to_be_queued.second.vbms_ext_claim.claim_id.to_s)
      end

      it "the priority end product sync queue records have a status of 'NOT_PROCESSED'" do
        expect(PriorityEndProductSyncQueue.first.status).to eq "NOT_PROCESSED"
        expect(PriorityEndProductSyncQueue.second.status).to eq "NOT_PROCESSED"
      end

      it "slack will NOT be notified when job runs successfully" do
        expect(slack_service).to_not have_received(:send_notification)
      end
    end

    context "when the epe's reference id is a lettered string (i.e. only match on matching numbers)" do
      before do
        epes_to_be_queued.each { |epe| epe.update!(reference_id: "whaddup yooo") }
        perform_enqueued_jobs do
          subject
        end
      end

      it "doesn't add epe to the queue" do
        expect(PriorityEndProductSyncQueue.count).to eq 0
      end
    end

    context "when a priority end product sync queue record already exists with the epe id" do
      before do
        PriorityEndProductSyncQueue.create(end_product_establishment_id: epes_to_be_queued.first.id)
        perform_enqueued_jobs do
          subject
        end
      end

      it "will not add same epe more than once in the priorty end product sync queue table" do
        expect(PriorityEndProductSyncQueue.count).to eq 2
      end
    end

    context "when the epe records' synced_status value is nil" do
      before do
        epes_to_be_queued.each { |epe| epe.update!(synced_status: nil) }
        perform_enqueued_jobs do
          subject
        end
      end

      it "will add the epe if epe synced status is nil and other conditions are met" do
        expect(PriorityEndProductSyncQueue.count).to eq 2
      end
    end

    context "when the job duration ends before all PriorityEndProductSyncQueue records can be batched" do
      before do
        # Job duration of 0.001 seconds limits the job's loop to one iteration
        stub_const("PopulateEndProductSyncQueueJob::JOB_DURATION", 0.001.seconds)
        allow(SlackService).to receive(:new).with(url: anything).and_return(slack_service)
        allow(slack_service).to receive(:send_notification) { |_, first_arg| @slack_msg = first_arg }
        perform_enqueued_jobs do
          subject
        end
      end

      it "there are 3 epe records" do
        expect(EndProductEstablishment.count).to eq(3)
      end

      it "creates 1 priority end product sync queue record" do
        expect(PriorityEndProductSyncQueue.count).to eq(1)
      end

      it "the current user is set to a system user" do
        expect(RequestStore.store[:current_user].id).to eq(User.system_user.id)
      end

      it "adds the epes to the priority end product sync queue table" do
        expect(PriorityEndProductSyncQueue.first.end_product_establishment_id).to eq epes_to_be_queued.first.id
      end

      it "the epes are associated with a vbms_ext_claim record" do
        expect(EndProductEstablishment.find(PriorityEndProductSyncQueue.first.end_product_establishment_id).reference_id).to eq (epes_to_be_queued.first.vbms_ext_claim.claim_id.to_s)
      end

      it "the priority end product sync queue record has a status of 'NOT_PROCESSED'" do
        expect(PriorityEndProductSyncQueue.first.status).to eq "NOT_PROCESSED"
      end

      it "slack will NOT be notified when job runs successfully" do
        expect(slack_service).to_not have_received(:send_notification)
      end
    end

    context "when there are no records available to batch" do
      before do
        EndProductEstablishment.destroy_all
        allow(Rails.logger).to receive(:info)
        perform_enqueued_jobs do
          subject
        end
      end

      it "doesn't add any epes to the batch" do
        expect(PriorityEndProductSyncQueue.count).to eq 0
      end

      it "logs a message that says 'PopulateEndProductSyncQueueJob is not able to find any batchable EPE records'" do
        expect(Rails.logger).to have_received(:info).with(
          "PopulateEndProductSyncQueueJob is not able to find any batchable EPE records."\
          "  Active Job ID: #{@job.job_id}."\
          "  Time: #{Time.zone.now}"
        )
      end
    end

    context "when an error is raised during the job" do
      let(:standard_error) { StandardError.new("Uh-Oh!") }
      before do
        allow(Rails.logger).to receive(:error)
        allow(Raven).to receive(:capture_exception)
        allow(Raven).to receive(:last_event_id) { "sentry_123" }
        allow(SlackService).to receive(:new).with(url: anything).and_return(slack_service)
        allow(slack_service).to receive(:send_notification) { |_, first_arg| @slack_msg = first_arg }
        allow_any_instance_of(PopulateEndProductSyncQueueJob)
          .to receive(:find_priority_end_product_establishments_to_sync).and_raise(standard_error)
        perform_enqueued_jobs do
          subject
        end
      end

      it "the error and the backtrace will be logged" do
        expect(Rails.logger).to have_received(:error).with(an_instance_of(StandardError))
      end

      it "the error will be sent to Sentry" do
        expect(Raven).to have_received(:capture_exception)
          .with(instance_of(StandardError),
                extra: {
                  active_job_id: @job.job_id,
                  job_time: Time.zone.now.to_s
                })
      end

      it "slack will be notified when job fails" do
        expect(slack_service).to have_received(:send_notification).with(
          "[ERROR] Error running PopulateEndProductSyncQueueJob.  Error: #{standard_error.message}."\
          "  Active Job ID: #{@job.job_id}.  See Sentry event sentry_123.", "PopulateEndProductSyncQueueJob"
        )
      end
    end

    context "when there are no records available to batch" do
      before do
        VbmsExtClaim.destroy_all
        allow(Rails.logger).to receive(:info)
        perform_enqueued_jobs do
          subject
        end
      end

      it "a message that says 'Cannot Find Any Records to Batch' will be logged" do
        expect(Rails.logger).to have_received(:info).with(
          "PopulateEndProductSyncQueueJob is not able to find any batchable EPE records."\
          "  Active Job ID: #{@job.job_id}.  Time: #{Time.zone.now}"
        )
      end
    end
  end
end
