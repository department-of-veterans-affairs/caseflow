# frozen_string_literal: true

class Fakes::WebexService
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
  end

  def create_conference(conferenced_item)
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
        generate_meetings_api_conference(conferenced_item)
      )
    )
  end

  def delete_conference(conf_id)
    if error?
      return ExternalApi::WebexService::DeleteResponse.new(
        HTTPI::Response.new(
          @status_code, {}, error_response
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

  def generate_meetings_api_conference(conferenced_item)
    conf_id = Faker::Alphanumeric.alphanumeric(number: 32).downcase
    meeting_num = Faker::Number.number(digits: 11)

    {
      id: conf_id,
      meetingNumber: meeting_num,
      password: Faker::Alphanumeric.alphanumeric(number: 11, min_alpha: 3, min_numeric: 3),
      phoneAndVideoSystemPassword: Faker::Number.number(digits: 8)
    }.merge(telephony_options(conf_id, meeting_num))
      .merge(DEFAULT_MEETING_PROPERTIES)
      .merge(conferenced_item.meeting_details_for_conference)
  end
end
