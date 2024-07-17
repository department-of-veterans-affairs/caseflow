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
      create_ac_1_appeals #TEAM 1
      create_ac_2_appeals #TEAM 1
      create_ac_3_appeals #TEAM 2
      create_ac_4_appeals #TEAM 2
      create_ac_5_appeals #TEAM 1
      create_ac_6_appeals #TEAM 2
      create_ac_7_appeals #TEAM 2
      create_ac_8_appeals #TEAM 2
      create_ac_9_appeals #TEAM 2
      create_ac_10_appeals #TEAM 2
      create_ac_11_appeals #TEAM 1
      create_ac_12_appeals #TEAM 3
      create_ac_13_appeals #TEAM 3
    end

    def create_ac_1_appeals
      # A non-SSC AVLJ that Only has 4 priority cases where they held the last hearing
      avlj = user.find_by(css_id: "NONSSCAN01")
      create_legacy_appeal(priority=true, avlj, 300.days.ago)
      create_legacy_appeal(priority=true, avlj, 200.days.ago)
      create_legacy_appeal(priority=true, avlj, 100.days.ago)
      create_legacy_appeal(priority=true, avlj, 30.days.ago)
    end

    def create_ac_2_appeals
      # A non-SSC AVLJ that Only has 4 non-priority cases where they held the last hearing
      avlj = user.find_by(css_id: "NONSSCAN02")
      create_legacy_appeal(priority=false, avlj, docket_date)
      create_legacy_appeal(priority=false, avlj, docket_date)
      create_legacy_appeal(priority=false, avlj, docket_date)
      create_legacy_appeal(priority=false, avlj, docket_date)
    end

    def create_ac_3_appeals
      # A non-SSC AVLJ that Only has 4 priority cases where they held the last hearing and signed the most recent decision
      avlj = user.find_by(css_id: "NONSSCAN03")
      create_legacy_appeal(priority=true, avlj, docket_date, avlj)
      create_legacy_appeal(priority=true, avlj, docket_date, avlj)
      create_legacy_appeal(priority=true, avlj, docket_date, avlj)
      create_legacy_appeal(priority=true, avlj, docket_date, avlj)
    end

    def create_ac_4_appeals
      # A non-SSC AVLJ that Only has 4 non-priority cases where they held the last hearing and signed the most recent decision
      avlj = user.find_by(css_id: "NONSSCAN04")
      create_legacy_appeal(priority=false, avlj, docket_date, avlj)
      create_legacy_appeal(priority=false, avlj, docket_date, avlj)
      create_legacy_appeal(priority=false, avlj, docket_date, avlj)
      create_legacy_appeal(priority=false, avlj, docket_date, avlj)
    end

    def create_ac_5_appeals
      # A non-SSC AVLJ that Has 4 in alternating order by age of BRIEFF.BFD19 (Docket Date)
# priority cases where they held the last hearing
# non-priority cases where they held the last hearing
      avlj = user.find_by(css_id: "NONSSCAN05")
      create_legacy_appeal(priority=false, avlj, docket_date) #oldest
      create_legacy_appeal(priority=true, avlj, docket_date)
      create_legacy_appeal(priority=false, avlj, docket_date)
      create_legacy_appeal(priority=true, avlj, docket_date) #most recent
    end

    def create_ac_6_appeals
      # A non-SSC AVLJ that Has 4 in alternating order by age of BRIEFF.BFD19 (Docket Date)
# priority cases where they held the last hearing and signed the most recent decision
# non-priority cases where they held the last hearing and signed the most recent decision
      avlj = user.find_by(css_id: "NONSSCAN06")
      create_legacy_appeal(priority=false, avlj, docket_date, avlj) #oldest
      create_legacy_appeal(priority=true, avlj, docket_date, avlj)
      create_legacy_appeal(priority=false, avlj, docket_date, avlj)
      create_legacy_appeal(priority=true, avlj, docket_date, avlj) #most recent
    end

    def create_ac_7_appeals
      # A non-SSC AVLJ that Only has 4 priority cases where they held the last hearing and did NOT sign the most recent decision
# These cases should NOT be returned to the board
      avlj = user.find_by(css_id: "NONSSCAN07")
      signing_avlj = user.find_by(css_id: "SIGNAVLJLGC")
      create_legacy_appeal(priority=true, avlj, docket_date, signing_avlj)
      create_legacy_appeal(priority=true, avlj, docket_date, signing_avlj)
      create_legacy_appeal(priority=true, avlj, docket_date, signing_avlj)
      create_legacy_appeal(priority=true, avlj, docket_date, signing_avlj)
    end

    def create_ac_8_appeals
      # A non-SSC AVLJ that Only has 4 non-priority cases where they held the last hearing and did NOT sign the most recent decision
# These cases should NOT be returned to the board
      avlj = user.find_by(css_id: "NONSSCAN08")
      signing_avlj = user.find_by(css_id: "SIGNAVLJLGC")
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
      avlj = user.find_by(css_id: "NONSSCAN09")
      signing_avlj = user.find_by(css_id: "SIGNAVLJLGC")
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

      avlj = user.find_by(css_id: "NONSSCAN10")
      signing_avlj = user.find_by(css_id: "SIGNAVLJLGC")
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
      ssc_avlj = user.find_by(css_id: "SSCA11")
      create_legacy_appeal(priority=true, ssc_avlj, docket_date)
      create_legacy_appeal(priority=false, ssc_avlj, docket_date)
      create_legacy_appeal(priority=true, ssc_avlj, docket_date)
      create_legacy_appeal(priority=false, ssc_avlj, docket_date)
    end

    def create_ac_12_appeals
      # A non-SSC AVLJ that has 4 appeals where the non-SSC AVLJ held a hearing first, but a second hearing was held by an SSC AVLJ.
# These cases should NOT be returned to the board
      avlj = user.find_by(css_id: "NONSSCAN12")
      ssc_avlj = user.find_by(css_id: "SSCAVLJLGC")
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
      avlj = user.find_by(css_id: "NONSSCAN13")
      avlj2 = user.find_by(css_id: "AVLJLGC2")
      create_legacy_appeal(priority=true, ssc_avlj, docket_date)
      create_second_hearing_for_legacy_appeal(legacy_appeal, docket_date, avlj2)

      create_legacy_appeal(priority=false, ssc_avlj, docket_date)
      create_second_hearing_for_legacy_appeal(legacy_appeal, docket_date, avlj2)

      create_legacy_appeal(priority=true, ssc_avlj, docket_date)
      create_second_hearing_for_legacy_appeal(legacy_appeal, docket_date, avlj2)

      create_legacy_appeal(priority=false, ssc_avlj, docket_date)
      create_second_hearing_for_legacy_appeal(legacy_appeal, docket_date, avlj2)
    end

    def create_non_ssc_avlj(ccsid, full_name)
    end

    def create_ssc_avlj(ccsid, full_name)
    end

    def demo_regional_office
      'RO17'
    end

    def create_legacy_appeal(priority, avlj, docket_date, signing_avlj=nil)
      #TODO: modify this method to work properly for this ticket's needs
      # BRIEFF.BFD19 = docket_date
      if signing_avlj
        create_brief(signing_avlj)
      end

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

    def create_demo_veteran_for_legacy_appeal
      file_number, participant_id  = random_demo_file_number_and_participant_id
      create_demo_veteran(
        file_number: file_number,
        participant_id: participant_id
      )
    end
##########

    def assign_last_hearing_to_avlj #maybe needed?
    end

    def create_brief(avlj)
      # BRIEFF
        # Provide access to legacy appeal decisions for more complete appeals history queries
  # JOIN_PREVIOUS_APPEALS = "
  # left join (
  #     select B.BFKEY as PREV_BFKEY, B.BFCORLID as PREV_BFCORLID, B.BFDDEC as PREV_BFDDEC,
  #     B.BFMEMID as PREV_DECIDING_JUDGE, B.BFAC as PREV_TYPE_ACTION, F.TINUM as PREV_TINUM,
  #     F.TITRNUM as PREV_TITRNUM
  #     from BRIEFF B
  #     inner join FOLDER F on F.TICKNUM = B.BFKEY
  #     where B.BFMPRO = 'HIS' and B.BFMEMID not in ('000', '888', '999') and B.BFATTID is not null
  #   ) PREV_APPEAL
  #     on PREV_APPEAL.PREV_BFKEY != BRIEFF.BFKEY and PREV_APPEAL.PREV_BFCORLID = BRIEFF.BFCORLID
  #     and PREV_APPEAL.PREV_TINUM = BRIEFF.TINUM and PREV_APPEAL.PREV_TITRNUM = BRIEFF.TITRNUM
  #     and PREV_APPEAL.PREV_BFDDEC = BRIEFF.BFDPDCN
  # "

  # def self.appeals_tied_to_non_ssc_avljs
  #   query = <<-SQL
  #     with non_ssc_avljs as (
  #       #{VACOLS::Staff::NON_SSC_AVLJS}
  #     )
  #     #{SELECT_READY_TO_DISTRIBUTE_APPEALS_ORDER_BY_BFD19}
  #     where APPEALS.VLJ in (select * from non_ssc_avljs)
  #     and (
  #       APPEALS.PREV_DECIDING_JUDGE is null or
  #       (
  #         APPEALS.PREV_DECIDING_JUDGE = APPEALS.VLJ
  #         AND APPEALS.HEARING_DATE <= APPEALS.PREV_BFDDEC
  #       )
  #     )
  #     order by BFD19
  #   SQL

  # B.BFMEMID as PREV_DECIDING_JUDGE
    end

    def create_second_hearing_for_legacy_appeal(legacy_appeal, avlj)
    end

  end
end
