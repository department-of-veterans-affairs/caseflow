# frozen_string_literal: true

class VBMSCaseflowLogger
  def log(event, data)
    case event
    when :request
      status = data[:response_code]

      if status != 200
        Rails.logger.error(
          "VBMS HTTP Error #{status} (#{data.pretty_inspect})"
        )
      else
        Rails.logger.info(
          "VBMS HTTP Success #{status} (#{data.pretty_inspect})"
        )
      end
    end
  end
end
