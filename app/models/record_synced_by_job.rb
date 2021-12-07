# frozen_string_literal: true

class RecordSyncedByJob < CaseflowRecord
  belongs_to :record, polymorphic: true

  def self.next_records_to_process(records, limit)
    records.includes(:record_synced_by_job)
      .order("record_synced_by_jobs.processed_at ASC NULLS FIRST").limit(limit)
  end
end

# (This section is updated by the annotate gem)
# == Schema Information
#
# Table name: record_synced_by_jobs
#
#  id            :bigint           not null, primary key
#  error         :string
#  processed_at  :datetime
#  record_type   :string           indexed => [record_id]
#  sync_job_name :string
#  created_at    :datetime
#  updated_at    :datetime         indexed
#  record_id     :bigint           indexed => [record_type]
#
