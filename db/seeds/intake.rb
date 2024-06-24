# frozen_string_literal: true

# create intake-related seeds

module Seeds
  class Intake < Base
    def seed!
      create_intake_users
      create_higher_level_review_tasks
      create_higher_level_reviews_and_supplemental_claims
      create_inbox_messages
      create_bgs_attorneys
      create_deceased_veteran
      create_veteran_with_no_dependents
      create_deceased_veteran_with_no_dependents
    end

    private

    def create_intake_users
      ["Mail Intake", "Admin Intake"].each do |role|
        # do not try to recreate when running seed file after inital seed
        next if User.find_by_css_id("#{role.tr(' ', '')}_LOCAL".upcase)

        create(:user,
               css_id: "#{role.tr(' ', '')}_LOCAL",
               roles: [role],
               station_id: "101",
               full_name: "Jame Local #{role} Smith")
      end
    end

    def create_deceased_veteran
      params = { first_name: "Ed", last_name: "Deceased", date_of_death: Time.zone.yesterday }
      params[:file_number] = 45_454_545 unless Veteran.find_by(file_number: 45_454_545)
      create(:veteran,
             params)
    end

    def create_veteran_with_no_dependents
      params = { first_name: "Robert", last_name: "Lonely" }
      params[:file_number] = 44_444_444 unless Veteran.find_by(file_number: 44_444_444)
      params[:participant_id] = 44_444_444 unless Veteran.find_by(file_number: 44_444_444)
      create(:veteran,
             params)
    end

    def create_deceased_veteran_with_no_dependents
      params = { first_name: "Karen", last_name: "Lonely", date_of_death: Time.zone.yesterday }
      params[:file_number] = 55_555_555 unless Veteran.find_by(file_number: 55_555_555)
      params[:participant_id] = 55_555_555 unless Veteran.find_by(file_number: 55_555_555)
      create(:veteran,
             params)
    end

    def create_higher_level_review_tasks
      6.times do
        veteran = create(:veteran)
        epe = create(:end_product_establishment, veteran_file_number: veteran.file_number)
        higher_level_review = create(
          :higher_level_review,
          end_product_establishments: [epe],
          veteran_file_number: veteran.file_number
        )
        3.times do
          create(:request_issue,
                 :nonrating,
                 end_product_establishment: epe,
                 veteran_participant_id: veteran.participant_id,
                 decision_review: higher_level_review)
        end
        nca = BusinessLine.find_or_create_by(name: "National Cemetery Administration", url: "nca")
        create(:higher_level_review_task,
               assigned_to: nca,
               appeal: higher_level_review)
      end
    end

    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/MethodLength
    def create_higher_level_reviews_and_supplemental_claims
      veteran = create(:veteran)

      ep_rating_code = "030HLRR"
      ep_nonrating_code = "030HLRNR"

      one_day_in_seconds = 60 * 60 * 24
      two_days_in_seconds = 2 * one_day_in_seconds
      thirty_days_in_seconds = 30 * one_day_in_seconds

      higher_level_review = create(:higher_level_review,
                                   veteran_file_number: veteran.file_number,
                                   receipt_date: Time.zone.now - thirty_days_in_seconds,
                                   informal_conference: false,
                                   same_office: false,
                                   benefit_type: "compensation",
                                   veteran_is_not_claimant: true,
                                   number_of_claimants: 1)

      create(:end_product_establishment,
             source: higher_level_review,
             veteran_file_number: veteran.file_number,
             claim_date: Time.zone.now - thirty_days_in_seconds,
             code: ep_rating_code,
             station: "397",
             benefit_type_code: "1",
             payee_code: "00",
             synced_status: "CAN",
             claimant_participant_id: veteran.participant_id)

      create(:end_product_establishment,
             source: higher_level_review,
             veteran_file_number: veteran.file_number,
             claim_date: Time.zone.now - thirty_days_in_seconds,
             code: ep_rating_code,
             station: "397",
             benefit_type_code: "1",
             payee_code: "00",
             synced_status: nil,
             claimant_participant_id: veteran.participant_id)

      create(:end_product_establishment,
             source: higher_level_review,
             veteran_file_number: veteran.file_number,
             claim_date: Time.zone.now - thirty_days_in_seconds,
             code: ep_rating_code,
             station: "397",
             benefit_type_code: "1",
             payee_code: "00",
             synced_status: "PEND",
             claimant_participant_id: veteran.participant_id)

      create(:end_product_establishment,
             source: higher_level_review,
             veteran_file_number: veteran.file_number,
             claim_date: Time.zone.now - thirty_days_in_seconds,
             code: ep_rating_code,
             station: "397",
             benefit_type_code: "1",
             payee_code: "00",
             synced_status: "CLR",
             last_synced_at: Time.zone.now - one_day_in_seconds,
             claimant_participant_id: veteran.participant_id)

      create(:end_product_establishment,
             source: higher_level_review,
             veteran_file_number: veteran.file_number,
             claim_date: Time.zone.now - thirty_days_in_seconds,
             code: ep_nonrating_code,
             station: "397",
             benefit_type_code: "1",
             payee_code: "00",
             synced_status: "CLR",
             last_synced_at: Time.zone.now - two_days_in_seconds,
             claimant_participant_id: veteran.participant_id)

      create(:end_product_establishment,
             source: higher_level_review,
             veteran_file_number: veteran.file_number,
             claim_date: Time.zone.now - thirty_days_in_seconds,
             code: ep_rating_code,
             station: "397",
             benefit_type_code: "1",
             payee_code: "00",
             synced_status: "LOL",
             claimant_participant_id: veteran.participant_id)

      eligible_request_issue =
        create(:request_issue,
               decision_review: higher_level_review,
               nonrating_issue_category: "Military Retired Pay",
               nonrating_issue_description: "nonrating description",
               ineligible_reason: nil,
               benefit_type: "compensation",
               decision_date: Date.new(2018, 5, 1))

      untimely_request_issue =
        create(:request_issue,
               decision_review: higher_level_review,
               nonrating_issue_category: "Active Duty Adjustments",
               nonrating_issue_description: "nonrating description",
               decision_date: Date.new(2018, 5, 1),
               benefit_type: "compensation",
               ineligible_reason: :untimely)

      higher_level_review.create_issues!([
                                           eligible_request_issue,
                                           untimely_request_issue
                                         ])
      higher_level_review.establish!

      create(:supplemental_claim,
             veteran_file_number: veteran.file_number,
             receipt_date: Time.zone.now,
             benefit_type: "compensation")
    end
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/MethodLength

    # rubocop:disable Metrics/MethodLength
    def create_inbox_messages
      user = User.find_or_create_by(css_id: "BVASYELLOW", station_id: "101")

      veteran1 = create(:veteran)
      veteran2 = create(:veteran)

      appeal1 = create(:appeal, veteran_file_number: veteran1.file_number)
      appeal2 = create(
        :legacy_appeal,
        vacols_case: create(:case, :type_original, bfcorlid: veteran2.file_number),
        vbms_id: "#{veteran2.file_number}S"
      )

      message1 = <<~MSG
        <a href="/queue/appeals/#{appeal1.uuid}">Veteran ID #{veteran1.file_number}</a> - Virtual hearing not scheduled
        Caseflow is having trouble contacting the virtual hearing scheduler.
        For help, submit a support ticket using <a href="https://yourit.va.gov/">YourIT</a>.
      MSG

      message2 = <<~MSG
        <a href="/queue/appeals/#{appeal2.vacols_id}">Veteran ID #{veteran2.file_number}</a> - Hearing time not updated
        Caseflow is having trouble contacting the virtual hearing scheduler.
        For help, submit a support ticket using <a href="https://yourit.va.gov/">YourIT</a>.
      MSG

      Message.create(text: message1, detail: appeal1, user: user)
      Message.create(text: message2, detail: appeal2, user: user)
    end
    # rubocop:enable Metrics/MethodLength

    def create_bgs_attorneys
      5000.times { create(:bgs_attorney) } if BgsAttorney.count < 5000
    end
  end
end
