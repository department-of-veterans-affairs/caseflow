# frozen_string_literal: true

require "json"

class ExternalApi::WebexService
  CREATE_CONFERENCE_ENDPOINT = "api-usgov.webex.com/v1/meetings"
  MOCK_ENDPOINT = "localhost:3050/fake.#{CREATE_CONFERENCE_ENDPOINT}"
  # ENDPOINT = ApplicationController.dependencies_faked? ? MOCK_ENDPOINT : CREATE_CONFERENCE_ENDPOINT

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
    title = virtual_hearing.alias
    hearing_day = HearingDay.find(virtual_hearing.hearing.hearing_day_id)
    hearing = Hearing.find(virtual_hearing.hearing.hearing_day_id)
    start_date_time = hearing.scheduled_for.iso8601
    timezone = hearing.regional_office&.timezone
    end_date = hearing_day.scheduled_for
    end_time = "23:59:59"
    end_date_time = combine_time_and_date(end_time, timezone, end_date)

    body = {
      "jwt": {
        "sub": title,
        "Nbf": start_date_time,
        "Exp": end_date_time,
        "flow": {
          "id": "sip-no-knock",
          "data": [
            {
              "uri": "example1@intadmin.room.wbx2.com"
            },
            {
              "uri": "example2@intadmin.room.wbx2.com"
            }
          ]
        }
      },
      # "aud": "some stuff",
      "numGuest": 1,
      "numHost": 1,
      "provideShortUrls": true,
      "verticalType": "gen",
      "loginUrlForHost": false,
      "jweAlg": "PBES2-HS512+A256KW",
      "saltLength": 8,
      "iterations": 1000,
      "enc": "A256GCM",
      "jwsAlg": "HS512"
    }

    resp = send_webex_request(MOCK_ENDPOINT, :post, body: body)
    return if resp.nil?

    ExternalApi::WebexService::CreateResponse.new(resp)
  end
  # rubocop:enable Metrics/MethodLength

  def delete_conference(virtual_hearing)
    return if virtual_hearing.conference_id.nil?

    delete_endpoint = "#{MOCK_ENDPOINT}#{conference_id}/"
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
