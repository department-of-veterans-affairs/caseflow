# frozen_string_literal: true

require "json"

class ExternalApi::WebexService
  ENDPOINT = "api-usgov.webex.com/v1/meetings"

  # :reek:UtilityFunction
  def combine_time_and_date(time, timezone, date)
    time_with_zone = time.in_time_zone(timezone)
    time_and_date_string = "#{date.strftime('%F')} #{time_with_zone.strftime('%T')}"
    combined_datetime = time_and_date_string.in_time_zone(timezone)
    formatted_datetime_string = combined_datetime.iso8601

    formatted_datetime_string
  end

  # rubocop:disable Metrics/MethodLength
  def create_conference(virtual_hearing)
    hearing_day = HearingDay.find(virtual_hearing.hearing.hearing_day_id)
    hearing = Hearing.find(virtual_hearing.hearing.hearing_day_id)
    timezone = hearing.regional_office&.timezone
    date = hearing_day.scheduled_for
    start_time = "00:00:01"
    end_time = "23:59:59"
    end_date_time = combine_time_and_date(end_time, timezone, date)
    start_date_time = combine_time_and_date(start_time, timezone, date)

    body = {
      "jwt": {
        "sub": virtual_hearing.subject_for_conference,
        "Nbf": start_date_time,
        "Exp": end_date_time
      },
      "aud": "",
      "numGuest": 1,
      "numHost": 1,
      "provideShortUrls": true
    }

    resp = send_webex_request(ENDPOINT, :post, body: body)
    return if resp.nil?

    ExternalApi::WebexService::CreateResponse.new(resp)
  end
  # rubocop:enable Metrics/MethodLength

  def delete_conference(virtual_hearing)
    return if virtual_hearing.conference_id.nil?

    delete_endpoint = "#{ENDPOINT}#{conference_id}/"
    resp = send_webex_request(delete_endpoint, :delete)
    return if resp.nil?

    ExternalApi::WebexService::DeleteResponse.new(resp)
  end

  private

  # :nocov:
  def send_webex_request(endpoint, method, body: nil)
    url = "http://#{endpoint}"
    request = HTTPI::Request.new(url)
    request.open_timeout = 300
    request.read_timeout = 300
    request.body = body.to_json unless body.nil?

    request.headers["Content-Type"] = "application/json" if method == :post

    MetricsService.record(
      "api-usgov.webex #{method.to_s.upcase} request to #{url}",
      service: :webex,
      name: endpoint
    ) do
      case method
      when :delete
        HTTPI.delete(request)
      when :post
        HTTPI.post(request)
      end
    end
  end
  # :nocov:
end
