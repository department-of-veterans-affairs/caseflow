# frozen_string_literal: true

##
# Service for converting any type of hearing to a virtual hearing
# and returning appropriate user alerts.

class VirtualHearings::ConvertToVirtualHearingService
  class << self
    # converts a hearing to virtual and returns alerts
    def convert_hearing_to_virtual(hearing, virtual_hearing_attributes)
      update_attributes = {
        virtual_hearing_attributes: virtual_hearing_attributes.to_h.deep_symbolize_keys,
        hearing: hearing
      }

      form = if hearing.is_a?(LegacyHearing)
               LegacyHearingUpdateForm.new(update_attributes)
             else
               HearingUpdateForm.new(update_attributes)
             end
      form.update

      [{ hearing: form.hearing_alerts }, { virtual_hearing: form.virtual_hearing_alert }]
    rescue ActiveRecord::RecordNotUnique => error
      # :nocov:
      raise wrap_error(error, 1003, COPY::VIRTUAL_HEARING_ALREADY_CREATED)
      # :nocov:
    rescue ActiveRecord::RecordInvalid => error
      raise wrap_error(error, 1002, error.message)
    rescue StandardError => error
      # :nocov:
      raise wrap_error(error, 1099, error.message)
      # :nocov:
    end

    private

    # Wraps an error in the class `Caseflow::Error::VirtualHearingConversionFailed`, allowing
    # errors thrown by this class to be handled with specialized logic.
    def wrap_error(error, code, message)
      Caseflow::Error::VirtualHearingConversionFailed.new(
        error_type: error.class,
        message: message,
        code: code
      )
    end
  end
end
