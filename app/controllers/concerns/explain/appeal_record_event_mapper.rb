# frozen_string_literal: true

##
# Maps Appeal records (exported by SanitizedJsonExporter) to AppealEventData objects for use by ExplainController.

class Explain::AppealRecordEventMapper < Explain::RecordEventMapper
  # :reek:FeatureEnvy
  def initialize(record)
    appeal_object_id = "#{Appeal.name}_#{record['id']}"
    super("appeal", record,
          default_context_id: appeal_object_id,
          default_object_id: appeal_object_id)
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
      events << new_event(current_time, "month", category: "clock", object_id: "month_#{count}")
    end
  end

  private

  def receipt_date
    record["receipt_date"]
  end

  def receipt_date_event
    new_event(receipt_date, "milestone", category: "milestone",
              comment: "NOD received",
              relevant_data_keys: %w[stream_type docket_type veteran_is_not_claimant])
  end

  RELEVANT_DATA_KEYS = %w[stream_type docket_type veteran_is_not_claimant
                          aod_based_on_age
                          established_at establishment_canceled_at
                          closest_regional_office
                          target_decision_date docket_range_date
                          legacy_opt_in_approved].freeze

  def appeal_creation_event
    duration_in_words = duration_in_words(receipt_date, record["created_at"])
    new_event(record["created_at"], "created",
              comment: "#{record['stream_docket_number']} created #{duration_in_words} from receipt date",
              relevant_data_keys: RELEVANT_DATA_KEYS)
  end
end
