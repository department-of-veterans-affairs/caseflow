# frozen_string_literal: true

##
# Service for converting any type of hearing to a virtual hearing
# and returning appropriate user alerts.

class VirtualHearings::ConvertToVirtualHearingService
  class << self
    # converts a hearing to virtual and returns alerts
    def convert_hearing_to_virtual(hearing, virtual_hearing_attributes)
      update_attributes = { hearing: hearing, virtual_hearing_attributes: virtual_hearing_attributes }

      update_attributes = { virtual_hearing_attributes: virtual_hearing_attributes.to_h, hearing: hearing}
      form = if hearing.is_a?(LegacyHearing)
               LegacyHearingUpdateForm.new(update_attributes)
             else
               HearingUpdateForm.new(update_attributes)
             end
      form.update

      [{ hearing: form.hearing_alerts }, { virtual_hearing: form.virtual_hearing_alert }]
    rescue StandardError => error
      raise(
        Caseflow::Error::VirtualHearingConversionFailed,
        error_type: error.class,
        message: error.message,
        code: :bad_request
      )
    end
  end
end
