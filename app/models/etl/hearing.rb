# frozen_string_literal: true

# transformed Hearing model, with associations "flattened" for reporting.

class ETL::Hearing < ETL::Record
  belongs_to :appeal, foreign_key: :appeal_id, foreign_type: "ETL::Appeal"

  class << self
    def origin_primary_key
      :hearing_id
    end

    private

    # rubocop:disable Metrics/MethodLength
    # rubocop:disable Metrics/AbcSize
    def merge_original_attributes_to_target(original, target)
      # memoize
      hearing_day = original.hearing_day
      hearing_location = original.hearing_location

      # hearing attributes
      target.hearing_id = original.id
      target.appeal_id = original.appeal_id
      target.hearing_created_at = original.created_at
      target.hearing_updated_at = original.updated_at
      target.bva_poc = original.bva_poc
      target.created_by_id = original.created_by_id
      target.created_by_user_css_id = original.created_by&.css_id
      target.created_by_user_full_name = original.created_by&.full_name
      target.created_by_user_sattyid = original.created_by&.vacols_user&.sattyid
      target.updated_by_id = original.updated_by_id
      target.updated_by_user_css_id = original.updated_by&.css_id
      target.updated_by_user_full_name = original.updated_by&.full_name
      target.updated_by_user_sattyid = original.updated_by&.vacols_user&.sattyid

      [
        :disposition,
        :evidence_window_waived,
        :judge_id,
        :military_service,
        :notes,
        :prepped,
        :representative_name,
        :scheduled_time,
        :summary,
        :transcript_requested,
        :transcript_sent_date,
        :uuid,
        :witness
      ].each do |attr|
        target[attr] = original[attr]
      end

      target.hearing_request_type = original.hearing_request_type

      # hearing day
      target.hearing_day_id = original.hearing_day_id
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
      ].each do |attr|
        target["hearing_day_#{attr}"] = hearing_day[attr]
      end
      target.hearing_day_created_by_id = hearing_day.created_by_id
      target.hearing_day_created_by_user_css_id = hearing_day.created_by&.css_id
      target.hearing_day_created_by_user_full_name = hearing_day.created_by&.full_name
      target.hearing_day_created_by_user_sattyid = hearing_day.created_by&.vacols_user&.sattyid
      target.hearing_day_updated_by_id = hearing_day.updated_by_id
      target.hearing_day_updated_by_user_css_id = hearing_day.updated_by&.css_id
      target.hearing_day_updated_by_user_full_name = hearing_day.updated_by&.full_name
      target.hearing_day_updated_by_user_sattyid = hearing_day.updated_by&.vacols_user&.sattyid

      # hearing location
      return target if hearing_location.blank?

      target.hearing_location_id = hearing_location.id
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
      ].each do |attr|
        target["hearing_location_#{attr}"] = hearing_location[attr]
      end

      target
    end
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/MethodLength
  end
end
