# frozen_string_literal: true

class HearingsController < HearingsApplicationController
  include HearingsConcerns::VerifyAccess
  include ValidationConcern

  before_action :verify_access_to_hearings, except: [:show]
  before_action :verify_access_to_reader_or_hearings, only: [:show]

  rescue_from ActiveRecord::RecordNotFound do |error|
    Rails.logger.debug "Unable to find hearing in Caseflow: #{error.message}"
    render json: { "errors": ["message": error.message, code: 1000] }, status: :not_found
  end

  rescue_from ActiveRecord::RecordNotUnique do |_error|
    render json: { "errors": ["message": COPY::VIRTUAL_HEARING_ALREADY_CREATED, code: 1003] }, status: :conflict
  end

  rescue_from ActiveRecord::RecordInvalid do |error|
    render json: { "errors": ["message": error.message, code: 1002] }, status: :bad_request
  end

  rescue_from Caseflow::Error::VacolsRepositoryError do |error|
    Rails.logger.debug "Unable to find hearing in VACOLS: #{error.message}"
    render json: { "errors": ["message": error.message, code: 1001] }, status: :not_found
  end

  def show
    render json: { data: hearing.to_hash_for_worksheet(current_user.id) }
  end

  validates :update, using: HearingsSchemas.update
  def update
    form = HearingUpdateForm.new(update_params)
    form.update

    render json: {
      data: form.hearing.to_hash(current_user.id),
      alerts: [
        { hearing: form.hearing_alerts },
        { virtual_hearing: form.virtual_hearing_alert }
      ]
    }
  end

  validates :update_legacy, using: HearingsSchemas.update_legacy
  def update_legacy
    form = LegacyHearingUpdateForm.new(update_params_legacy)
    form.update
    render json: {
      data: form.hearing.to_hash(current_user.id),
      alerts: [
        { hearing: form.hearing_alerts },
        { virtual_hearing: form.virtual_hearing_alert }
      ]
    }
  end

  def find_closest_hearing_locations
    HearingDayMapper.validate_regional_office(params["regional_office"])

    appeal = Appeal.find_appeal_by_uuid_or_find_or_create_legacy_appeal_by_vacols_id(params["appeal_id"])
    facility_ids = RegionalOffice.facility_ids_for_ro(params["regional_office"])
    facility_response = appeal.va_dot_gov_address_validator.get_distance_to_facilities(facility_ids: facility_ids)

    if facility_response.success?
      render json: { hearing_locations: facility_response.data }
    else
      capture_exception(facility_response.error) if facility_response.error.code == 400
      render facility_response.error.serialize_response
    end
  end

  def virtual_hearing_job_status
    render json: {
      email_events: hearing.serialized_email_events,
      virtual_hearing: {
        status: hearing.virtual_hearing&.status,
        job_completed: hearing.virtual_hearing&.job_completed?,
        alias_with_host: hearing.virtual_hearing&.formatted_alias_or_alias_with_host,
        guest_link: hearing.virtual_hearing&.guest_link,
        host_link: hearing.virtual_hearing&.host_link,
        guest_pin: hearing.virtual_hearing&.guest_pin,
        host_pin: hearing.virtual_hearing&.host_pin
      }
    }
  end

  private

  def hearing
    @hearing ||= Hearing.find_hearing_by_uuid_or_vacols_id(hearing_external_id)
  end

  def hearing_external_id
    params[:id]
  end

  def update_params
    permitted_params[:hearing]
      .to_h
      .merge(
        hearing: hearing,
        advance_on_docket_motion_attributes: permitted_params[:advance_on_docket_motion].to_h
      )
  end

  def update_params_legacy
    permitted_params[:hearing]
      .to_h
      .merge(hearing: hearing)
  end
end
