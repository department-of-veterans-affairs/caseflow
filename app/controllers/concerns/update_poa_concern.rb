# frozen_string_literal: true

module UpdatePOAConcern
  extend ActiveSupport::Concern
  # these two methods were previously in appeals controller trying to see if they can be brought here.

  def clear_poa_not_found_cache(appeal)
    Rails.cache.delete("bgs-participant-poa-not-found-#{appeal&.veteran&.file_number}")
    Rails.cache.delete("bgs-participant-poa-not-found-#{appeal&.claimant_participant_id}")
  end

  def cooldown_period_remaining(appeal)
    next_update_allowed_at = appeal.poa_last_synced_at + 10.minutes if appeal.poa_last_synced_at.present?
    if next_update_allowed_at && next_update_allowed_at > Time.zone.now
      return ((next_update_allowed_at - Time.zone.now) / 60).ceil
    end

    0
  end

  def update_or_delete_power_of_attorney!(appeal)
    appeal.power_of_attorney&.try(:clear_bgs_power_of_attorney!) # clear memoization on legacy appeals
    poa = appeal.bgs_power_of_attorney
    if poa.blank?
      [COPY::POA_SUCCESSFULLY_REFRESH_MESSAGE, "success", "blank"]
    elsif poa.bgs_record == :not_found
      poa.destroy!
      [COPY::POA_SUCCESSFULLY_REFRESH_MESSAGE, "success", "deleted"]
    else
      poa.save_with_updated_bgs_record!
      [COPY::POA_UPDATED_SUCCESSFULLY, "success", "updated"]
    end
  rescue StandardError => error
    [error, "error", "updated"]
  end

  def update_poa_information(appeal)
    clear_poa_not_found_cache(appeal)
    cooldown_period = cooldown_period_remaining(appeal)
    if cooldown_period > 0
      render json: {
        alert_type: "info",
        message: "Information is current at this time. Please try again in #{cooldown_period} minutes",
        power_of_attorney: power_of_attorney_data
      }
    else
      message, result, status = update_or_delete_power_of_attorney!(appeal)
      render json: {
        alert_type: result,
        message: message,
        power_of_attorney: (status == "updated") ? power_of_attorney_data : {}
      }
    end
  end

  def render_error(error)
    Rails.logger.error("#{error.message}\n#{error.backtrace.join("\n")}")
    Raven.capture_exception(error, extra: { appeal_type: appeal.type, appeal_id: appeal.id })
    render json: {
      alert_type: "error",
      message: "Something went wrong"
    }, status: :unprocessable_entity
  end
end
