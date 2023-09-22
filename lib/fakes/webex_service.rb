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

  DEFAULT_MEETING_PROPERTIES = {
    hostUserId: Faker::Alphanumeric.alphanumeric(number: 79),
    hostDisplayName: "BVA Caseflow",
    hostEmail: "testaccount@admindomain.com",
    hostKey: "123456",
    siteUrl: "test.webex.com",
    webLink: "https://test.webex.com/not-real/j.php?MTID=m#{Faker::Alphanumeric.alphanumeric(number: 32).downcase}",
    sipAddress: "12345678910@test.webex.com",
    dialInIpAddress: "",
    enabledAutoRecordMeeting: false,
    allowAnyUserToBeCoHost: false,
    allowFirstUserToBeCoHost: false,
    allowAuthenticatedDevices: true,
    enabledJoinBeforeHost: false,
    joinBeforeHostMinutes: 0,
    enableConnectAudioBeforeHost: false,
    excludePassword: false,
    publicMeeting: false,
    enableAutomaticLock: false,
    meetingType: "meetingSeries",
    state: "active",
    unlockedMeetingJoinSecurity: "allowJoinWithLobby",
    meetingOptions: {
      enabledChat: true,
      enabledVideo: true,
      enabledNote: true,
      noteType: "allowAll",
      enabledFileTransfer: true,
      enabledUCFRichMedia: true
    },
    attendeePrivileges: {
      enabledShareContent: true,
      enabledSaveDocument: false,
      enabledPrintDocument: false,
      enabledAnnotate: false,
      enabledViewParticipantList: true,
      enabledViewThumbnails: false,
      enabledRemoteControl: true,
      enabledViewAnyDocument: false,
      enabledViewAnyPage: false,
      enabledContactOperatorPrivately: false,
      enabledChatHost: true,
      enabledChatPresenter: true,
      enabledChatOtherParticipants: true
    },
    sessionTypeId: 3,
    scheduledType: "meeting",
    simultaneousInterpretation: {
      enabled: false
    },
    enabledBreakoutSessions: false,
    audioConnectionOptions: {
      audioConnectionType: "webexAudio",
      enabledTollFreeCallIn: false,
      enabledGlobalCallIn: true,
      enabledAudienceCallBack: false,
      entryAndExitTone: "beep",
      allowHostToUnmuteParticipants: false,
      allowAttendeeToUnmuteSelf: true,
      muteAttendeeUponEntry: true
    }
  }.freeze

  def initialize(**args)
    @status_code = args[:status_code]
    @error_message = args[:error_message] || "Error"
    @instant_connect = args[:use_instant_connect]
  end

  def create_conference(virtual_hearing)
    if error?
      return ExternalApi::WebexService::CreateResponse.new(
        HTTPI::Response.new(
          @status_code,
          {},
          error_response
        )
      )
    end



    ExternalApi::WebexService::CreateResponse.new(
      HTTPI::Response.new(
        200,
        {},
        if @instant_connect
          generate_instant_connect_conference(virtual_hearing)
        else
          generate_meetings_api_conference(virtual_hearing)
        end
      )
    )
  end

  def delete_conference(*)
    if error?
      return ExternalApi::WebexService::DeleteResponse.new(
        HTTPI::Response.new(
          @status_code, {}, {}
        )
      )
    end

    ExternalApi::WebexService::DeleteResponse.new(HTTPI::Response.new(200, {}, {}))
  end

  private

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
    }
  end

  def link_info(num_links = 1)
    Array.new(num_links).map do
      {
        cipher: SAMPLE_CIPHER,
        short: Faker::Alphanumeric.alphanumeric(number: 7, min_alpha: 3, min_numeric: 1)
      }
    end
  end

  def generate_instant_connect_conference(virtual_hearing)
    {
      host: link_info,
      guest: link_info(args[:num_guests]),
      baseUrl: "https://instant-usgov.webex.com/visit/"
    }
  end

  def telephony_options(conf_id, meeting_num)
    {
      telephony: {
        accessCode: meeting_num,
        callInNumbers: [
          {
            label: "United States Toll",
            callInNumber: Faker::PhoneNumber.phone_number,
            tollType: "toll"
          }
        ],
        links: [
          {
            rel: "globalCallinNumbers",
            href: "/v1/meetings/#{conf_id}/globalCallinNumbers",
            method: "GET"
          }
        ]
      }
    }
  end

  # Contains docket number of appeal, appeal id, appeal type (A/L), and hearing id
  def conference_title(virtual_hearing)
    appeal = virtual_hearing.hearing.appeal

    "#{appeal.docket_number}_#{appeal.id}_#{appeal.class}"
  end

  def generate_meetings_api_conference(virtual_hearing)
    conf_id = Faker::Alphanumeric.alphanumeric(number: 32).downcase
    meeting_num = Faker::Number.number(digits: 11)

    {
      id: conf_id,
      meetingNumber: meeting_num,
      title: conference_title(virtual_hearing),
      password: Faker::Alphanumeric.alphanumeric(number: 11, min_alpha: 3, min_numeric: 3),
      phoneAndVideoSystemPassword: Faker::Number.number(digits: 8),
      start: virtual_hearing.hearing.scheduled_for.beginning_of_day.iso8601,
      end: virtual_hearing.hearing.scheduled_for.end_of_day.iso8601,
      timezone: virtual_hearing.hering.scheduled_for.time_zone.name
    }.merge(telephony_options(conf_id, meeting_num))
      .merge(DEFAULT_CONFERENCE_OPTIONS)
  end
end
