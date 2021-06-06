# frozen_string_literal: true

##
# Maps Appeal records (exported by SanitizedJsonExporter) to AppealEventData objects for use by ExplainController.

class Explain::AppealRecordToEventMapper < Explain::RecordToEventMapper
  def initialize(record)
    super("appeal", record,
          default_context_id: "#{Appeal.name}_#{record['id']}",
          default_object_id: "#{Appeal.name}_#{record['id']}")
  end

  def events
    [
      receipt_date_event,
      (appeal_creation_event if record["created_at"])
    ].compact
  end

  def timing_events(last_timestamp)
    number_of_months = (last_timestamp.year * 12 + last_timestamp.month) -
                       (receipt_date.year * 12 + receipt_date.month) + 2
    number_of_months.times.each_with_object([]) do |count, events|
      next if count == 0

      current_time = receipt_date + count.month
      events << new_event(current_time, "month", object_type: "clock", object_id: "month_#{count}")
    end
  end

  private

  def receipt_date
    record["receipt_date"]
  end

  def receipt_date_event
    new_event(receipt_date, "receipt_date", object_type: "milestone")
  end

  def appeal_creation_event
    duration_in_words = duration_in_words(receipt_date, record["created_at"])
    relevant_data_keys = %w[stream_type docket_type closest_regional_office].freeze
    new_event(record["created_at"], "appeal_created",
              comment: "#{duration_in_words} from receipt date",
              relevant_data_keys: relevant_data_keys)
  end
end
