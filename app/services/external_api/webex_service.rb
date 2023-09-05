# frozen_string_literal: true

require "json"

class ExternalApi::WebexService
  CREATE_CONFERENCE_ENDPOINT = "api-usgov.webex.com/v1/meetings"
  MOCK_ENDPOINT = "localhost:3050/fake.#{CREATE_CONFERENCE_ENDPOINT}"
  # ENDPOINT = ApplicationController.dependencies_faked? ? MOCK_ENDPOINT : CREATE_CONFERENCE_ENDPOINT

  def create_conference(virtual_hearing)
    title
    # where can we get this from
    hearing_day = HearingDay.find(virtual_hearing.hearing.hearing_day_id)
    start_date_time = hearing_day.scheduled_for
    # does not give timezone
    # method to ensure correct formatting
    # begins_at in hearing_day auto creates time zone to America/New York...but can be nil
    end_date_time
    # slot_length_minutes can be nil but relevant?

    body = {
      "title": title,
      # the mock uses 'subject' which is the one we need?
      "start": start_date_time,
      "end": end_date_time,
      # Formatting >> "2019-11-01 21:00:00",
      "timezone": "Asia/Shanghai",
      # not required
      "enabledAutoRecordMeeting": "false",
      "allowAnyUserToBeCoHost": "false",
      "enabledJoinBeforeHost": "false",
      "enableConnectAudioBeforeHost": "false",
      "joinBeforeHostMinutes": 0,
      "excludePassword": "false",
      "publicMeeting": "false",
      "reminderTime": 0,
      "unlockedMeetingJoinSecurity": "allowJoinWithLobby",
      "enabledWebCastView": "false",
      "enableAutomaticLock": "false",
      "automaticLockMinutes": 0,
      "allowFirstUserToBeCoHost": "false",
      "allowAuthenticatedDevices": true,
      "sendEmail": "false",
      "siteUrl": "TBA FROM UC",
      "meetingOptions": [
        {
          "enabledChat": true,
          "enableVideo": true
        }
      ],
      "attendeePrivileges": {
        "enableShareContent": true
      },
      "enabledBreakoutSessions": false,
      "audioConnectionOptions": [
        {
          "audioConnectionType": "webexAudio",
          "enabledTollFreeCallIn": true,
          "enabledGlobalCallIn": true,
          "enabledAudianceCallBack": false,
          "entryAndExitTone": "beep",
          "allowHosttoUnmuteParticipants": true,
          "allowAttendeeToUnmuteSelf": true,
          "muteAttendeeUponEntry": true
        }
      ]
    }

    resp = send_webex_request(MOCK_ENDPOINT, :post, body: body)
    return if resp.nil?

    ExternalApi::WebexService::CreateResponse.new(resp)
  end

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
    url = endpoint
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
