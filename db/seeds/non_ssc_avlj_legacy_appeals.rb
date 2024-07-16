# frozen_string_literal: true

module Seeds
  class NonSscAvljLegacyAppeals < Base
    def initialize
      initialize_np_legacy_appeals_file_number_and_participant_id
      initialize_priority_legacy_appeals_file_number_and_participant_id
    end

    def seed!
      RequestStore[:current_user] = User.system_user
      create_avljs
      create_legacy_appeals
    end

    private

    def initialize_np_legacy_appeals_file_number_and_participant_id
    end

    def initialize_priority_legacy_appeals_file_number_and_participant_id
    end

    def create_avljs
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
      create_priority_legacy_appeal(avlj, docket_date)
      create_priority_legacy_appeal(avlj, docket_date)
      create_priority_legacy_appeal(avlj, docket_date)
      create_priority_legacy_appeal(avlj, docket_date)
    end

    def create_ac_2_appeals
      # A non-SSC AVLJ that Only has 4 non-priority cases where they held the last hearing
      create_non_priority_legacy_appeal(avlj, docket_date)
      create_non_priority_legacy_appeal(avlj, docket_date)
      create_non_priority_legacy_appeal(avlj, docket_date)
      create_non_priority_legacy_appeal(avlj, docket_date)
    end

    def create_ac_3_appeals
      # A non-SSC AVLJ that Only has 4 priority cases where they held the last hearing and signed the most recent decision
      create_priority_legacy_appeal(avlj, docket_date, avlj)
      create_priority_legacy_appeal(avlj, docket_date, avlj)
      create_priority_legacy_appeal(avlj, docket_date, avlj)
      create_priority_legacy_appeal(avlj, docket_date, avlj)
    end

    def create_ac_4_appeals
      # A non-SSC AVLJ that Only has 4 non-priority cases where they held the last hearing and signed the most recent decision
      create_non_priority_legacy_appeal(avlj, docket_date, avlj)
      create_non_priority_legacy_appeal(avlj, docket_date, avlj)
      create_non_priority_legacy_appeal(avlj, docket_date, avlj)
      create_non_priority_legacy_appeal(avlj, docket_date, avlj)
    end

    def create_ac_5_appeals
      # A non-SSC AVLJ that Has 4 in alternating order by age of BRIEFF.BFD19 (Docket Date)
# priority cases where they held the last hearing
# non-priority cases where they held the last hearing
      create_non_priority_legacy_appeal(avlj, docket_date) #oldest
      create_priority_legacy_appeal(avlj, docket_date)
      create_non_priority_legacy_appeal(avlj, docket_date)
      create_priority_legacy_appeal(avlj, docket_date) #most recent
    end

    def create_ac_6_appeals
      # A non-SSC AVLJ that Has 4 in alternating order by age of BRIEFF.BFD19 (Docket Date)
# priority cases where they held the last hearing and signed the most recent decision
# non-priority cases where they held the last hearing and signed the most recent decision
      create_non_priority_legacy_appeal(avlj, docket_date, avlj) #oldest
      create_priority_legacy_appeal(avlj, docket_date, avlj)
      create_non_priority_legacy_appeal(avlj, docket_date, avlj)
      create_priority_legacy_appeal(avlj, docket_date, avlj) #most recent
    end

    def create_ac_7_appeals
      # A non-SSC AVLJ that Only has 4 priority cases where they held the last hearing and did NOT sign the most recent decision
# These cases should NOT be returned to the board
      create_priority_legacy_appeal(avlj, docket_date, signing_avlj)
      create_priority_legacy_appeal(avlj, docket_date, signing_avlj)
      create_priority_legacy_appeal(avlj, docket_date, signing_avlj)
      create_priority_legacy_appeal(avlj, docket_date, signing_avlj)
    end

    def create_ac_8_appeals
      # A non-SSC AVLJ that Only has 4 non-priority cases where they held the last hearing and did NOT sign the most recent decision
# These cases should NOT be returned to the board
      create_non_priority_legacy_appeal(avlj, docket_date, signing_avlj)
      create_non_priority_legacy_appeal(avlj, docket_date, signing_avlj)
      create_non_priority_legacy_appeal(avlj, docket_date, signing_avlj)
      create_non_priority_legacy_appeal(avlj, docket_date, signing_avlj)
    end

    def create_ac_9_appeals
      # A non-SSC AVLJ that Has 4 in alternating order by age of BRIEFF.BFD19 (Docket Date)
# priority cases where they held the last hearing and did NOT sign the most recent decision
# These cases should NOT be returned to the board
# non-priority cases where they held the last hearing and did NOT sign the most recent decision
# These cases should NOT be returned to the board
      create_non_priority_legacy_appeal(avlj, docket_date, signing_avlj) #oldest
      create_priority_legacy_appeal(avlj, docket_date, signing_avlj)
      create_non_priority_legacy_appeal(avlj, docket_date, signing_avlj)
      create_priority_legacy_appeal(avlj, docket_date, signing_avlj) #most recent
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
      create_priority_legacy_appeal(avlj, docket_date, signing_avlj) #oldest
      create_non_priority_legacy_appeal(avlj, docket_date, signing_avlj)
      create_priority_legacy_appeal(avlj, docket_date)
      create_non_priority_legacy_appeal(avlj, docket_date)
      create_priority_legacy_appeal(avlj, docket_date, avlj)
      create_non_priority_legacy_appeal(avlj, docket_date, avlj)
      create_priority_legacy_appeal(avlj, docket_date, signing_avlj)
      create_non_priority_legacy_appeal(avlj, docket_date, signing_avlj)
      create_priority_legacy_appeal(avlj, docket_date)
      create_non_priority_legacy_appeal(avlj, docket_date)
      create_priority_legacy_appeal(avlj, docket_date, avlj)
      create_non_priority_legacy_appeal(avlj, docket_date, avlj) #most recent

    end

    def create_ac_11_appeals
      # A SSC AVLJ that has 4 appeals for which they held the last hearing.
# These cases should NOT be returned to the board
      create_priority_legacy_appeal(ssc_avlj, docket_date)
      create_non_priority_legacy_appeal(ssc_avlj, docket_date)
      create_priority_legacy_appeal(ssc_avlj, docket_date)
      create_non_priority_legacy_appeal(ssc_avlj, docket_date)
    end

    def create_ac_12_appeals
      # A non-SSC AVLJ that has 4 appeals where the non-SSC AVLJ held a hearing first, but a second hearing was held by an SSC AVLJ.
# These cases should NOT be returned to the board
      create_priority_legacy_appeal(ssc_avlj, docket_date)
      create_second_hearing_for_legacy_appeal(legacy_appeal, docket_date, ssc_avlj)

      create_non_priority_legacy_appeal(ssc_avlj, docket_date)
      create_second_hearing_for_legacy_appeal(legacy_appeal, docket_date, ssc_avlj)

      create_priority_legacy_appeal(ssc_avlj, docket_date)
      create_second_hearing_for_legacy_appeal(legacy_appeal, docket_date, ssc_avlj)

      create_non_priority_legacy_appeal(ssc_avlj, docket_date)
      create_second_hearing_for_legacy_appeal(legacy_appeal, docket_date, ssc_avlj)
    end

    def create_ac_13_appeals
      # A non-SSC AVLJ that has 4 appeals where the non-SSC AVLJ held a hearing first, but a second hearing was held by different non-SSC AVLJ.
      create_priority_legacy_appeal(ssc_avlj, docket_date)
      create_second_hearing_for_legacy_appeal(legacy_appeal, docket_date, avlj2)

      create_non_priority_legacy_appeal(ssc_avlj, docket_date)
      create_second_hearing_for_legacy_appeal(legacy_appeal, docket_date, avlj2)

      create_priority_legacy_appeal(ssc_avlj, docket_date)
      create_second_hearing_for_legacy_appeal(legacy_appeal, docket_date, avlj2)

      create_non_priority_legacy_appeal(ssc_avlj, docket_date)
      create_second_hearing_for_legacy_appeal(legacy_appeal, docket_date, avlj2)
    end

    def create_non_ssc_avlj
    end

    def create_ssc_avlj
    end

    def create_priority_legacy_appeal(avlj, docket_date, signing_avlj=nil)
      #TODO: modify this method to work properly for this ticket's needs
      # BRIEFF.BFD19 = docket_date
      if signing_avlj
        create_brief(signing_avlj)
      end

      Timecop.travel(docket_date)
      veteran = create_demo_veteran_for_docket

      correspondent = create(:correspondent,
                            snamef: veteran.first_name, snamel: veteran.last_name,
                            ssalut: "", ssn: veteran.file_number)

      vacols_case = create_priority_video_vacols_case(veteran,
                                            correspondent,
                                            @associated_judge,
                                            @days_ago)

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

    def create_non_priority_legacy_appeal(avlj, docket_date, signing_avlj=nil)
      #TODO: modify this method to work properly for this ticket's needs
      # BRIEFF.BFD19 = docket_date
      if signing_avlj
        create_brief(signing_avlj)
      end

      Timecop.travel(docket_date)
      veteran = create_demo_veteran_for_docket

      correspondent = create(:correspondent,
                            snamef: veteran.first_name, snamel: veteran.last_name,
                            ssalut: "", ssn: veteran.file_number)

      vacols_case = create_non_priority_video_vacols_case(veteran,
                                            correspondent,
                                            @associated_judge,
                                            @days_ago)

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
