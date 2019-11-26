# frozen_string_literal: true

describe RecordSyncedByJob, :postgres do
  context ".next_records_to_process" do
    let(:appeal_without_sync) { create(:appeal) }
    let(:recent_appeal_with_sync) { create(:appeal) }
    let(:old_appeal_with_sync) { create(:appeal) }

    let!(:recent_record_synced_by_job) do
      RecordSyncedByJob.create!(record: recent_appeal_with_sync, processed_at: 1.day.ago)
    end

    let!(:old_record_synced_by_job) do
      RecordSyncedByJob.create!(record: old_appeal_with_sync, processed_at: 2.days.ago)
    end

    context "when the limit is 1" do
      let(:limit) { 1 }

      it "only returns appeal without synced record" do
        expect(RecordSyncedByJob.next_records_to_process(Appeal.all, limit)).to match_array(
          [appeal_without_sync]
        )
      end
    end

    context "when the limit is 2" do
      let(:limit) { 2 }

      it "only returns appeal without synced record and the older synced record" do
        expect(RecordSyncedByJob.next_records_to_process(Appeal.all, limit)).to match_array(
          [appeal_without_sync, old_appeal_with_sync]
        )
      end
    end
  end
end
