module Seeds
  class Intake < Base
    def seed!
      create_intake_users
      create_higher_level_review_tasks
      create_ama_appeals
      create_higher_level_reviews_and_supplemental_claims
      create_inbox_messages
    end

    private

    def create_intake_users
      ["Mail Intake", "Admin Intake"].each do |role|
        User.create(css_id: "#{role.tr(' ', '')}_LOCAL", roles: [role], station_id: "101", full_name: "Jame Local #{role} Smith")
      end
    end

    def create_higher_level_review_tasks
      6.times do
        veteran = FactoryBot.create(:veteran)
        epe = FactoryBot.create(:end_product_establishment, veteran_file_number: veteran.file_number)
        higher_level_review = FactoryBot.create(
          :higher_level_review,
          end_product_establishments: [epe],
          veteran_file_number: veteran.file_number
        )
        3.times do
          FactoryBot.create(:request_issue,
                            :nonrating,
                            end_product_establishment: epe,
                            veteran_participant_id: veteran.participant_id,
                            decision_review: higher_level_review)
        end
        nca = BusinessLine.find_or_create_by(name: "National Cemetery Administration", url: "nca")
        FactoryBot.create(:higher_level_review_task,
                          assigned_to: nca,
                          appeal: higher_level_review)
      end
    end
  
    def create_ama_appeals
      notes = "Pain disorder with 100\% evaluation per examination"
  
      FactoryBot.create(
        :appeal,
        claimants: [
          FactoryBot.build(:claimant, participant_id: "CLAIMANT_WITH_PVA_AS_VSO"),
          FactoryBot.build(:claimant, participant_id: "OTHER_CLAIMANT")
        ],
        veteran_file_number: "701305078",
        docket_type: Constants.AMA_DOCKETS.direct_review,
        request_issues: FactoryBot.create_list(:request_issue, 3, :nonrating, notes: notes)
      )
  
      es = Constants.AMA_DOCKETS.evidence_submission
      dr = Constants.AMA_DOCKETS.direct_review
      # Older style, tasks to be created later
      [
        { number_of_claimants: nil, veteran_file_number: "783740847", docket_type: es, request_issue_count: 3 },
        { number_of_claimants: 1, veteran_file_number: "228081153", docket_type: es, request_issue_count: 1 },
        { number_of_claimants: 1, veteran_file_number: "152003980", docket_type: dr, request_issue_count: 3 },
        { number_of_claimants: 1, veteran_file_number: "375273128", docket_type: dr, request_issue_count: 1 },
        { number_of_claimants: 1, veteran_file_number: "682007349", docket_type: dr, request_issue_count: 5 },
        { number_of_claimants: 1, veteran_file_number: "231439628", docket_type: dr, request_issue_count: 1 },
        { number_of_claimants: 1, veteran_file_number: "975191063", docket_type: dr, request_issue_count: 8 },
        { number_of_claimants: 1, veteran_file_number: "662643660", docket_type: dr, request_issue_count: 8 },
        { number_of_claimants: 1, veteran_file_number: "162726229", docket_type: dr, request_issue_count: 8 },
        { number_of_claimants: 1, veteran_file_number: "760362568", docket_type: dr, request_issue_count: 8 }
      ].each do |params|
        FactoryBot.create(
          :appeal,
          number_of_claimants: params[:number_of_claimants],
          veteran_file_number: params[:veteran_file_number],
          docket_type: params[:docket_type],
          request_issues: FactoryBot.create_list(
            :request_issue, params[:request_issue_count], :nonrating, notes: notes
          )
        )
      end
  
      # Newer style, tasks created through the Factory trait
      [
        { number_of_claimants: nil, veteran_file_number: "963360019", docket_type: dr, request_issue_count: 2 },
        { number_of_claimants: 1, veteran_file_number: "604969679", docket_type: dr, request_issue_count: 1 }
      ].each do |params|
        FactoryBot.create(
          :appeal,
          :assigned_to_judge,
          number_of_claimants: params[:number_of_claimants],
          active_task_assigned_at: Time.zone.now,
          veteran_file_number: params[:veteran_file_number],
          docket_type: params[:docket_type],
          closest_regional_office: "RO17",
          request_issues: FactoryBot.create_list(
            :request_issue, params[:request_issue_count], :nonrating, notes: notes
          )
        )
      end
      # Create AMA tasks ready for distribution
      (1..30).each do |num|
        vet_file_number = format("3213213%02d", num)
        FactoryBot.create(
          :appeal,
          :ready_for_distribution,
          number_of_claimants: 1,
          active_task_assigned_at: Time.zone.now,
          veteran_file_number: vet_file_number,
          docket_type: Constants.AMA_DOCKETS.direct_review,
          closest_regional_office: "RO17",
          request_issues: FactoryBot.create_list(
            :request_issue, 2, :nonrating, notes: notes
          )
        )
      end
  
      LegacyAppeal.create(vacols_id: "2096907", vbms_id: "228081153S")
      LegacyAppeal.create(vacols_id: "2226048", vbms_id: "213912991S")
      LegacyAppeal.create(vacols_id: "2249056", vbms_id: "608428712S")
      LegacyAppeal.create(vacols_id: "2306397", vbms_id: "779309925S")
      LegacyAppeal.create(vacols_id: "2657227", vbms_id: "169397130S")
    end
  
    def create_higher_level_reviews_and_supplemental_claims
      veteran_file_number = "682007349"
      veteran = Veteran.find_by(file_number: veteran_file_number)
  
      ep_rating_code = "030HLRR"
      ep_nonrating_code = "030HLRNR"
  
      one_day_in_seconds = 60 * 60 * 24
      two_days_in_seconds = 2 * one_day_in_seconds
      thirty_days_in_seconds = 30 * one_day_in_seconds
  
      higher_level_review = HigherLevelReview.create!(
        veteran_file_number: veteran_file_number,
        receipt_date: Time.zone.now - thirty_days_in_seconds,
        informal_conference: false,
        same_office: false,
        benefit_type: "compensation"
      )
      higher_level_review.create_claimant!(
        participant_id: "5382910292",
        payee_code: "10"
      )
  
      EndProductEstablishment.create!(
        source: higher_level_review,
        veteran_file_number: veteran.file_number,
        claim_date: Time.zone.now - thirty_days_in_seconds,
        code: ep_rating_code,
        station: "397",
        benefit_type_code: "1",
        payee_code: "00",
        synced_status: "CAN",
        claimant_participant_id: veteran.participant_id
      )
  
      EndProductEstablishment.create!(
        source: higher_level_review,
        veteran_file_number: veteran.file_number,
        claim_date: Time.zone.now - thirty_days_in_seconds,
        code: ep_rating_code,
        station: "397",
        benefit_type_code: "1",
        payee_code: "00",
        synced_status: nil,
        claimant_participant_id: veteran.participant_id
      )
  
      EndProductEstablishment.create!(
        source: higher_level_review,
        veteran_file_number: veteran.file_number,
        claim_date: Time.zone.now - thirty_days_in_seconds,
        code: ep_rating_code,
        station: "397",
        benefit_type_code: "1",
        payee_code: "00",
        synced_status: "PEND",
        claimant_participant_id: veteran.participant_id
      )
  
      EndProductEstablishment.create!(
        source: higher_level_review,
        veteran_file_number: veteran.file_number,
        claim_date: Time.zone.now - thirty_days_in_seconds,
        code: ep_rating_code,
        station: "397",
        benefit_type_code: "1",
        payee_code: "00",
        synced_status: "CLR",
        last_synced_at: Time.zone.now - one_day_in_seconds,
        claimant_participant_id: veteran.participant_id
      )
  
      EndProductEstablishment.create!(
        source: higher_level_review,
        veteran_file_number: veteran.file_number,
        claim_date: Time.zone.now - thirty_days_in_seconds,
        code: ep_nonrating_code,
        station: "397",
        benefit_type_code: "1",
        payee_code: "00",
        synced_status: "CLR",
        last_synced_at: Time.zone.now - two_days_in_seconds,
        claimant_participant_id: veteran.participant_id
      )
  
      EndProductEstablishment.create!(
        source: higher_level_review,
        veteran_file_number: veteran.file_number,
        claim_date: Time.zone.now - thirty_days_in_seconds,
        code: ep_rating_code,
        station: "397",
        benefit_type_code: "1",
        payee_code: "00",
        synced_status: "LOL",
        claimant_participant_id: veteran.participant_id
      )
  
      eligible_request_issue = RequestIssue.create!(
        decision_review: higher_level_review,
        nonrating_issue_category: "Military Retired Pay",
        nonrating_issue_description: "nonrating description",
        contention_reference_id: "1234",
        ineligible_reason: nil,
        benefit_type: "compensation",
        decision_date: Date.new(2018, 5, 1)
      )
  
      untimely_request_issue = RequestIssue.create!(
        decision_review: higher_level_review,
        nonrating_issue_category: "Active Duty Adjustments",
        nonrating_issue_description: "nonrating description",
        contention_reference_id: "12345",
        decision_date: Date.new(2018, 5, 1),
        benefit_type: "compensation",
        ineligible_reason: :untimely
      )
  
      higher_level_review.create_issues!([
                                           eligible_request_issue,
                                           untimely_request_issue
                                         ])
      higher_level_review.establish!
  
      SupplementalClaim.create(
        veteran_file_number: veteran.file_number,
        receipt_date: Time.zone.now,
        benefit_type: "compensation"
      )
    end

    def create_inbox_messages
      user = User.find_or_create_by(css_id: "BVASYELLOW", station_id: "101")
  
      veteran1 = FactoryBot.create(:veteran)
      veteran2 = FactoryBot.create(:veteran)
  
      appeal1 = FactoryBot.create(:appeal, veteran_file_number: veteran1.file_number)
      appeal2 = FactoryBot.create(
        :legacy_appeal,
        vacols_case: FactoryBot.create(:case),
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
  end
end
