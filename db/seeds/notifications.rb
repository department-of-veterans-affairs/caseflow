# frozen_string_literal: true

# create notification-events seeds

module Seeds
  class Notifications < Base
    include PowerOfAttorneyMapper

    def initialize
      initial_participant_id
    end

    def seed!
      create_first_ama_appeal
      create_second_ama_appeal
      create_third_ama_appeal
      create_fourth_ama_appeal
      create_fifth_ama_appeal
      create_sixth_ama_appeal
      create_seventh_ama_appeal
      create_eighth_ama_appeal
      create_ninth_ama_appeal
      create_notifications
    end

    private

    def initial_participant_id
      @participant_id ||= 700_000_000
    end

    def create_poa(veteran_file_number, claimant_participant_id)
      fake_poa = Fakes::BGSServicePOA.random_poa_org[:power_of_attorney]
      create(
        :bgs_power_of_attorney,
        file_number: veteran_file_number,
        claimant_participant_id: claimant_participant_id,
        representative_name: fake_poa[:nm],
        poa_participant_id: fake_poa[:ptcpnt_id],
        representative_type: BGS_REP_TYPE_TO_REP_TYPE[fake_poa[:org_type_nm]]
      )
    end

    # creates fake veteran given a file number
    def create_veteran(veteran_file_number, first_name, last_name)
      @participant_id += 1
      veteran_fields = {
        first_name: first_name,
        last_name: last_name,
        participant_id: format("%<n>09d", n: @participant_id),
        bgs_veteran_record: {
          date_of_birth: Faker::Date.birthday(min_age: 35, max_age: 80).strftime("%m/%d/%Y"),
          date_of_death: nil,
          name_suffix: nil,
          sex: Faker::Gender.binary_type[0],
          address_line1: Faker::Address.street_address,
          country: "USA",
          zip_code: Faker::Address.zip_code,
          state: Faker::Address.state_abbr,
          city: Faker::Address.city
        }
      }
      veteran_fields[:file_number] = veteran_file_number
      create(:veteran, **veteran_fields)
    end

    def create_first_ama_appeal(issue_count: 1)
      veteran = create_veteran("999999990", "Abellona", "Valtas")
      claimant_participant_id = "RANDOM_CLAIMANT_PID#{veteran.file_number}"
      create_poa(veteran.file_number, claimant_participant_id)
      create(
        :appeal,
        :with_request_issues,
        uuid: "d31d7f91-91a0-46f8-b4bc-c57e139cee72",
        veteran_file_number: veteran.file_number,
        docket_type: Constants.AMA_DOCKETS.hearing,
        stream_type: Constants.AMA_STREAM_TYPES.original,
        receipt_date: 12.days.ago,
        veteran_is_not_claimant: false,
        issue_count: issue_count,
        claimants: [create(:claimant, participant_id: claimant_participant_id)]
      )
    end

    def create_second_ama_appeal(issue_count: 1)
      veteran = create_veteran("999999991", "Bob", "Smithhickle")
      claimant_participant_id = "RANDOM_CLAIMANT_PID#{veteran.file_number}"
      create_poa(veteran.file_number, claimant_participant_id)
      create(
        :appeal,
        :with_request_issues,
        uuid: "25c4857b-3cc5-4497-a066-25be73aa4b6b",
        veteran_file_number: veteran.file_number,
        docket_type: Constants.AMA_DOCKETS.hearing,
        stream_type: Constants.AMA_STREAM_TYPES.original,
        receipt_date: 12.days.ago,
        veteran_is_not_claimant: false,
        issue_count: issue_count,
        claimants: [create(:claimant, participant_id: claimant_participant_id)]
      )
    end

    def create_third_ama_appeal(issue_count: 1)
      veteran = create_veteran("999999992", "Bob", "Smithbauch")
      claimant_participant_id = "RANDOM_CLAIMANT_PID#{veteran.file_number}"
      create_poa(veteran.file_number, claimant_participant_id)
      create(
        :appeal,
        :with_request_issues,
        uuid: "7a060e04-1143-4e42-9ede-bdc42877f4f8",
        veteran_file_number: veteran.file_number,
        docket_type: Constants.AMA_DOCKETS.hearing,
        stream_type: Constants.AMA_STREAM_TYPES.original,
        receipt_date: 12.days.ago,
        veteran_is_not_claimant: false,
        issue_count: issue_count,
        claimants: [create(:claimant, participant_id: claimant_participant_id)]
      )
    end

    def create_fourth_ama_appeal(issue_count: 1)
      veteran = create_veteran("999999993", "Bob", "Smithmurphy")
      claimant_participant_id = "RANDOM_CLAIMANT_PID#{veteran.file_number}"
      create_poa(veteran.file_number, claimant_participant_id)
      create(
        :appeal,
        :with_request_issues,
        uuid: "952b6490-a10a-484b-a29b-31489e9a6e5a",
        veteran_file_number: veteran.file_number,
        docket_type: Constants.AMA_DOCKETS.hearing,
        stream_type: Constants.AMA_STREAM_TYPES.original,
        receipt_date: 12.days.ago,
        veteran_is_not_claimant: false,
        issue_count: issue_count,
        claimants: [create(:claimant, participant_id: claimant_participant_id)]
      )
    end

    def create_fifth_ama_appeal(issue_count: 1)
      veteran = create_veteran("999999994", "Bob", "Smithwolff")
      claimant_participant_id = "RANDOM_CLAIMANT_PID#{veteran.file_number}"
      create_poa(veteran.file_number, claimant_participant_id)
      create(
        :appeal,
        :with_request_issues,
        uuid: "fb3b029f-f07e-45bf-9277-809b44f7451a",
        veteran_file_number: veteran.file_number,
        docket_type: Constants.AMA_DOCKETS.hearing,
        stream_type: Constants.AMA_STREAM_TYPES.original,
        receipt_date: 12.days.ago,
        veteran_is_not_claimant: false,
        issue_count: issue_count,
        claimants: [create(:claimant, participant_id: claimant_participant_id)]
      )
    end

    def create_sixth_ama_appeal(issue_count: 1)
      veteran = create_veteran("999999995", "Bob", "Smithwest")
      claimant_participant_id = "RANDOM_CLAIMANT_PID#{veteran.file_number}"
      create_poa(veteran.file_number, claimant_participant_id)
      create(
        :appeal,
        :with_request_issues,
        uuid: "2b3afced-f698-4abe-84f9-6d44f26d20d4",
        veteran_file_number: veteran.file_number,
        docket_type: Constants.AMA_DOCKETS.hearing,
        stream_type: Constants.AMA_STREAM_TYPES.original,
        receipt_date: 12.days.ago,
        veteran_is_not_claimant: false,
        issue_count: issue_count,
        claimants: [create(:claimant, participant_id: claimant_participant_id)]
      )
    end

    def create_seventh_ama_appeal(issue_count: 1)
      veteran = create_veteran("999999996", "Bob", "Smithgorczany")
      claimant_participant_id = "RANDOM_CLAIMANT_PID#{veteran.file_number}"
      create_poa(veteran.file_number, claimant_participant_id)
      create(
        :appeal,
        :with_request_issues,
        uuid: "ea2303e9-2bab-472b-a653-94b71bca8ca3",
        veteran_file_number: veteran.file_number,
        docket_type: Constants.AMA_DOCKETS.hearing,
        stream_type: Constants.AMA_STREAM_TYPES.original,
        receipt_date: 12.days.ago,
        veteran_is_not_claimant: false,
        issue_count: issue_count,
        claimants: [create(:claimant, participant_id: claimant_participant_id)]
      )
    end

    def create_eighth_ama_appeal(issue_count: 1)
      veteran = create_veteran("999999997", "Bob", "Smithlueilwitz")
      claimant_participant_id = "RANDOM_CLAIMANT_PID#{veteran.file_number}"
      create_poa(veteran.file_number, claimant_participant_id)
      create(
        :appeal,
        :with_request_issues,
        uuid: "6262d552-5f49-4c82-b086-2e5d8395bdac",
        veteran_file_number: veteran.file_number,
        docket_type: Constants.AMA_DOCKETS.hearing,
        stream_type: Constants.AMA_STREAM_TYPES.original,
        receipt_date: 12.days.ago,
        veteran_is_not_claimant: false,
        issue_count: issue_count,
        claimants: [create(:claimant, participant_id: claimant_participant_id)]
      )
    end

    def create_ninth_ama_appeal(issue_count: 1)
      veteran = create_veteran("999999998", "Bob", "Smithframi")
      claimant_participant_id = "RANDOM_CLAIMANT_PID#{veteran.file_number}"
      create_poa(veteran.file_number, claimant_participant_id)
      create(
        :appeal,
        :with_request_issues,
        uuid: "a11d63f2-7abc-4fab-aa4b-4308ff2f2692",
        veteran_file_number: veteran.file_number,
        docket_type: Constants.AMA_DOCKETS.hearing,
        stream_type: Constants.AMA_STREAM_TYPES.original,
        receipt_date: 12.days.ago,
        veteran_is_not_claimant: false,
        issue_count: issue_count,
        claimants: [create(:claimant, participant_id: claimant_participant_id)]
      )
    end

    def notification_content
      {
        appeal_docketed: <<-content.squish,
        Your appeal at the Board of Veteran's Appeals has been docketed. We must work cases in the
        order your VA Form 9 substantive appeal (for Legacy) or VA Form 10182 (for AMA) was received.
        We will update you with any progress. If you have any questions please reach out to your Veterans
        Service Organization or representative or log onto VA.gov for additional information.
        content
        hearing_scheduled: <<-content.squish,
        Your hearing has been scheduled with a Veterans Law Judge at the Board of Veterans' Appeals.
        You will be notified of the details in writing shortly.
        content
        privacy_act_pending: <<-content.squish,
        You or your representative filed a Privacy Act request. The Board placed your appeal on hold until
        this request is satisfied.
        content
        privacy_act_complete: <<-content.squish,
        The Privacy Act request has been satisfied and the Board will continue processing your appeal at
        this time.  The Board must work cases in docket order (the order received). If you have any
        questions please reach out to your Veterans Service Organization or representative, if you have
        one, or log onto VA.gov for additional information
        content
        hearing_withdrawn: <<-content.squish,
        You or your representative have requested to withdraw your hearing request. The Board will
        continue processing your appeal, but it must work cases in docket order (the order received).  For
        more information please reach out to your Veterans Service Organization or representative, if you
        have one, or contact the hearing coordinator for your region. For a list of hearing coordinators by
        region with contact information, please visit https://www.bva.va.gov.
        content
        vso_ihp_pending: <<-content.squish,
        You filed an appeal with the Board of Veterans' Appeals. Your case has been assigned to your
        Veterans Service Organization to provide written argument. Once the argument has been received,
        the Board of Veterans' Appeals will resume processing of your appeal.
        content
        vso_ihp_complete: <<-content.squish,
        The Board of Veterans' Appeals received the written argument from your Veterans Service
        Organization. The Board will continue processing your appeal, but it must work cases in docket
        order (the order received). If you have any questions please reach out to your Veterans Service
        Organization or log onto VA.gov for additional information.
        content
        appeal_decision_mailed_non_contested: <<-content.squish
        The Board of Veterans' Appeals issued a decision on your appeal that will be sent to you and to
        your representative, if you have one, shortly.
        content
      }
    end

    def create_notifications
      # Multiple Notifications for Legacy Appeal 2226048
      Notification.create(appeals_id: "2226048", appeals_type: "LegacyAppeal", event_date: 8.days.ago, event_type: "Appeal docketed", notification_type: "Email and SMS",
        recipient_email: "example@example.com", recipient_phone_number: "555-555-5555", email_notification_status: "delivered", sms_notification_status: "delivered",
        notification_content: notification_content[:appeal_docketed])
      Notification.create(appeals_id: "2226048", appeals_type: "LegacyAppeal", event_date: 7.days.ago, event_type: "Hearing scheduled", notification_type: "Email and SMS",
        recipient_email: "example@example.com", recipient_phone_number: nil, email_notification_status: "delivered",  sms_notification_status: "temporary-failure",
        notification_content: notification_content[:hearing_scheduled])
      Notification.create(appeals_id: "2226048", appeals_type: "LegacyAppeal", event_date: 6.days.ago, event_type: "Privacy Act request pending", notification_type: "Email and SMS",
        recipient_email: "example@example.com", recipient_phone_number: nil, email_notification_status: "delivered",  sms_notification_status: "temporary-failure",
        notification_content: notification_content[:privacy_act_pending])
      Notification.create(appeals_id: "2226048", appeals_type: "LegacyAppeal", event_date: 5.days.ago, event_type: "Privacy Act request complete", notification_type: "Email and SMS",
        recipient_email: "example@example.com", recipient_phone_number: nil, email_notification_status: "delivered",  sms_notification_status: "temporary-failure",
        notification_content: notification_content[:privacy_act_complete])
      Notification.create(appeals_id: "2226048", appeals_type: "LegacyAppeal", event_date: 4.days.ago, event_type: "Withdrawal of hearing", notification_type: "Email and SMS",
        recipient_email: nil, recipient_phone_number: nil, email_notification_status: "Success",  sms_notification_status: "temporary-failure",
        notification_content: notification_content[:hearing_withdrawn])
      Notification.create(appeals_id: "2226048", appeals_type: "LegacyAppeal", event_date: 3.days.ago, event_type: "VSO IHP pending", notification_type: "Email and SMS",
        recipient_email: nil, recipient_phone_number: nil, email_notification_status: "Success", sms_notification_status: "Success",
        notification_content: notification_content[:vso_ihp_pending])
      Notification.create(appeals_id: "2226048", appeals_type: "LegacyAppeal", event_date: 2.days.ago, event_type: "VSO IHP complete", notification_type: "Email and SMS",
        recipient_email: nil, recipient_phone_number: nil, email_notification_status: "Success", sms_notification_status: "Success",
        notification_content: notification_content[:vso_ihp_complete])
      Notification.create(appeals_id: "2226048", appeals_type: "LegacyAppeal", event_date: 1.days.ago, event_type: "Appeal decision mailed (Non-contested claims)",
        notification_type: "Email and SMS", recipient_email: nil, recipient_phone_number: nil, email_notification_status: "Success",
        notification_content: notification_content[:appeal_decision_mailed_non_contested],
        sms_notification_status: "permanent-failure")

      # Multiple Notifications for Legacy Appeal 2309289
      Notification.create(appeals_id: "2309289", appeals_type: "LegacyAppeal", event_date: 8.days.ago, event_type: "Appeal docketed", notification_type: "Email and SMS",
        recipient_email: "example@example.com", recipient_phone_number: "555-555-5555", email_notification_status: "delivered", sms_notification_status: "delivered",
        notification_content: notification_content[:appeal_docketed])
      Notification.create(appeals_id: "2309289", appeals_type: "LegacyAppeal", event_date: 7.days.ago, event_type: "Hearing scheduled", notification_type: "Email and SMS",
        recipient_email: "example@example.com", recipient_phone_number: nil, email_notification_status: "delivered",  sms_notification_status: "temporary-failure",
        notification_content: notification_content[:hearing_scheduled])
      Notification.create(appeals_id: "2309289", appeals_type: "LegacyAppeal", event_date: 6.days.ago, event_type: "Privacy Act request pending", notification_type: "Email and SMS",
        recipient_email: "example@example.com", recipient_phone_number: nil, email_notification_status: "delivered",  sms_notification_status: "temporary-failure",
        notification_content: notification_content[:privacy_act_pending])
      Notification.create(appeals_id: "2309289", appeals_type: "LegacyAppeal", event_date: 5.days.ago, event_type: "Privacy Act request complete", notification_type: "Email and SMS",
        recipient_email: "example@example.com", recipient_phone_number: nil, email_notification_status: "delivered",  sms_notification_status: "temporary-failure",
        notification_content: notification_content[:privacy_act_complete])
      Notification.create(appeals_id: "2309289", appeals_type: "LegacyAppeal", event_date: 4.days.ago, event_type: "Withdrawal of hearing", notification_type: "Email and SMS",
        recipient_email: nil, recipient_phone_number: nil, email_notification_status: "Success",  sms_notification_status: "temporary-failure",
        notification_content: notification_content[:hearing_withdrawn])
      Notification.create(appeals_id: "2309289", appeals_type: "LegacyAppeal", event_date: 3.days.ago, event_type: "VSO IHP pending", notification_type: "Email and SMS",
        recipient_email: nil, recipient_phone_number: nil, email_notification_status: "Success", sms_notification_status: "Success",
        notification_content: notification_content[:vso_ihp_pending])
      Notification.create(appeals_id: "2309289", appeals_type: "LegacyAppeal", event_date: 2.days.ago, event_type: "VSO IHP complete", notification_type: "Email and SMS",
        recipient_email: nil, recipient_phone_number: nil, email_notification_status: "Success", sms_notification_status: "Success",
        notification_content: notification_content[:vso_ihp_complete])
      Notification.create(appeals_id: "2309289", appeals_type: "LegacyAppeal", event_date: 1.days.ago, event_type: "Appeal decision mailed (Non-contested claims)",
        notification_type: "Email and SMS", recipient_email: nil, recipient_phone_number: nil, email_notification_status: "Success",
        notification_content: notification_content[:appeal_decision_mailed_non_contested],
        sms_notification_status: "permanent-failure")

      # Multiple Notifications for Legacy Appeal 2362049
      Notification.create(appeals_id: "2362049", appeals_type: "LegacyAppeal", event_date: 8.days.ago, event_type: "Appeal docketed", notification_type: "Email and SMS",
        recipient_email: "example@example.com", recipient_phone_number: "555-555-5555", email_notification_status: "delivered", sms_notification_status: "delivered",
        notification_content: notification_content[:appeal_docketed])
      Notification.create(appeals_id: "2362049", appeals_type: "LegacyAppeal", event_date: 7.days.ago, event_type: "Hearing scheduled", notification_type: "Email and SMS",
        recipient_email: "example@example.com", recipient_phone_number: nil, email_notification_status: "delivered",  sms_notification_status: "temporary-failure",
        notification_content: notification_content[:hearing_scheduled])
      Notification.create(appeals_id: "2362049", appeals_type: "LegacyAppeal", event_date: 6.days.ago, event_type: "Privacy Act request pending", notification_type: "Email and SMS",
        recipient_email: "example@example.com", recipient_phone_number: nil, email_notification_status: "delivered",  sms_notification_status: "temporary-failure",
        notification_content: notification_content[:privacy_act_pending])
      Notification.create(appeals_id: "2362049", appeals_type: "LegacyAppeal", event_date: 5.days.ago, event_type: "Privacy Act request complete", notification_type: "Email and SMS",
        recipient_email: "example@example.com", recipient_phone_number: nil, email_notification_status: "delivered",  sms_notification_status: "temporary-failure",
        notification_content: notification_content[:privacy_act_complete])
      Notification.create(appeals_id: "2362049", appeals_type: "LegacyAppeal", event_date: 4.days.ago, event_type: "Withdrawal of hearing", notification_type: "Email and SMS",
        recipient_email: nil, recipient_phone_number: nil, email_notification_status: "Success",  sms_notification_status: "temporary-failure",
        notification_content: notification_content[:hearing_withdrawn])
      Notification.create(appeals_id: "2362049", appeals_type: "LegacyAppeal", event_date: 3.days.ago, event_type: "VSO IHP pending", notification_type: "Email and SMS",
        recipient_email: nil, recipient_phone_number: nil, email_notification_status: "Success", sms_notification_status: "Success",
        notification_content: notification_content[:vso_ihp_pending])
      Notification.create(appeals_id: "2362049", appeals_type: "LegacyAppeal", event_date: 2.days.ago, event_type: "VSO IHP complete", notification_type: "Email and SMS",
        recipient_email: nil, recipient_phone_number: nil, email_notification_status: "Success", sms_notification_status: "Success",
        notification_content: notification_content[:vso_ihp_complete])
      Notification.create(appeals_id: "2362049", appeals_type: "LegacyAppeal", event_date: 1.days.ago, event_type: "Appeal decision mailed (Non-contested claims)",
        notification_type: "Email and SMS", recipient_email: nil, recipient_phone_number: nil, email_notification_status: "Success",
        notification_content: notification_content[:appeal_decision_mailed_non_contested],
        sms_notification_status: "permanent-failure")

      # Single Notification for Legacy Appeal 2591483
      Notification.create(appeals_id: "2591483", appeals_type: "LegacyAppeal", event_date: 1.days.ago, event_type: "Appeal docketed", notification_type: "Email and SMS",
        recipient_email: nil, recipient_phone_number: nil, email_notification_status: "Success", sms_notification_status: "Success",
        notification_content: notification_content[:appeal_docketed])

      # Single Notification for Legacy Appeal 2687879
      Notification.create(appeals_id: "2687879", appeals_type: "LegacyAppeal", event_date: 1.days.ago, event_type: "Appeal docketed", notification_type: "Email and SMS",
        recipient_email: nil, recipient_phone_number: nil, email_notification_status: "Success", sms_notification_status: "Success",
        notification_content: notification_content[:appeal_docketed])

      # Single Notification for Legacy Appeal 2727431
      Notification.create(appeals_id: "2727431", appeals_type: "LegacyAppeal", event_date: 1.days.ago, event_type: "Appeal docketed", notification_type: "Email and SMS",
        recipient_email: nil, recipient_phone_number: nil, email_notification_status: "Success", sms_notification_status: "Success",
        notification_content: notification_content[:appeal_docketed])

      # Multiple Notifications for AMA Appeal d31d7f91-91a0-46f8-b4bc-c57e139cee72
      Notification.create(appeals_id: "d31d7f91-91a0-46f8-b4bc-c57e139cee72", appeals_type: "Appeal", event_date: 8.days.ago, event_type: "Appeal docketed", notification_type: "Email and SMS",
          recipient_email: "example@example.com", recipient_phone_number: "555-555-5555", email_notification_status: "delivered", sms_notification_status: "delivered",
          notification_content: notification_content[:appeal_docketed])
      Notification.create(appeals_id: "d31d7f91-91a0-46f8-b4bc-c57e139cee72", appeals_type: "Appeal", event_date: 7.days.ago, event_type: "Hearing scheduled", notification_type: "Email and SMS",
          recipient_email: "example@example.com", recipient_phone_number: nil, email_notification_status: "delivered",  sms_notification_status: "temporary-failure",
          notification_content: notification_content[:hearing_scheduled])
      Notification.create(appeals_id: "d31d7f91-91a0-46f8-b4bc-c57e139cee72", appeals_type: "Appeal", event_date: 6.days.ago, event_type: "Privacy Act request pending", notification_type: "Email and SMS",
          recipient_email: "example@example.com", recipient_phone_number: nil, email_notification_status: "delivered",  sms_notification_status: "temporary-failure",
          notification_content: notification_content[:privacy_act_pending])
      Notification.create(appeals_id: "d31d7f91-91a0-46f8-b4bc-c57e139cee72", appeals_type: "Appeal", event_date: 5.days.ago, event_type: "Privacy Act request complete", notification_type: "Email and SMS",
          recipient_email: "example@example.com", recipient_phone_number: nil, email_notification_status: "delivered",  sms_notification_status: "temporary-failure",
          notification_content: notification_content[:privacy_act_complete])
      Notification.create(appeals_id: "d31d7f91-91a0-46f8-b4bc-c57e139cee72", appeals_type: "Appeal", event_date: 4.days.ago, event_type: "Withdrawal of hearing", notification_type: "Email and SMS",
          recipient_email: nil, recipient_phone_number: nil, email_notification_status: "Success",  sms_notification_status: "temporary-failure",
          notification_content: notification_content[:hearing_withdrawn])
      Notification.create(appeals_id: "d31d7f91-91a0-46f8-b4bc-c57e139cee72", appeals_type: "Appeal", event_date: 3.days.ago, event_type: "VSO IHP pending", notification_type: "Email and SMS",
          recipient_email: nil, recipient_phone_number: nil, email_notification_status: "Success", sms_notification_status: "Success",
          notification_content: notification_content[:vso_ihp_pending])
      Notification.create(appeals_id: "d31d7f91-91a0-46f8-b4bc-c57e139cee72", appeals_type: "Appeal", event_date: 2.days.ago, event_type: "VSO IHP complete", notification_type: "Email and SMS",
          recipient_email: nil, recipient_phone_number: nil, email_notification_status: "Success", sms_notification_status: "Success",
          notification_content: notification_content[:vso_ihp_complete])
      Notification.create(appeals_id: "d31d7f91-91a0-46f8-b4bc-c57e139cee72", appeals_type: "Appeal", event_date: 1.days.ago, event_type: "Appeal decision mailed (Non-contested claims)",
          notification_type: "Email and SMS", recipient_email: nil, recipient_phone_number: nil, email_notification_status: "Success",
          notification_content: notification_content[:appeal_decision_mailed_non_contested],
          sms_notification_status: "permanent-failure")

      # Multiple Notifications for AMA Appeal 25c4857b-3cc5-4497-a066-25be73aa4b6b
      Notification.create(appeals_id: "25c4857b-3cc5-4497-a066-25be73aa4b6b", appeals_type: "Appeal", event_date: 8.days.ago, event_type: "Appeal docketed", notification_type: "Email and SMS",
          recipient_email: "example@example.com", recipient_phone_number: "555-555-5555", email_notification_status: "delivered", sms_notification_status: "delivered",
          notification_content: notification_content[:appeal_docketed])
      Notification.create(appeals_id: "25c4857b-3cc5-4497-a066-25be73aa4b6b", appeals_type: "Appeal", event_date: 7.days.ago, event_type: "Hearing scheduled", notification_type: "Email and SMS",
          recipient_email: "example@example.com", recipient_phone_number: nil, email_notification_status: "delivered",  sms_notification_status: "temporary-failure",
          notification_content: notification_content[:hearing_scheduled])
      Notification.create(appeals_id: "25c4857b-3cc5-4497-a066-25be73aa4b6b", appeals_type: "Appeal", event_date: 6.days.ago, event_type: "Privacy Act request pending", notification_type: "Email and SMS",
          recipient_email: "example@example.com", recipient_phone_number: nil, email_notification_status: "delivered",  sms_notification_status: "temporary-failure",
          notification_content: notification_content[:privacy_act_pending])
      Notification.create(appeals_id: "25c4857b-3cc5-4497-a066-25be73aa4b6b", appeals_type: "Appeal", event_date: 5.days.ago, event_type: "Privacy Act request complete", notification_type: "Email and SMS",
          recipient_email: "example@example.com", recipient_phone_number: nil, email_notification_status: "delivered",  sms_notification_status: "temporary-failure",
          notification_content: notification_content[:privacy_act_complete])
      Notification.create(appeals_id: "25c4857b-3cc5-4497-a066-25be73aa4b6b", appeals_type: "Appeal", event_date: 4.days.ago, event_type: "Withdrawal of hearing", notification_type: "Email and SMS",
          recipient_email: nil, recipient_phone_number: nil, email_notification_status: "Success",  sms_notification_status: "temporary-failure",
          notification_content: notification_content[:hearing_withdrawn])
      Notification.create(appeals_id: "25c4857b-3cc5-4497-a066-25be73aa4b6b", appeals_type: "Appeal", event_date: 3.days.ago, event_type: "VSO IHP pending", notification_type: "Email and SMS",
          recipient_email: nil, recipient_phone_number: nil, email_notification_status: "Success", sms_notification_status: "Success",
          notification_content: notification_content[:vso_ihp_pending])
      Notification.create(appeals_id: "25c4857b-3cc5-4497-a066-25be73aa4b6b", appeals_type: "Appeal", event_date: 2.days.ago, event_type: "VSO IHP complete", notification_type: "Email and SMS",
          recipient_email: nil, recipient_phone_number: nil, email_notification_status: "Success", sms_notification_status: "Success",
          notification_content: notification_content[:vso_ihp_complete])
      Notification.create(appeals_id: "25c4857b-3cc5-4497-a066-25be73aa4b6b", appeals_type: "Appeal", event_date: 1.days.ago, event_type: "Appeal decision mailed (Non-contested claims)",
          notification_type: "Email and SMS", recipient_email: nil, recipient_phone_number: nil, email_notification_status: "Success",
          notification_content: notification_content[:appeal_decision_mailed_non_contested],
          sms_notification_status: "permanent-failure")

      # Multiple Notifications for AMA Appeal 7a060e04-1143-4e42-9ede-bdc42877f4f8
      Notification.create(appeals_id: "7a060e04-1143-4e42-9ede-bdc42877f4f8", appeals_type: "Appeal", event_date: 8.days.ago, event_type: "Appeal docketed", notification_type: "Email and SMS",
          recipient_email: "example@example.com", recipient_phone_number: "555-555-5555", email_notification_status: "delivered", sms_notification_status: "delivered",
          notification_content: notification_content[:appeal_docketed])
      Notification.create(appeals_id: "7a060e04-1143-4e42-9ede-bdc42877f4f8", appeals_type: "Appeal", event_date: 7.days.ago, event_type: "Hearing scheduled", notification_type: "Email and SMS",
          recipient_email: "example@example.com", recipient_phone_number: nil, email_notification_status: "delivered",  sms_notification_status: "temporary-failure",
          notification_content: notification_content[:hearing_scheduled])
      Notification.create(appeals_id: "7a060e04-1143-4e42-9ede-bdc42877f4f8", appeals_type: "Appeal", event_date: 6.days.ago, event_type: "Privacy Act request pending", notification_type: "Email and SMS",
          recipient_email: "example@example.com", recipient_phone_number: nil, email_notification_status: "delivered",  sms_notification_status: "temporary-failure",
          notification_content: notification_content[:privacy_act_pending])
      Notification.create(appeals_id: "7a060e04-1143-4e42-9ede-bdc42877f4f8", appeals_type: "Appeal", event_date: 5.days.ago, event_type: "Privacy Act request complete", notification_type: "Email and SMS",
          recipient_email: "example@example.com", recipient_phone_number: nil, email_notification_status: "delivered",  sms_notification_status: "temporary-failure",
          notification_content: notification_content[:privacy_act_complete])
      Notification.create(appeals_id: "7a060e04-1143-4e42-9ede-bdc42877f4f8", appeals_type: "Appeal", event_date: 4.days.ago, event_type: "Withdrawal of hearing", notification_type: "Email and SMS",
          recipient_email: nil, recipient_phone_number: nil, email_notification_status: "Success",  sms_notification_status: "temporary-failure",
          notification_content: notification_content[:hearing_withdrawn])
      Notification.create(appeals_id: "7a060e04-1143-4e42-9ede-bdc42877f4f8", appeals_type: "Appeal", event_date: 3.days.ago, event_type: "VSO IHP pending", notification_type: "Email and SMS",
          recipient_email: nil, recipient_phone_number: nil, email_notification_status: "Success", sms_notification_status: "Success",
          notification_content: notification_content[:vso_ihp_pending])
      Notification.create(appeals_id: "7a060e04-1143-4e42-9ede-bdc42877f4f8", appeals_type: "Appeal", event_date: 2.days.ago, event_type: "VSO IHP complete", notification_type: "Email and SMS",
          recipient_email: nil, recipient_phone_number: nil, email_notification_status: "Success", sms_notification_status: "Success",
          notification_content: notification_content[:vso_ihp_complete])
      Notification.create(appeals_id: "7a060e04-1143-4e42-9ede-bdc42877f4f8", appeals_type: "Appeal", event_date: 1.days.ago, event_type: "Appeal decision mailed (Non-contested claims)",
          notification_type: "Email and SMS", recipient_email: nil, recipient_phone_number: nil, email_notification_status: "Success",
          notification_content: notification_content[:appeal_decision_mailed_non_contested],
          sms_notification_status: "permanent-failure")

      # Single Notification for AMA Appeal 952b6490-a10a-484b-a29b-31489e9a6e5a
      Notification.create(appeals_id: "952b6490-a10a-484b-a29b-31489e9a6e5a", appeals_type: "Appeal", event_date: 8.days.ago, event_type: "Appeal docketed", notification_type: "Email and SMS",
          recipient_email: "example@example.com", recipient_phone_number: nil, email_notification_status: "delivered", sms_notification_status: "permanent-failure",
          notification_content: notification_content[:appeal_docketed])

      # Single Notification for AMA Appeal fb3b029f-f07e-45bf-9277-809b44f7451a
      Notification.create(appeals_id: "fb3b029f-f07e-45bf-9277-809b44f7451a", appeals_type: "Appeal", event_date: 8.days.ago, event_type: "Appeal docketed", notification_type: "Email and SMS",
          recipient_email: "example@example.com", recipient_phone_number: nil, email_notification_status: "delivered", sms_notification_status: "permanent-failure",
          notification_content: notification_content[:appeal_docketed])

      # Single Notification for AMA Appeal 2b3afced-f698-4abe-84f9-6d44f26d20d4
      Notification.create(appeals_id: "2b3afced-f698-4abe-84f9-6d44f26d20d4", appeals_type: "Appeal", event_date: 8.days.ago, event_type: "Appeal docketed", notification_type: "Email and SMS",
          recipient_email: "example@example.com", recipient_phone_number: nil, email_notification_status: "delivered", sms_notification_status: "permanent-failure",
          notification_content: notification_content[:appeal_docketed])

      # Notifications of No Participant Id Found, No Claimant Found, and No External Id for Legacy Appeal 3565723
      3565723
      Notification.create(appeals_id: "3565723", appeals_type: "LegacyAppeal", event_date: 8.days.ago, event_type: "Appeal docketed", notification_type: "Email and SMS",
        recipient_email: "example@example.com", recipient_phone_number: "555-555-5555", email_notification_status: "No Participant Id Found", sms_notification_status: "No Participant Id Found")
      Notification.create(appeals_id: "3565723", appeals_type: "LegacyAppeal", event_date: 7.days.ago, event_type: "Hearing scheduled", notification_type: "Email and SMS",
        recipient_email: "example@example.com", recipient_phone_number: "555-555-5555", email_notification_status: "No Claimant Found",  sms_notification_status: "No Claimant Found")
      Notification.create(appeals_id: "3565723", appeals_type: "LegacyAppeal", event_date: 6.days.ago, event_type: "Privacy Act request pending", notification_type: "Email and SMS",
        recipient_email: "example@example.com", recipient_phone_number: "555-555-5555", email_notification_status: "No External Id",  sms_notification_status: "No External Id")

      # Notifications of No Participant Id Found, No Claimant Found, and No External Id for AMA Appeal ea2303e9-2bab-472b-a653-94b71bca8ca3
      3565723
      Notification.create(appeals_id: "ea2303e9-2bab-472b-a653-94b71bca8ca3", appeals_type: "Appeal", event_date: 8.days.ago, event_type: "Appeal docketed", notification_type: "Email and SMS",
        recipient_email: "example@example.com", recipient_phone_number: "555-555-5555", email_notification_status: "No Participant Id Found", sms_notification_status: "No Participant Id Found")
      Notification.create(appeals_id: "ea2303e9-2bab-472b-a653-94b71bca8ca3", appeals_type: "Appeal", event_date: 7.days.ago, event_type: "Hearing scheduled", notification_type: "Email and SMS",
        recipient_email: "example@example.com", recipient_phone_number: "555-555-5555", email_notification_status: "No Claimant Found",  sms_notification_status: "No Claimant Found")
      Notification.create(appeals_id: "ea2303e9-2bab-472b-a653-94b71bca8ca3", appeals_type: "Appeal", event_date: 6.days.ago, event_type: "Privacy Act request pending", notification_type: "Email and SMS",
        recipient_email: "example@example.com", recipient_phone_number: "555-555-5555", email_notification_status: "No External Id",  sms_notification_status: "No External Id")
    end
  end
end
