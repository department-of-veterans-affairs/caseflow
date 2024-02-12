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
    @num_hosts = args[:num_hosts] || 1
    @num_guests = args[:num_guests] || 1
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
        {},
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
        {},
        build_meeting_response
      )
    )
  end

  def get_recordings_list
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

  def get_recording_details
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

  # rubocop:disable Metrics/MethodLength
  def fake_recordings_list_data
    {
      "items": [
        {
          "id": "4f914b1dfe3c4d11a61730f18c0f5387",
          "meetingId": "f91b6edce9864428af084977b7c68291_I_166641849979635652",
          "scheduledMeetingId": "f91b6edce9864428af084977b7c68291_20200713T121500Z",
          "meetingSeriesId": "f91b6edce9864428af084977b7c68291",
          "topic": "200103-61110_2000061110_Appeal",
          "createTime": "2020-07-13T17:11:35Z",
          "timeRecorded": "2020-07-13T17:05:35Z",
          "siteUrl": "site4-example.webex.com",
          "downloadUrl": "https://site4-example.webex.com/site4/lsr.php?RCID=b91990e37417bda24986e46cf43345ab",
          "playbackUrl": "https://site4-example.webex.com/site4/ldr.php?RCID=69201a61d1d94a84aca18817261d1a73",
          "password": "BgJep@43",
          "format": "ARF",
          "serviceType": "MeetingCenter",
          "durationSeconds": 18_416,
          "sizeBytes": 168_103,
          "shareToMe": false,
          "integrationTags": [
            "dbaeceebea5c4a63ac9d5ef1edfe36b9",
            "85e1d6319aa94c0583a6891280e3437d",
            "27226d1311b947f3a68d6bdf8e4e19a1"
          ],
          "status": "available"
        },
        {
          "id": "3324fb76946249cfa07fc30b3ccbf580",
          "meetingId": "f91b6edce9864428af084977b7c68291_I_166641849979635652",
          "scheduledMeetingId": "f91b6edce9864428af084977b7c68291_20200713T121500Z",
          "meetingSeriesId": "f91b6edce9864428af084977b7c68291",
          "topic": "150000248290335_343_LegacyAppeal",
          "createTime": "2020-07-13T17:11:34Z",
          "timeRecorded": "2020-07-13T17:05:35Z",
          "siteUrl": "site4-example.webex.com",
          "downloadUrl": "https://site4-example.webex.com/site4/lsr.php?RCID=8a763939dec1fa26c565700d628fcb98",
          "playbackUrl": "https://site4-example.webex.com/site4/ldr.php?RCID=b05e9c4f773745e7b88725cc97bc3161",
          "password": "BgJep@43",
          "format": "ARF",
          "serviceType": "MeetingCenter",
          "durationSeconds": 181_562,
          "sizeBytes": 199_134,
          "shareToMe": false,
          "integrationTags": [
            "dbaeceebea5c4a63ac9d5ef1edfe36b9",
            "85e1d6319aa94c0583a6891280e3437d",
            "27226d1311b947f3a68d6bdf8e4e19a1"
          ],
          "status": "available"
        },
        {
          "id": "42b80117a2a74dcf9863bf06264f8075",
          "meetingId": "f91b6edce9864428af084977b7c68291_I_166641849979635652",
          "scheduledMeetingId": "f91b6edce9864428af084977b7c68291_20200713T121500Z",
          "meetingSeriesId": "f91b6edce9864428af084977b7c68291",
          "topic": "231207-1177_1177_Appeal",
          "createTime": "2020-07-13T17:11:33Z",
          "timeRecorded": "2020-07-13T17:05:35Z",
          "siteUrl": "site4-example.webex.com",
          "downloadUrl": "https://site4-example.webex.com/site4/lsr.php?RCID=0edd48adbb183e7da97884a0a984e877",
          "playbackUrl": "https://site4-example.webex.com/site4/ldr.php?RCID=b64b28ebf70e4645954420c295a9fcad",
          "password": "BgJep@4",
          "format": "ARF",
          "serviceType": "MeetingCenter",
          "durationSeconds": 181_562,
          "sizeBytes": 199_134,
          "shareToMe": true,
          "integrationTags": [
            "dbaeceebea5c4a63ac9d5ef1edfe36b9",
            "85e1d6319aa94c0583a6891280e3437d",
            "27226d1311b947f3a68d6bdf8e4e19a1"
          ],
          "status": "available"
        }
      ]
    }
  end
  # rubocop:enable Metrics/MethodLength

  def fake_recording_details_data
    {
      "id": "4f914b1dfe3c4d11a61730f18c0f5387",
      "meetingId": "f91b6edce9864428af084977b7c68291_I_166641849979635652",
      "scheduledMeetingId": "f91b6edce9864428af084977b7c68291_20200713T121500Z",
      "meetingSeriesId": "f91b6edce9864428af084977b7c68291",
      "topic": "Example Topic",
      "createTime": "2020-07-13T17:11:35Z",
      "timeRecorded": "2020-07-13T17:05:35Z",
      "siteUrl": "site4-example.webex.com",
      "downloadUrl": "https://site4-example.webex.com/site4/lsr.php?RCID=b91990e37417bda24986e46cf43345ab",
      "playbackUrl": "https://site4-example.webex.com/site4/ldr.php?RCID=69201a61d1d94a84aca18817261d1a73",
      "password": "BgJep@43",
      "temporaryDirectDownloadLinks": {
          "recordingDownloadLink": "https://site4-example.webex.com/nbr/MultiThreadDownloadServlet?siteid=2062842&recordid=305462&confid=137735449369118342&language=en_US&userid=3516472&serviceRecordID=305492&ticket=SDJTSwAAAIUBSHkvL6Z5ddyBim5%2FHcJYcvn6IoXNEyCE2mAYQ5BlBg%3D%3D&timestamp=1567125236465&islogin=yes&isprevent=no&ispwd=yes",
          "audioDownloadLink": "https://site4-example.webex.com/nbr/downloadMedia.do?siteid=2062842&recordid=305462&confid=137735449369118342&language=en_US&userid=3516472&serviceRecordID=305492&ticket=SDJTSwAAAIXCIXsuBt%2BAgtK7WoQ2VhgeI608N4ZMIJ3vxQaQNZuLZA%3D%3D&timestamp=1567125236708&islogin=yes&isprevent=no&ispwd=yes&mediaType=1",
          "transcriptDownloadLink": "https://site4-example.webex.com/nbr/downloadMedia.do?siteid=2062842&recordid=305462&confid=137735449369118342&language=en_US&userid=3516472&serviceRecordID=305492&ticket=SDJTSwAAAAJVUJDxeA08qKkF%2FlxlSkDxuEFPwgGT0XW1z21NhY%2BCvg%3D%3D&timestamp=1567125236866&islogin=yes&isprevent=no&ispwd=yes&mediaType=2",
          "expiration": "2022-05-01T10:30:25Z"
      },
      "format": "ARF",
      "serviceType": "MeetingCenter",
      "durationSeconds": 18416,
      "sizeBytes": 168103,
      "shareToMe": false,
      "integrationTags": [
          "dbaeceebea5c4a63ac9d5ef1edfe36b9",
          "85e1d6319aa94c0583a6891280e3437d",
          "27226d1311b947f3a68d6bdf8e4e19a1"
      ],
      "status": "available"
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
