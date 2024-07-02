# frozen_string_literal: true

# Abstract STI base class for transformed Hearing model, with associations "flattened" for reporting.

class ETL::HearingRecord < ETL::Record
  self.table_name = "hearings"

  belongs_to :appeal, primary_key: :appeal_id, foreign_key: :appeal_id, class_name: "ETL::Appeal"

  class << self
    def origin_primary_key
      :hearing_id
    end

    def mirrored_hearing_attributes
      [
        :disposition,
        :evidence_window_waived,
        :judge_id,
        :military_service,
        :notes,
        :prepped,
        :representative_name,
        :scheduled_in_timezone,
        :scheduled_time,
        :summary,
        :transcript_requested,
        :transcript_sent_date,
        :uuid,
        :witness
      ]
    end

    def mirrored_hearing_day_attributes
      [
        :bva_poc,
        :created_at,
        :deleted_at,
        :judge_id,
        :lock,
        :notes,
        :regional_office,
        :request_type,
        :room,
        :scheduled_for,
        :updated_at
      ]
    end

    def mirrored_hearing_location_attributes
      [
        :address,
        :city,
        :classification,
        :created_at,
        :distance,
        :facility_id,
        :facility_type,
        :name,
        :state,
        :updated_at,
        :zip_code
      ]
    end

    private

    # rubocop:disable Metrics/MethodLength
    # rubocop:disable Metrics/AbcSize
    def merge_original_attributes_to_target(original, target)
      # memoize
      hearing_day = original.hearing_day
      if hearing_day.nil?
        hearing_day = HearingDay.with_deleted.find(original.hearing_day_id)
      end
      hearing_location = original.hearing_location
      judge = original.judge
      created_by = user_cache(original.created_by_id)
      updated_by = user_cache(original.updated_by_id)

      # hearing attributes
      target.hearing_id = original.id
      target.appeal_id = original.appeal_id
      target.hearing_created_at = original.created_at
      target.hearing_updated_at = original.updated_at
      target.created_by_id = original.created_by_id
      target.created_by_user_css_id = created_by&.css_id
      target.created_by_user_full_name = created_by&.full_name
      target.created_by_user_sattyid = created_by&.vacols_user&.sattyid
      target.updated_by_id = original.updated_by_id
      target.updated_by_user_css_id = updated_by&.css_id
      target.updated_by_user_full_name = updated_by&.full_name
      target.updated_by_user_sattyid = updated_by&.vacols_user&.sattyid
      target.judge_css_id = judge&.css_id
      target.judge_full_name = judge&.full_name
      target.judge_sattyid = judge&.vacols_user&.sattyid

      mirrored_hearing_attributes.each do |attr|
        target[attr] = original.send(attr)
      end

      # hearing day
      if hearing_day.present?
        target.hearing_day_id = original.hearing_day_id
        mirrored_hearing_day_attributes.each do |attr|
          target["hearing_day_#{attr}"] = hearing_day[attr]
        end
        hearing_day_created_by = user_cache(hearing_day.created_by_id)
        target.hearing_day_created_by_id = hearing_day.created_by_id
        target.hearing_day_created_by_user_css_id = hearing_day_created_by&.css_id
        target.hearing_day_created_by_user_full_name = hearing_day_created_by&.full_name
        target.hearing_day_created_by_user_sattyid = hearing_day_created_by&.vacols_user&.sattyid
        hearing_day_updated_by = user_cache(hearing_day.updated_by_id)
        target.hearing_day_updated_by_id = hearing_day.updated_by_id
        target.hearing_day_updated_by_user_css_id = hearing_day_updated_by&.css_id
        target.hearing_day_updated_by_user_full_name = hearing_day_updated_by&.full_name
        target.hearing_day_updated_by_user_sattyid = hearing_day_updated_by&.vacols_user&.sattyid
      end

      # hearing location
      if hearing_location.present?
        target.hearing_location_id = hearing_location.id
        mirrored_hearing_location_attributes.each do |attr|
          target["hearing_location_#{attr}"] = hearing_location[attr]
        end
      end

      # STI does not work on the base class so we set explicitly
      target.type = name

      # do these last as they may raise exceptions in legacy hearings
      target.bva_poc = original.bva_poc
      target.hearing_request_type = original.hearing_request_type
      if original.hearing_request_type.nil?
        target.hearing_request_type = Hearing::HEARING_TYPES[hearing_day.request_type&.to_sym]
      end

      target
    end
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/MethodLength
  end
end
