# frozen_string_literal: true

module Seeds
  class NonSscAvljLegacyAppeals < Base
    def initialize
      # initialize_np_legacy_appeals_file_number_and_participant_id
      # initialize_priority_legacy_appeals_file_number_and_participant_id
    end

    def seed!
      RequestStore[:current_user] = User.system_user
      create_avljs
      create_legacy_appeals
    end

    private

    def create_avljs
      create_non_ssc_avlj("NONSSCAN01", "Four Priority")
      create_non_ssc_avlj("NONSSCAN02", "Four non-priority")
      create_non_ssc_avlj("NONSSCAN03", "Four-pri h-and-d")
      create_non_ssc_avlj("NONSSCAN04", "Four-non-pri h-and-d")
      create_non_ssc_avlj("NONSSCAN05", "For-mix-of both-h-only")
      create_non_ssc_avlj("NONSSCAN06", "For-mix-of both-h-and-d")
      create_non_ssc_avlj("NONSSCAN07", "Do-not-get moved-pri")
      create_non_ssc_avlj("NONSSCAN08", "Do-not-get moved-nonpri")
      create_non_ssc_avlj("NONSSCAN09", "Do-not-get moved-mix")
      create_non_ssc_avlj("NONSSCAN10", "Some-moved some-not")
      create_ssc_avlj("SSCA11", "Does-not qualify for-mvmt")
      create_non_ssc_avlj("NONSSCAN12", "Two-judges last-is-SSC")
      create_non_ssc_avlj("NONSSCAN13", "Two-judges both-non-SSC")
      create_inactive_non_ssc_avlj("NONSSCAN14", "Inactive Non")
      create_vlj("REGVLJ01", "Regular VLJ1")
      create_vlj("REGVLJ02", "Regular VLJ2")
      create_non_ssc_avlj("SIGNAVLJLGC", "NonSSC Signing-AVLJ")
      create_non_ssc_avlj("AVLJLGC2", "Alternate NonSSC-AVLJ")
      create_ssc_avlj("SSCAVLJLGC", "SSC-Two-judges last-is-SSC")
    end

    def create_legacy_appeals
      # the naming comes from the acceptance criteria of APPEALS-45208
      create_four_priority_appeals_tied_to_a_non_ssc_avlj
      create_four_non_priority_appeals_tied_to_a_non_ssc_avlj
      create_four_priority_appeals_tied_to_and_signed_by_a_non_ssc_avlj
      create_four_non_priority_appeals_tied_to_and_signed_by_a_non_ssc_avlj
      create_four_alternating_priority_by_age_appeals_tied_to_a_non_ssc_avlj
      create_four_alternating_priority_by_age_appeals_tied_to_and_signed_by_a_non_ssc_avlj
      create_four_priority_appeals_tied_to_a_non_ssc_avlj_signed_by_another_avlj
      create_four_non_priority_appeals_tied_to_a_non_ssc_avlj_signed_by_another_avlj
      create_four_alternating_priority_by_age_appeals_tied_to_a_non_ssc_avlj_signed_by_another_avlj
      create_two_sets_of_seven_types_of_appeals_tied_to_a_non_ssc_avlj
      create_four_alternating_priority_by_age_appeals_tied_to_a_ssc_avlj
      create_four_alternating_priority_by_age_appeals_tied_to_a_non_ssc_avlj_with_a_second_hearing_held_by_a_ssc_avlj
      create_four_alternating_priority_by_age_appeals_tied_to_a_non_ssc_avlj_with_a_second_hearing_held_by_another_non_ssc_avlj
      create_unsigned_priority_appeal_tied_to_inactive_non_ssc_avlj
      create_signed_non_priority_appeal_tied_to_inactive_non_ssc_avlj
      create_unsigned_priority_ama_appeal_tied_to_non_ssc_avlj
      create_signed_non_priority_ama_appeal_tied_to_non_ssc_avlj
      create_signed_priority_appeal_tied_to_vlj
      create_unsigned_non_priority_appeal_tied_to_vlj
    end

    def create_four_priority_appeals_tied_to_a_non_ssc_avlj
      # A non-SSC AVLJ that Only has 4 priority cases where they held the last hearing
      avlj = User.find_by(css_id: "NONSSCAN01")
      create_legacy_appeal(priority=true, avlj, 300.days.ago)
      create_legacy_appeal(priority=true, avlj, 200.days.ago)
      create_legacy_appeal(priority=true, avlj, 100.days.ago)
      create_legacy_appeal(priority=true, avlj, 30.days.ago)
    end

    def create_four_non_priority_appeals_tied_to_a_non_ssc_avlj
      # A non-SSC AVLJ that Only has 4 non-priority cases where they held the last hearing
      avlj = User.find_by(css_id: "NONSSCAN02")
      create_legacy_appeal(priority=false, avlj, 350.days.ago)
      create_legacy_appeal(priority=false, avlj, 250.days.ago)
      create_legacy_appeal(priority=false, avlj, 150.days.ago)
      create_legacy_appeal(priority=false, avlj, 50.days.ago)
    end

    def create_four_priority_appeals_tied_to_and_signed_by_a_non_ssc_avlj
      assigned_avlj = User.find_by(css_id: "NONSSCAN03")
      signing_avlj = User.find_by(css_id: "NONSSCAN03")
      create_signed_legacy_appeal(priority=true, signing_avlj, assigned_avlj, 100.days.ago)
      create_signed_legacy_appeal(priority=true, signing_avlj, assigned_avlj, 80.days.ago)
      create_signed_legacy_appeal(priority=true, signing_avlj, assigned_avlj, 60.days.ago)
      create_signed_legacy_appeal(priority=true, signing_avlj, assigned_avlj, 30.days.ago)
    end

    def create_four_non_priority_appeals_tied_to_and_signed_by_a_non_ssc_avlj
      # A non-SSC AVLJ that Only has 4 non-priority cases where they held the last hearing and signed the most recent decision
      assigned_avlj = User.find_by(css_id: "NONSSCAN04")
      signing_avlj = User.find_by(css_id: "NONSSCAN04")
      create_signed_legacy_appeal(priority=false, signing_avlj, assigned_avlj, 110.days.ago)
      create_signed_legacy_appeal(priority=false, signing_avlj, assigned_avlj, 90.days.ago)
      create_signed_legacy_appeal(priority=false, signing_avlj, assigned_avlj, 70.days.ago)
      create_signed_legacy_appeal(priority=false, signing_avlj, assigned_avlj, 40.days.ago)
    end

    def create_four_alternating_priority_by_age_appeals_tied_to_a_non_ssc_avlj
      # A non-SSC AVLJ that Has 4 in alternating order by age of BRIEFF.BFD19 (Docket Date)
      # priority cases where they held the last hearing
      # non-priority cases where they held the last hearing
      avlj = User.find_by(css_id: "NONSSCAN05")
      create_legacy_appeal(priority=false, avlj, 600.days.ago) #oldest
      create_legacy_appeal(priority=true, avlj, 425.days.ago)
      create_legacy_appeal(priority=false, avlj, 400.days.ago)
      create_legacy_appeal(priority=true, avlj, 40.days.ago) #most recent
    end

    def create_four_alternating_priority_by_age_appeals_tied_to_and_signed_by_a_non_ssc_avlj
      # A non-SSC AVLJ that Has 4 in alternating order by age of BRIEFF.BFD19 (Docket Date)
      # priority cases where they held the last hearing and signed the most recent decision
      # non-priority cases where they held the last hearing and signed the most recent decision
      signing_avlj = User.find_by(css_id: "NONSSCAN06")
      assigned_avlj = User.find_by(css_id: "NONSSCAN06")
      create_signed_legacy_appeal(priority=false, signing_avlj, assigned_avlj, 120.days.ago) #oldest
      create_signed_legacy_appeal(priority=true, signing_avlj, assigned_avlj, 110.days.ago)
      create_signed_legacy_appeal(priority=false, signing_avlj, assigned_avlj, 100.days.ago)
      create_signed_legacy_appeal(priority=true, signing_avlj, assigned_avlj, 50.days.ago) #most recent
    end

    def create_four_priority_appeals_tied_to_a_non_ssc_avlj_signed_by_another_avlj
      # A non-SSC AVLJ that Only has 4 priority cases where they held the last hearing and did NOT sign the most recent decision
      # These cases should NOT be returned to the board
      assigned_avlj = User.find_by(css_id: "NONSSCAN07")
      signing_avlj = User.find_by(css_id: "SIGNAVLJLGC")
      create_signed_legacy_appeal(priority=true, signing_avlj, assigned_avlj, 120.days.ago)
      create_signed_legacy_appeal(priority=true, signing_avlj, assigned_avlj, 110.days.ago)
      create_signed_legacy_appeal(priority=true, signing_avlj, assigned_avlj, 100.days.ago)
      create_signed_legacy_appeal(priority=true, signing_avlj, assigned_avlj, 50.days.ago)
    end

    def create_four_non_priority_appeals_tied_to_a_non_ssc_avlj_signed_by_another_avlj
      # A non-SSC AVLJ that Only has 4 non-priority cases where they held the last hearing and did NOT sign the most recent decision
      # These cases should NOT be returned to the board
      assigned_avlj = User.find_by(css_id: "NONSSCAN08")
      signing_avlj = User.find_by(css_id: "SIGNAVLJLGC")
      create_signed_legacy_appeal(priority=false, signing_avlj, assigned_avlj, 120.days.ago)
      create_signed_legacy_appeal(priority=false, signing_avlj, assigned_avlj, 110.days.ago)
      create_signed_legacy_appeal(priority=false, signing_avlj, assigned_avlj, 100.days.ago)
      create_signed_legacy_appeal(priority=false, signing_avlj, assigned_avlj, 50.days.ago)
    end

    def create_four_alternating_priority_by_age_appeals_tied_to_a_non_ssc_avlj_signed_by_another_avlj
      # A non-SSC AVLJ that Has 4 in alternating order by age of BRIEFF.BFD19 (Docket Date)
      # priority cases where they held the last hearing and did NOT sign the most recent decision
      # These cases should NOT be returned to the board
      # non-priority cases where they held the last hearing and did NOT sign the most recent decision
      # These cases should NOT be returned to the board
      assigned_avlj = User.find_by(css_id: "NONSSCAN09")
      signing_avlj = User.find_by(css_id: "SIGNAVLJLGC")
      create_signed_legacy_appeal(priority=false, signing_avlj, assigned_avlj, 220.days.ago) #oldest
      create_signed_legacy_appeal(priority=true, signing_avlj, assigned_avlj, 210.days.ago)
      create_signed_legacy_appeal(priority=false, signing_avlj, assigned_avlj, 200.days.ago)
      create_signed_legacy_appeal(priority=true, signing_avlj, assigned_avlj, 150.days.ago) #most recent
    end

    def create_two_sets_of_seven_types_of_appeals_tied_to_a_non_ssc_avlj
      # A non-SSC AVLJ that Has 12 appeals
      # Notes
      # Cycle through the groups before creating the second appeal in the group, make each created appeal newer by BRIEFF.BFD19 (Docket Date) than the previous one
      # Appeals in the same group should not be grouped next to each other
      # appeals
      # 1. priority cases where they held the last hearing and did NOT sign the most recent decision
      # These cases should NOT be returned to the board
      # 2. non-priority cases where they held the last hearing and did NOT sign the most recent decision
      # These cases should NOT be returned to the board
      # 3. priority cases where they held the last hearing
      # 4. non-priority cases where they held the last hearing
      # 5. priority cases where they held the last hearing and signed the most recent decision
      # 6. non-priority cases where they held the last hearing and signed the most recent decision
      # 7. has an appeal with a hearing where they were the judge but the appeal is NOT ready to distribute
      # This case would NOT show up in the ready to distribute query, but we could look it up by veteran ID to verify that it didn't get moved.

      assigned_avlj = User.find_by(css_id: "NONSSCAN10")
      signing_avlj = User.find_by(css_id: "SIGNAVLJLGC")
      create_signed_legacy_appeal(priority=false, signing_avlj, assigned_avlj, 220.days.ago) #oldest
      create_signed_legacy_appeal(priority=true, signing_avlj, assigned_avlj, 210.days.ago)
      create_legacy_appeal(priority=true, assigned_avlj, 200.days.ago)
      create_legacy_appeal(priority=false, assigned_avlj, 190.days.ago)
      create_signed_legacy_appeal(priority=false, assigned_avlj, assigned_avlj, 180.days.ago)
      create_signed_legacy_appeal(priority=true, assigned_avlj, assigned_avlj, 170.days.ago)
      legacy_appeal = create_legacy_appeal(priority=true, assigned_avlj, 160.days.ago)
      make_legacy_appeal_not_ready_for_distribution(legacy_appeal)

      create_signed_legacy_appeal(priority=false, signing_avlj, assigned_avlj, 150.days.ago)
      create_signed_legacy_appeal(priority=true, signing_avlj, assigned_avlj, 140.days.ago)
      create_legacy_appeal(priority=true, assigned_avlj, 130.days.ago)
      create_legacy_appeal(priority=false, assigned_avlj, 120.days.ago)
      create_signed_legacy_appeal(priority=false, assigned_avlj, assigned_avlj, 110.days.ago)
      create_signed_legacy_appeal(priority=true, assigned_avlj, assigned_avlj, 100.days.ago)
      legacy_appeal = create_legacy_appeal(priority=true, assigned_avlj, 90.days.ago)
      make_legacy_appeal_not_ready_for_distribution(legacy_appeal)#most recent
    end

    def create_four_alternating_priority_by_age_appeals_tied_to_a_ssc_avlj
      # A SSC AVLJ that has 4 appeals for which they held the last hearing.
      # These cases should NOT be returned to the board
      ssc_avlj = User.find_by(css_id: "SSCA11")
      create_legacy_appeal(priority=true, ssc_avlj, 325.days.ago)
      create_legacy_appeal(priority=false, ssc_avlj, 275.days.ago)
      create_legacy_appeal(priority=true, ssc_avlj, 175.days.ago)
      create_legacy_appeal(priority=false, ssc_avlj, 75.days.ago)
    end

    def create_four_alternating_priority_by_age_appeals_tied_to_a_non_ssc_avlj_with_a_second_hearing_held_by_a_ssc_avlj
      # A non-SSC AVLJ that has 4 appeals where the non-SSC AVLJ held a hearing first, but a second hearing was held by an SSC AVLJ.
      # These cases should NOT be returned to the board
      avlj = User.find_by(css_id: "NONSSCAN12")
      ssc_avlj = User.find_by(css_id: "SSCAVLJLGC")
      legacy_appeal = create_legacy_appeal(priority=true, avlj, 90.days.ago)
      create_second_hearing_for_legacy_appeal(legacy_appeal, 90.days.ago, ssc_avlj)

      legacy_appeal = create_legacy_appeal(priority=false, avlj, 60.days.ago)
      create_second_hearing_for_legacy_appeal(legacy_appeal, 30.days.ago, ssc_avlj)

      legacy_appeal = create_legacy_appeal(priority=true, avlj, 30.days.ago)
      create_second_hearing_for_legacy_appeal(legacy_appeal, 15.days.ago, ssc_avlj)

      legacy_appeal = create_legacy_appeal(priority=false, avlj, 15.days.ago)
      create_second_hearing_for_legacy_appeal(legacy_appeal, 5.days.ago, ssc_avlj)
    end

    def create_four_alternating_priority_by_age_appeals_tied_to_a_non_ssc_avlj_with_a_second_hearing_held_by_another_non_ssc_avlj
      # A non-SSC AVLJ that has 4 appeals where the non-SSC AVLJ held a hearing first, but a second hearing was held by different non-SSC AVLJ.
      avlj = User.find_by(css_id: "NONSSCAN13")
      avlj2 = User.find_by(css_id: "AVLJLGC2")
      legacy_appeal = create_legacy_appeal(priority=true, avlj, 95.days.ago)
      create_second_hearing_for_legacy_appeal(legacy_appeal, 65.days.ago, avlj2)

      legacy_appeal = create_legacy_appeal(priority=false, avlj, 65.days.ago)
      create_second_hearing_for_legacy_appeal(legacy_appeal, 35.days.ago, avlj2)

      legacy_appeal = create_legacy_appeal(priority=true, avlj, 35.days.ago)
      create_second_hearing_for_legacy_appeal(legacy_appeal, 25.days.ago, avlj2)

      legacy_appeal = create_legacy_appeal(priority=false, avlj, 20.days.ago)
      create_second_hearing_for_legacy_appeal(legacy_appeal, 10.days.ago, avlj2)
    end

    def create_unsigned_priority_appeal_tied_to_inactive_non_ssc_avlj
      inactive_avlj = User.find_by(css_id: "NONSSCAN14")
      docket_date = Date.new(1999, 1, 1)
      create_legacy_appeal(priority=true, inactive_avlj, docket_date)
    end

    def create_signed_non_priority_appeal_tied_to_inactive_non_ssc_avlj
      inactive_avlj = User.find_by(css_id: "NONSSCAN14")
      docket_date = Date.new(1999, 1, 2)
      create_signed_legacy_appeal(priority=false, inactive_avlj, inactive_avlj, docket_date)
    end

    def create_unsigned_priority_ama_appeal_tied_to_non_ssc_avlj
      non_ssc_avlj = User.find_by(css_id: "NONSSCAN01")
      docket_date = Date.new(2020, 1, 3)
      create_ama_appeal(priority=true, non_ssc_avlj, docket_date)
    end

    def create_signed_non_priority_ama_appeal_tied_to_non_ssc_avlj
      non_ssc_avlj = User.find_by(css_id: "NONSSCAN01")
      docket_date = Date.new(2020, 1, 4)
      create_signed_ama_appeal(priority=false, non_ssc_avlj, non_ssc_avlj, docket_date)
    end

    def create_signed_priority_appeal_tied_to_vlj
      vlj = User.find_by(css_id: "REGVLJ01")
      docket_date = Date.new(1999, 1, 5)
      create_signed_legacy_appeal(priority=true, vlj, vlj, docket_date)
    end

    def create_unsigned_non_priority_appeal_tied_to_vlj
      vlj = User.find_by(css_id: "REGVLJ02")
      docket_date = Date.new(1999, 1, 6)
      create_legacy_appeal(priority=false, vlj, docket_date)
    end

    def create_non_ssc_avlj(css_id, full_name)
      User.find_by_css_id(css_id) ||
        create(:user, :non_ssc_avlj_user, css_id: css_id, full_name: full_name)
    end

    def create_ssc_avlj(css_id, full_name)
      User.find_by_css_id(css_id) ||
        create(:user, :ssc_avlj_user, css_id: css_id, full_name: full_name)
    end

    def create_inactive_non_ssc_avlj(css_id, full_name)
      # same as a regular non_ssc_avlj except their sactive = 'I' instead of 'A'
      User.find_by_css_id(css_id) ||
        create(:user, :inactive_non_ssc_avlj_user, css_id: css_id, full_name: full_name)
    end

    def create_vlj(css_id, full_name)
      # same as a ssc_avlj except thier svlj = 'J' instead of 'A'
      User.find_by_css_id(css_id) ||
        create(:user, :vlj_user, css_id: css_id, full_name: full_name)
    end

    def demo_regional_office
      'RO17'
    end

    def create_signed_legacy_appeal(priority, signing_avlj, assigned_avlj, docket_date)
      Timecop.travel(docket_date) do
        traits = priority ? [:type_cavc_remand] : [:type_original]
        create(:legacy_signed_appeal, *traits, signing_avlj: signing_avlj, assigned_avlj: assigned_avlj)
      end
    end

    def create_legacy_appeal(priority, avlj, docket_date)
      Timecop.travel(docket_date)
      veteran = create_demo_veteran_for_legacy_appeal

      correspondent = create(:correspondent,
                            snamef: veteran.first_name, snamel: veteran.last_name,
                            ssalut: "", ssn: veteran.file_number)


      vacols_case = priority ? create_priority_video_vacols_case(veteran,
                                        correspondent,
                                        avlj,
                                        docket_date) :
                                create_non_priority_video_vacols_case(veteran,
                                correspondent,
                                avlj,
                                docket_date)

      legacy_appeal = create(
        :legacy_appeal,
        :with_root_task,
        vacols_case: vacols_case,
        closest_regional_office: demo_regional_office
      )

      create(:available_hearing_locations, demo_regional_office, appeal: legacy_appeal)
      Timecop.return

      legacy_appeal
    end

    def create_ama_appeal(priority, avlj, docket_date)
      Timecop.travel(docket_date)
        priority ? create(
            :appeal,
            :hearing_docket,
            :with_post_intake_tasks,
            :advanced_on_docket_due_to_age,
            :held_hearing_and_ready_to_distribute,
            :tied_to_judge,
            veteran: create_demo_veteran_for_legacy_appeal,
            receipt_date: docket_date,
            tied_judge: avlj,
            adding_user: avlj
          ) : create(
            :appeal,
            :hearing_docket,
            :with_post_intake_tasks,
            :held_hearing_and_ready_to_distribute,
            :tied_to_judge,
            veteran: create_demo_veteran_for_legacy_appeal,
            receipt_date: docket_date,
            tied_judge: avlj,
            adding_user: avlj
          )
      Timecop.return
    end

    def create_signed_ama_appeal(priority, avlj, signing_avlj, docket_date)

      # Go back to when we want the original appeal to have been decided
      Timecop.travel(docket_date)

        source = create(:appeal, :dispatched, :hearing_docket, associated_judge: avlj)
        remand = create(:cavc_remand, source_appeal: source).remand_appeal
        remand.tasks.where(type: SendCavcRemandProcessedLetterTask.name).map(&:completed!)
        create(:appeal_affinity, appeal: remand)

        jat = JudgeAssignTaskCreator.new(appeal: remand, judge: avlj, assigned_by_id: avlj.id).call
        create(:colocated_task, :schedule_hearing, parent: jat, assigned_by: avlj).completed!

        create(:hearing, :held, appeal: remand, judge: avlj, adding_user: User.system_user)
        remand.tasks.where(type: AssignHearingDispositionTask.name).flat_map(&:children).map(&:completed!)
        remand.appeal_affinity.update!(affinity_start_date: Time.zone.now)

        remand
      Timecop.return
    end


    def create_priority_video_vacols_case(veteran, correspondent, associated_judge, days_ago)
      create(
        :case,
        :aod,
        :tied_to_judge,
        :video_hearing_requested,
        :type_original,
        :ready_for_distribution,
        tied_judge: associated_judge,
        correspondent: correspondent,
        bfcorlid: "#{veteran.file_number}S",
        case_issues: create_list(:case_issue, 3, :compensation),
        bfd19: days_ago
      )
    end

    def create_non_priority_video_vacols_case(veteran, correspondent, associated_judge, days_ago)
      create(
        :case,
        :tied_to_judge,
        :video_hearing_requested,
        :type_original,
        :ready_for_distribution,
        tied_judge: associated_judge,
        correspondent: correspondent,
        bfcorlid: "#{veteran.file_number}S",
        case_issues: create_list(:case_issue, 3, :compensation),
        bfd19: days_ago
      )
    end

    def random_demo_file_number_and_participant_id
      random_file_number = Random.rand(100_000_000...989_999_999)
      random_participant_id = random_file_number + 100000

      while find_demo_veteran(random_file_number)
        random_file_number += 2000
        random_participant_id += 2000
      end

      return random_file_number, random_participant_id
    end

    def find_demo_veteran(file_number)
      Veteran.find_by(file_number: format("%<n>09d", n: file_number + 1))
    end

    def create_demo_veteran(options = {})
      params = {
        file_number: format("%<n>09d", n: options[:file_number]),
        participant_id: format("%<n>09d", n: options[:participant_id])
      }

      Veteran.find_by_participant_id(params[:participant_id]) || create(:veteran, params.merge(options))
    end

    def create_demo_veteran_for_legacy_appeal
      file_number, participant_id  = random_demo_file_number_and_participant_id
      create_demo_veteran(
        file_number: file_number,
        participant_id: participant_id
      )
    end

    def create_second_hearing_for_legacy_appeal(legacy_appeal, docket_date, avlj)
      case_hearing = create(
        :case_hearing,
        :disposition_held,
        folder_nr: legacy_appeal.vacols_id,
        hearing_date: docket_date.to_date,
        user: avlj
      )

      create(:legacy_hearing, appeal: legacy_appeal, case_hearing: case_hearing)
    end

    def make_legacy_appeal_not_ready_for_distribution(legacy_appeal)
      Rails.logger.info("~~~Marking legacy appeal for Veteran ID: #{legacy_appeal.vbms_id} as Not Ready To Distribute~~~")
      VACOLS::Case.find(legacy_appeal.vacols_id).update!(bfcurloc: "01")
    end
  end
end
