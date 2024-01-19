# frozen_string_literal: true

class EventRecord < CaseflowRecord
  belongs_to :backfill_record, polymorphic: true
end
