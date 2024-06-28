# frozen_string_literal: true

class Fakes::WebexService
  SAMPLE_CIPHER = "eyJwMnMiOiJvUlZHZENlck9OanYxWjhLeHRub3p4NklPUUNzTVdEdWFMakRXR09kLTh4Tk91OUVyWDQ1aUZ6TG5FY" \
                  "nlJeTZTam40Vk1kVEZHU1pyaE5pRiIsInAyYyI6MzIzMzAsImF1ZCI6ImE0ZDg4NmIwLTk3OWYtNGUyYy1hOTU4LT" \
                  "NlOGMxNDYwNWU1MSIsImlzcyI6IjU0OWRhYWNiLWJmZWUtNDkxOS1hNGU0LWMwOTQ0YTY0ZGUyNSIsImN0eSI6Ikp" \
                  "XVCIsImVuYyI6IkEyNTZHQ00iLCJhbGciOiJQQkVTMi1IUzUxMitBMjU2S1cifQ.cm6FWc6Bl4vB_utAc_bswG82m" \
                  "UXhxkITkI0tZDGzzh5TKdoWSS1Mjw.L8mGls6Kp3lsa8Wz.fLen-yV2sTpWlkLFCszQjcG5V9FhJVwoNB9Ky9BgCp" \
                  "T46cFWUe-wmyn1yIZcGxFcDcwhhKwW3PVuQQ1xjl-z63o67esrvaWAjgglSioKiOFTJF1M94d4gVj2foSQtYKzR8S" \
                  "nI6wW5X5KShcVjxjchT7xDNxnHtIZoG-Zda_aOOfz_WK18rhNcyvb-BY7cSwTMhbnuuXO0-cuJ7wNyDbvqEfWXALf" \
                  "j87a2_WopcwK-x-8TQ20bzZKUrugt0FRj6VKxOCzxDhozmWDFMRu8Dpj2UrS7Fo-JQf_I1oN0O-Dwf5r8ItcNQEu5" \
                  "X0tcRazhrHSNWfOL2DOaDyHawi4oxc7MqaNRxxyrpy2qYw06_TzBwRKlMFZ8fT7-GJbDlE3nqWlNw3mlRuvhu80CH" \
                  "SO5RK5a1obU4sfLX0Fsxl-csC-1QjcHuKOSP_ozb6l7om-WeOdbSV99Fjy68egjH1NhMQIcVwpG0fy2j8r3sN4nz0" \
                  "RSe3LXoK78JqRxk6XuaQCDkr6TmG5YjHQ2FFw1tP1ekHpNIL2oJNVAKKPgget7LRuSiM6jg.628e3hFPmZCoqXuyY" \
                  "2OriQ"

  def initialize(**args)
    @status_code = args[:status_code] || 200
    @error_message = args[:error_message] || "Error"
    @num_hosts = args[:num_hosts] || 2
    @num_guests = args[:num_guests] || 1
  end

  def self.access_token
    "access_token"
  end

  def create_conference(virtual_hearing)
    if error?
      return ExternalApi::WebexService::CreateResponse.new(
        HTTPI::Response.new(@status_code, {}, error_response)
      )
    end

    ExternalApi::WebexService::CreateResponse.new(
      HTTPI::Response.new(
        200,
        { virtual_hearing: virtual_hearing },
        build_meeting_response
      )
    )
  end

  def delete_conference(virtual_hearing)
    if error?
      return ExternalApi::WebexService::DeleteResponse.new(
        HTTPI::Response.new(@status_code, {}, error_response)
      )
    end

    ExternalApi::WebexService::DeleteResponse.new(
      HTTPI::Response.new(
        200,
        { virtual_hearing: virtual_hearing },
        build_meeting_response
      )
    )
  end

  def fetch_recordings_list
    if error?
      return ExternalApi::WebexService::RecordingsListResponse.new(
        HTTPI::Response.new(@status_code, {}, error_response)
      )
    end

    ExternalApi::WebexService::RecordingsListResponse.new(
      HTTPI::Response.new(
        200,
        {},
        fake_recordings_list_data.to_json
      )
    )
  end

  def fetch_recording_details(recording_id)
    if error?
      return ExternalApi::WebexService::RecordingDetailsResponse.new(
        HTTPI::Response.new(@status_code, {}, error_response)
      )
    end

    ExternalApi::WebexService::RecordingDetailsResponse.new(
      HTTPI::Response.new(
        200,
        {},
        fake_recording_details_data.to_json
      )
    )
  end

  def fetch_rooms_list
    if error?
      return ExternalApi::WebexService::RoomsListResponse.new(
        HTTPI::Response.new(@status_code, {}, error_response)
      )
    end

    ExternalApi::WebexService::RoomsListResponse.new(
      HTTPI::Response.new(
        200,
        {},
        fake_rooms_list_data.to_json
      )
    )
  end

  def fetch_room_details(room_id)
    if error?
      return ExternalApi::WebexService::RoomDetailsResponse.new(
        HTTPI::Response.new(@status_code, {}, error_response)
      )
    end

    ExternalApi::WebexService::RoomDetailsResponse.new(
      HTTPI::Response.new(
        200,
        {},
        fake_room_details_data.to_json
      )
    )
  end

  def refresh_access_token
    ExternalApi::WebexService::AccessTokenRefreshResponse.new(
      HTTPI::Response.new(
        200,
        {},
        fake_webex_access_token_data.to_json
      )
    )
  end

  def fake_webex_access_token_data
    {
      "access_token" => "token1",
      "expires_in" => 1_209_599,
      "refresh_token" => "token2",
      "refresh_token_expires_in" => 7_757_533,
      "token_type" => "Bearer",
      "scope" => "meeting:admin_preferences_write spark:kms
    meeting:admin_preferences_read meeting:admin_schedule_write meeting:admin_recordings_write
    meeting:admin_participants_read meeting:admin_recordings_read meeting:admin_schedule_read
    meeting:admin_transcripts_read"
    }
  end

  # rubocop:disable Metrics/MethodLength
  def fake_recordings_list_data
    {
      "items": [
        {
          "id": "4f914b1dfe3c4d11a61730f18c0f5387",
          "meetingId": "f91b6edce9864428af084977b7c68291_I_166641849979635652",
          "scheduledMeetingId": "f91b6edce9864428af084977b7c68291_20200713T121500Z",
          "meetingSeriesId": "f91b6edce9864428af084977b7c68291",
          "topic": "Webex meeting-20240520 2030-1",
          "createTime": "2020-07-13T17:11:35Z",
          "timeRecorded": "2020-07-13T17:05:35Z",
          "hostDisplayName": "John Andersen",
          "hostEmail": "john.andersen@example.com",
          "siteUrl": "site4-example.webex.com",
          "downloadUrl": "https://site4-example.webex.com/site4/lsr.php?RCID=b91990e37417bda24986e46cf43345ab",
          "playbackUrl": "https://site4-example.webex.com/site4/ldr.php?RCID=69201a61d1d94a84aca18817261d1a73",
          "format": "ARF",
          "serviceType": "MeetingCenter",
          "durationSeconds": 18_416,
          "sizeBytes": 168_103,
          "integrationTags": %w[
            dbaeceebea5c4a63ac9d5ef1edfe36b9
            85e1d6319aa94c0583a6891280e3437d
            27226d1311b947f3a68d6bdf8e4e19a1
          ],
          "status": "available"
        },
        {
          "id": "3324fb76946249cfa07fc30b3ccbf580",
          "meetingId": "f91b6edce9864428af084977b7c68291_I_166641849979635652",
          "scheduledMeetingId": "f91b6edce9864428af084977b7c68291_20200713T121500Z",
          "meetingSeriesId": "f91b6edce9864428af084977b7c68291",
          "topic": "Webex meeting-20240520 4030-1",
          "createTime": "2020-07-13T17:11:34Z",
          "timeRecorded": "2020-07-13T17:05:35Z",
          "hostDisplayName": "John Andersen",
          "hostEmail": "john.andersen@example.com",
          "siteUrl": "site4-example.webex.com",
          "downloadUrl": "https://site4-example.webex.com/site4/lsr.php?RCID=8a763939dec1fa26c565700d628fcb98",
          "playbackUrl": "https://site4-example.webex.com/site4/ldr.php?RCID=b05e9c4f773745e7b88725cc97bc3161",
          "format": "ARF",
          "serviceType": "MeetingCenter",
          "durationSeconds": 181_562,
          "sizeBytes": 199_134,
          "integrationTags": %w[
            dbaeceebea5c4a63ac9d5ef1edfe36b9
            85e1d6319aa94c0583a6891280e3437d
            27226d1311b947f3a68d6bdf8e4e19a1
          ],
          "status": "available"
        },
        {
          "id": "42b80117a2a74dcf9863bf06264f8075",
          "meetingId": "f91b6edce9864428af084977b7c68291_I_166641849979635652",
          "scheduledMeetingId": "f91b6edce9864428af084977b7c68291_20200713T121500Z",
          "meetingSeriesId": "f91b6edce9864428af084977b7c68291",
          "topic": "Webex meeting-20240520 5030-1",
          "createTime": "2020-07-13T17:11:33Z",
          "timeRecorded": "2020-07-13T17:05:35Z",
          "hostDisplayName": "John Andersen",
          "hostEmail": "john.andersen@example.com",
          "siteUrl": "site4-example.webex.com",
          "downloadUrl": "https://site4-example.webex.com/site4/lsr.php?RCID=0edd48adbb183e7da97884a0a984e877",
          "playbackUrl": "https://site4-example.webex.com/site4/ldr.php?RCID=b64b28ebf70e4645954420c295a9fcad",
          "format": "ARF",
          "serviceType": "MeetingCenter",
          "durationSeconds": 181_562,
          "sizeBytes": 199_134,
          "integrationTags": %w[
            dbaeceebea5c4a63ac9d5ef1edfe36b9
            85e1d6319aa94c0583a6891280e3437d
            27226d1311b947f3a68d6bdf8e4e19a1
          ],
          "status": "available"
        }
      ]
    }
  end

  def fake_recording_details_data
    {
      "id": "4f914b1dfe3c4d11a61730f18c0f5387",
      "meetingId": "f91b6edce9864428af084977b7c68291_I_166641849979635652",
      "scheduledMeetingId": "f91b6edce9864428af084977b7c68291_20200713T121500Z",
      "meetingSeriesId": "f91b6edce9864428af084977b7c68291",
      "topic": "Webex meeting-20240520 2030-1",
      "createTime": "2020-07-13T17:11:35Z",
      "timeRecorded": "2020-07-13T17:05:35Z",
      "siteUrl": "site4-example.webex.com",
      "downloadUrl": "https://site4-example.webex.com/site4/lsr.php?RCID=b91990e37417bda24986e46cf43345ab",
      "playbackUrl": "https://site4-example.webex.com/site4/ldr.php?RCID=69201a61d1d94a84aca18817261d1a73",
      "password": "BgJep@43",
      "temporaryDirectDownloadLinks": {
        "recordingDownloadLink": "https://www.learningcontainer.com/mp4-sample-video-files-download/#",
        "audioDownloadLink": "https://freetestdata.com/audio-files/mp3/",
        "transcriptDownloadLink": "https://www.capsubservices.com/assets/downloads/web/WebVTT.vtt",
        "expiration": "2022-05-01T10:30:25Z"
      },
      "format": "ARF",
      "serviceType": "MeetingCenter",
      "durationSeconds": 18_416,
      "sizeBytes": 168_103,
      "shareToMe": false,
      "integrationTags": %w[
        dbaeceebea5c4a63ac9d5ef1edfe36b9
        85e1d6319aa94c0583a6891280e3437d
        27226d1311b947f3a68d6bdf8e4e19a1
      ],
      "status": "available"
    }
  end

  def fake_rooms_list_data
    {
      "items": [
        {
          "id": "Y2lzY29zcGFyazovL3VybjpURUFNOnVzLWdvdi13ZXN0LTFfYTEvUk9PTS85YTZjZTRjMC0xNmM5LTExZWYtYjIxOC1iMWE5YTQ2",
          "title": "Virtual Visit - 221218-977_933_Hearing-20240508 1426",
          "type": "group",
          "isLocked": false,
          "lastActivity": "2024-05-20T16:58:49.551Z",
          "creatorId": "Y2lzY29zcGFyazovL3VzL1BFT1BMRS9iOGU0ZTYyNy02MjUwLTQwY2ItYWNhZS05ZjkxZjlmY2NiYWI",
          "created": "2024-05-20T16:54:20.684Z",
          "ownerId": "Y2lzY29zcGFyazovL3VzL09SR0FOSVpBVElPTi81NDlkYWFjYi1iZmVlLTQ5MTktYTRlNC1jMDk0NGE2NGRlMjU",
          "isPublic": false,
          "isReadOnly": false
        },
        {
          "id": "Y2lzY29zcGFyazovL3VybjpURUFNOnVzLWdvdi13ZXN0LTFfYTEvUk9PTS8zYTlhMzdiMC0wZWNiLTExZWYtYTNhZS02MTJkMjlj",
          "title": "Virtual Visit - 180000304_1_LegacyHearing-20240213 1712",
          "type": "group",
          "isLocked": false,
          "lastActivity": "2024-05-10T12:45:49.611Z",
          "creatorId": "Y2lzY29zcGFyazovL3VzL1BFT1BMRS9iOGU0ZTYyNy02MjUwLTQwY2ItYWNhZS05ZjkxZjlmY2NiYWI",
          "created": "2024-05-10T12:45:49.611Z",
          "isPublic": false,
          "isReadOnly": false
        },
        {
          "id": "1234",
          "title": "Virtual Visit - 221218-977_933_AMA-20240508 1426",
          "type": "group",
          "isLocked": false,
          "lastActivity": "2024-05-11T12:45:49.611Z",
          "creatorId": "56789",
          "created": "2024-05-11T12:45:49.611Z",
          "isPublic": false,
          "isReadOnly": false
        },
        {
          "id": "5678",
          "title": "Virtual Visit - PatientLast Problem Hearing-20240213 3123",
          "type": "group",
          "isLocked": false,
          "lastActivity": "2024-05-11T12:45:49.611Z",
          "creatorId": "56789",
          "created": "2024-05-11T12:45:49.611Z",
          "isPublic": false,
          "isReadOnly": false
        }
      ]
    }
  end
  # rubocop:enable Metrics/MethodLength

  def fake_room_details_data
    {
      "roomId": "Y2lzY29zcGFyazovL3VybjpURUFNOnVzLWdvdi13ZXN0LTFfYTEvUk9PTS85YTZjZTRjMC0xNmM5LTExZWYtYjIxOC1iMWE5YTQ2",
      "meetingLink": "https://vadevops.webex.com/m/f3387f62-aded-46b9-8954-0b1f2c94dfd3",
      "sipAddress": "28236309135@vadevops.webex.com",
      "meetingNumber": "28236309135",
      "meetingId": "f91b6edce9864428af084977b7c68291_I_166641849979635652",
      "callInTollFreeNumber": "",
      "callInTollNumber": "+1-415-527-5035"
    }
  end

  private

  def build_meeting_response
    {
      host: link_info(@num_hosts),
      guest: link_info(@num_guests),
      baseUrl: "https://instant-usgov.webex.com/visit/"
    }.to_json
  end

  def link_info(num_links = 1)
    Array.new(num_links).map do
      {
        cipher: SAMPLE_CIPHER,
        short: Faker::Alphanumeric.alphanumeric(number: 7, min_alpha: 3, min_numeric: 1)
      }
    end
  end

  def error?
    [
      400, 401, 403, 404, 405, 409, 410,
      500, 502, 503, 504
    ].include? @status_code
  end

  def error_response
    {
      message: @error_message,
      errors: [
        description: @error_message
      ],
      trackingId: "ROUTER_#{SecureRandom.uuid}"
    }.to_json
  end
end
