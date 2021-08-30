# frozen_string_literal: true

##
# Maps Hearing records (exported by SanitizedJsonExporter) to AppealEventData objects
# for use by ExplainController.

class Explain::HearingRecordEventMapper < Explain::RecordEventMapper
  # :reek:FeatureEnvy
  def initialize(record, hearing_day, virtual_hearing, object_id_cache)
    @hearing_day = hearing_day
    @virtual_hearing = virtual_hearing
    super("hearing", record,
          object_id_cache: object_id_cache,
          default_context_id: "Appeal_#{record['appeal_id']}",
          default_object_id: "Hearing_#{record['id']}")
  end

  def events
    [
      hearing_creation_event,
      (hearing_updated_event if record["updated_at"])
    ].compact
  end

  private

  def slot_time
    record["scheduled_time"]&.strftime("%H:%M")
  end

  def regional_office
    @hearing_day["regional_office"]
  end

  REQUEST_TYPE_TO_WORDS = HearingDay::REQUEST_TYPES.invert.freeze

  def hearing_type
    # See https://github.com/department-of-veterans-affairs/caseflow/wiki/Caseflow-Data-Model-and-Dictionary#virtualhearings
    return "virtual" if @virtual_hearing

    (REQUEST_TYPE_TO_WORDS[@hearing_day["request_type"]]).to_s
  end

  def hearing_as_word
    "#{@hearing_day['scheduled_for']} #{hearing_type} hearing with judge #{user(record['judge_id'])}"
  end

  RELEVANT_DATA_KEYS = %w[scheduled_for scheduled_time military_service representative_name bva_poc room].freeze

  def hearing_creation_event
    new_event(record["created_at"], "created",
              comment: "#{user(record['created_by_id'])} created #{hearing_as_word}",
              relevant_data_keys: RELEVANT_DATA_KEYS) do |event|
                event.relevant_data[:slot_time] = slot_time if slot_time
                event.relevant_data[:regional_office] = regional_office if regional_office
                event.details[:hearing_day] = @hearing_day if @hearing_day
                event.details[:virtual_hearing] = @virtual_hearing if @virtual_hearing
              end
  end

  RELEVANT_UPDATE_DATA_KEYS = %w[evidence_window_waived
                                 transcript_requested transcript_sent_date
                                 notes summary prepped witness].freeze

  def hearing_updated_event
    new_event(record["updated_at"], record["disposition"],
              comment: "#{user(record['updated_by_id'])} marked #{hearing_as_word} as #{record['disposition']}",
              relevant_data_keys: RELEVANT_UPDATE_DATA_KEYS)
  end
end
