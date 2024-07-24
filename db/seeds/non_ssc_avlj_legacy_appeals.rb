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
      create_non_ssc_avlj("NONSSCAN01", "Non SSC AVLJ1")
      create_non_ssc_avlj("NONSSCAN02", "Non SSC AVLJ2")
      create_non_ssc_avlj("NONSSCAN03", "Non SSC AVLJ3")
      create_non_ssc_avlj("NONSSCAN04", "Non SSC AVLJ4")
      create_non_ssc_avlj("NONSSCAN05", "Non SSC AVLJ5")
      create_non_ssc_avlj("NONSSCAN06", "Non SSC AVLJ6")
      create_non_ssc_avlj("NONSSCAN07", "Non SSC AVLJ7")
      create_non_ssc_avlj("NONSSCAN08", "Non SSC AVLJ8")
      create_non_ssc_avlj("NONSSCAN09", "Non SSC AVLJ9")
      create_non_ssc_avlj("NONSSCAN10", "Non SSC AVLJ110")
      create_ssc_avlj("SSCA11", "SSC AVLJ1")
      create_non_ssc_avlj("NONSSCAN12", "Non SSC AVLJ12")
      create_non_ssc_avlj("NONSSCAN13", "Non SSC AVLJ13")

      create_non_ssc_avlj("SIGNAVLJLGC", "NonSSC Signing AVLJ1") #singing_avlj
      create_non_ssc_avlj("AVLJLGC2", "Alternate NonSSC AVLJ") #avlj2
    end

    def create_legacy_appeals
      # the naming comes from the acceptance criteria of APPEALS-45208
      #TODO: Rename these methods
      # create_ac_1_appeals #TEAM 1
      # create_ac_2_appeals #TEAM 1
      create_ac_3_appeals #TEAM 2
      # create_ac_4_appeals #TEAM 2
      # # create_ac_5_appeals #TEAM 1
      # create_ac_6_appeals #TEAM 2
      # create_ac_7_appeals #TEAM 2
      # create_ac_8_appeals #TEAM 2
      # create_ac_9_appeals #TEAM 2
      # create_ac_10_appeals #TEAM 2
      # create_ac_11_appeals #TEAM 1
      # create_ac_12_appeals #TEAM 3
      # create_ac_13_appeals #TEAM 3
    end

    def create_ac_1_appeals
      # A non-SSC AVLJ that Only has 4 priority cases where they held the last hearing
      avlj = User.find_by(css_id: "NONSSCAN01")
      create_legacy_appeal(priority=true, avlj, 300.days.ago)
      create_legacy_appeal(priority=true, avlj, 200.days.ago)
      create_legacy_appeal(priority=true, avlj, 100.days.ago)
      create_legacy_appeal(priority=true, avlj, 30.days.ago)
    end

    def create_ac_2_appeals
      # A non-SSC AVLJ that Only has 4 non-priority cases where they held the last hearing
      avlj = User.find_by(css_id: "NONSSCAN02")
      create_legacy_appeal(priority=false, avlj, 350.days.ago)
      create_legacy_appeal(priority=false, avlj, 250.days.ago)
      create_legacy_appeal(priority=false, avlj, 150.days.ago)
      create_legacy_appeal(priority=false, avlj, 50.days.ago)
    end

    def create_ac_3_appeals
      # A non-SSC AVLJ that Only has 4 priority cases where they held the last hearing and signed the most recent decision
      signing_avlj = VACOLS::Staff.find_by(stafkey: "NONSSCAN03")

      Timecop.travel(30.days.ago)
        create(:legacy_signed_appeal, :type_cavc_remand, signing_avlj: signing_avlj)
      Timecop.return

      # create_legacy_appeal(priority=true, avlj, 200.days.ago, avlj)
      # create_legacy_appeal(priority=true, avlj, 100.days.ago, avlj)
      # create_legacy_appeal(priority=true, avlj, 50.days.ago, avlj)
      # create_legacy_appeal(priority=true, avlj, 10.days.ago, avlj)
    end

    def create_ac_4_appeals
      # A non-SSC AVLJ that Only has 4 non-priority cases where they held the last hearing and signed the most recent decision
      avlj = user.find_by(css_id: "NONSSCAN04")
      create_legacy_appeal(priority=false, avlj, 200.days.ago)
      create_legacy_appeal(priority=false, avlj, 100.days.ago)
      create_legacy_appeal(priority=false, avlj, 50.days.ago)
      create_legacy_appeal(priority=false, avlj, 10.days.ago, avlj)
    end

    def create_ac_5_appeals
      # A non-SSC AVLJ that Has 4 in alternating order by age of BRIEFF.BFD19 (Docket Date)
# priority cases where they held the last hearing
# non-priority cases where they held the last hearing
      avlj = User.find_by(css_id: "NONSSCAN05")
      create_legacy_appeal(priority=false, avlj, 600.days.ago) #oldest
      create_legacy_appeal(priority=true, avlj, 425.days.ago)
      create_legacy_appeal(priority=false, avlj, 400.days.ago)
      create_legacy_appeal(priority=true, avlj, 40.days.ago) #most recent
    end

    def create_ac_6_appeals
      # A non-SSC AVLJ that Has 4 in alternating order by age of BRIEFF.BFD19 (Docket Date)
# priority cases where they held the last hearing and signed the most recent decision
# non-priority cases where they held the last hearing and signed the most recent decision
      avlj = user.find_by(css_id: "NONSSCAN06")
      create_legacy_appeal(priority=false, avlj, 300.days.ago) #oldest
      create_legacy_appeal(priority=true, avlj, 250.days.ago)
      create_legacy_appeal(priority=false, avlj, 100.days.ago, avlj)
      create_legacy_appeal(priority=true, avlj, 60.days.ago, avlj) #most recent
    end

    def create_ac_7_appeals
      # A non-SSC AVLJ that Only has 4 priority cases where they held the last hearing and did NOT sign the most recent decision
# These cases should NOT be returned to the board
      avlj = User.find_by(css_id: "NONSSCAN07")
      signing_avlj = User.find_by(css_id: "SIGNAVLJLGC")
      create_legacy_appeal(priority=true, avlj, docket_date, signing_avlj)
      create_legacy_appeal(priority=true, avlj, docket_date, signing_avlj)
      create_legacy_appeal(priority=true, avlj, docket_date, signing_avlj)
      create_legacy_appeal(priority=true, avlj, docket_date, signing_avlj)
    end

    def create_ac_8_appeals
      # A non-SSC AVLJ that Only has 4 non-priority cases where they held the last hearing and did NOT sign the most recent decision
# These cases should NOT be returned to the board
      avlj = User.find_by(css_id: "NONSSCAN08")
      signing_avlj = User.find_by(css_id: "SIGNAVLJLGC")
      create_legacy_appeal(priority=false, avlj, docket_date, signing_avlj)
      create_legacy_appeal(priority=false, avlj, docket_date, signing_avlj)
      create_legacy_appeal(priority=false, avlj, docket_date, signing_avlj)
      create_legacy_appeal(priority=false, avlj, docket_date, signing_avlj)
    end

    def create_ac_9_appeals
      # A non-SSC AVLJ that Has 4 in alternating order by age of BRIEFF.BFD19 (Docket Date)
# priority cases where they held the last hearing and did NOT sign the most recent decision
# These cases should NOT be returned to the board
# non-priority cases where they held the last hearing and did NOT sign the most recent decision
# These cases should NOT be returned to the board
      avlj = User.find_by(css_id: "NONSSCAN09")
      signing_avlj = User.find_by(css_id: "SIGNAVLJLGC")
      create_legacy_appeal(priority=false, avlj, docket_date, signing_avlj) #oldest
      create_legacy_appeal(priority=true, avlj, docket_date, signing_avlj)
      create_legacy_appeal(priority=false, avlj, docket_date, signing_avlj)
      create_legacy_appeal(priority=true, avlj, docket_date, signing_avlj) #most recent
    end

    def create_ac_10_appeals
      # A non-SSC AVLJ that Has 12 appeals
# Notes
# Cycle through the groups before creating the second appeal in the group, make each created appeal newer by BRIEFF.BFD19 (Docket Date) than the previous one
# Appeals in the same group should not be grouped next to each other
# appeals
# priority cases where they held the last hearing and did NOT sign the most recent decision
# These cases should NOT be returned to the board
# non-priority cases where they held the last hearing and did NOT sign the most recent decision
# These cases should NOT be returned to the board
# priority cases where they held the last hearing
# non-priority cases where they held the last hearing
# priority cases where they held the last hearing and signed the most recent decision
# non-priority cases where they held the last hearing and signed the most recent decision
# has an appeal with a hearing where they were the judge but the appeal is NOT ready to distribute
# This case would NOT show up in the ready to distribute query, but we could look it up by veteran ID to verify that it didn't get moved.

      avlj = User.find_by(css_id: "NONSSCAN10")
      signing_avlj = User.find_by(css_id: "SIGNAVLJLGC")
      create_legacy_appeal(priority=true, avlj, docket_date, signing_avlj) #oldest
      create_legacy_appeal(priority=false, avlj, docket_date, signing_avlj)
      create_legacy_appeal(priority=true, avlj, docket_date)
      create_legacy_appeal(priority=false, avlj, docket_date)
      create_legacy_appeal(priority=true, avlj, docket_date, avlj)
      create_legacy_appeal(priority=false, avlj, docket_date, avlj)
      create_legacy_appeal(priority=true, avlj, docket_date, avlj).not_ready_to_distribute


      create_legacy_appeal(priority=true, avlj, docket_date, signing_avlj)
      create_legacy_appeal(priority=false, avlj, docket_date, signing_avlj)
      create_legacy_appeal(priority=true, avlj, docket_date)
      create_legacy_appeal(priority=false, avlj, docket_date)
      create_legacy_appeal(priority=true, avlj, docket_date, avlj)
      create_legacy_appeal(priority=false, avlj, docket_date, avlj)
      create_legacy_appeal(priority=true, avlj, docket_date, avlj).not_ready_to_distribute#most recent
    end

    def create_ac_11_appeals
      # A SSC AVLJ that has 4 appeals for which they held the last hearing.
# These cases should NOT be returned to the board
      ssc_avlj = User.find_by(css_id: "SSCA11")
      create_legacy_appeal(priority=true, ssc_avlj, 325.days.ago)
      create_legacy_appeal(priority=false, ssc_avlj, 275.days.ago)
      create_legacy_appeal(priority=true, ssc_avlj, 175.days.ago)
      create_legacy_appeal(priority=false, ssc_avlj, 75.days.ago)
    end

    def create_ac_12_appeals
      # A non-SSC AVLJ that has 4 appeals where the non-SSC AVLJ held a hearing first, but a second hearing was held by an SSC AVLJ.
# These cases should NOT be returned to the board
      avlj = User.find_by(css_id: "NONSSCAN12")
      ssc_avlj = User.find_by(css_id: "SSCAVLJLGC")
      create_legacy_appeal(priority=true, avlj, docket_date)
      create_second_hearing_for_legacy_appeal(legacy_appeal, docket_date, ssc_avlj)

      create_legacy_appeal(priority=false, avlj, docket_date)
      create_second_hearing_for_legacy_appeal(legacy_appeal, docket_date, ssc_avlj)

      create_legacy_appeal(priority=true, avlj, docket_date)
      create_second_hearing_for_legacy_appeal(legacy_appeal, docket_date, ssc_avlj)

      create_legacy_appeal(priority=false, avlj, docket_date)
      create_second_hearing_for_legacy_appeal(legacy_appeal, docket_date, ssc_avlj)
    end

    def create_ac_13_appeals
      # A non-SSC AVLJ that has 4 appeals where the non-SSC AVLJ held a hearing first, but a second hearing was held by different non-SSC AVLJ.
      avlj = User.find_by(css_id: "NONSSCAN13")
      avlj2 = User.find_by(css_id: "AVLJLGC2")
      create_legacy_appeal(priority=true, avlj, docket_date)
      create_second_hearing_for_legacy_appeal(legacy_appeal, docket_date, avlj2)

      create_legacy_appeal(priority=false, avlj, docket_date)
      create_second_hearing_for_legacy_appeal(legacy_appeal, docket_date, avlj2)

      create_legacy_appeal(priority=true, avlj, docket_date)
      create_second_hearing_for_legacy_appeal(legacy_appeal, docket_date, avlj2)

      create_legacy_appeal(priority=false, avlj, docket_date)
      create_second_hearing_for_legacy_appeal(legacy_appeal, docket_date, avlj2)
    end

    def create_non_ssc_avlj(css_id, full_name)
      User.find_by_css_id(css_id) ||
        create(:user, :non_ssc_avlj_user, css_id: css_id, full_name: full_name) #add in the work from https://github.com/department-of-veterans-affairs/caseflow/pull/22176/files
    end

    def create_ssc_avlj(css_id, full_name)
      # User.find_by_css_id(css_id) ||
      #   create(:user, :ssc_avlj_user, css_id: css_id, full_name: full_name) #to be devolped
    end

    def demo_regional_office
      'RO17'
    end

    # def create_legacy_appeal(priority, avlj, docket_date, signing_avlj=nil)
    #   legacy_appeal = create(:legacy_signed_appeal)

    #   if priority

      #TODO: modify this method to work properly for this ticket's needs
      # # BRIEFF.BFD19 = docket_date
      # if signing_avlj
      #   brieff = create_brieff(signing_avlj, docket_date) #this may or may not need to be developed depending on how the factory works
      # end

      # Timecop.travel(docket_date)
      # veteran = create_demo_veteran_for_legacy_appeal

      # correspondent = create(:correspondent,
      #                       snamef: veteran.first_name, snamel: veteran.last_name,
      #                       ssalut: "", ssn: veteran.file_number)

      # if signing_avlj
      #   vacols_case = priority ? create_signed_priority_video_vacols_case(veteran,
      #                                     correspondent,
      #                                     avlj,
      #                                     docket_date,
      #                                     signing_avlj,
      #                                     brieff) :
      #                             create_signed_non_priority_video_vacols_case(veteran,
      #                             correspondent,
      #                             avlj,
      #                             docket_date,
      #                             signing_avlj,
      #                             brieff)
      # else
      #   vacols_case = priority ? create_priority_video_vacols_case(veteran,
      #                                     correspondent,
      #                                     avlj,
      #                                     docket_date) :
      #                             create_non_priority_video_vacols_case(veteran,
      #                             correspondent,
      #                             avlj,
      #                             docket_date)
      # end

      # legacy_appeal = create(
      #   :legacy_appeal,
      #   :with_root_task,
      #   vacols_case: vacols_case,
      #   closest_regional_office: demo_regional_office
      # )

      # create(:available_hearing_locations, demo_regional_office, appeal: legacy_appeal)
      # Timecop.return
    # end

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

    def assign_last_hearing_to_avlj #maybe needed?
    end

    def create_second_hearing_for_legacy_appeal(legacy_appeal, avlj)
    end

  end
end
