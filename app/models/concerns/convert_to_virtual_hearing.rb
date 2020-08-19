# frozen_string_literal: true

module ConvertToVirtualHearing
  extend ActiveSupport::Concern

  # takes a video or central hearing and converts to virtual and updates alerts
  def convert_hearing_to_virtual(hearing, virtual_hearing_attributes)
    update_attributes = { hearing: hearing, virtual_hearing_attributes: virtual_hearing_attributes }

    form = if hearing.is_a?(LegacyHearing)
             LegacyHearingUpdateForm.new(update_attributes)
           else
             HearingUpdateForm.new(update_attributes)
           end
    form.update

    @alerts = [{ hearing: form.hearing_alerts }, { virtual_hearing: form.virtual_hearing_alert }]
  rescue StandardError => error
    raise Caseflow::Error::VirtualHearingConversionFailed, error_class: error.class, message: error.message, code: :bad_request
  end
end
