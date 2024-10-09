# frozen_string_literal: true

module Seeds
  class AojRemandReturnLegacyAppeals < Base
    def initialize
      RequestStore[:current_user] = User.system_user
      initialize_ssn
    end

    def seed!
      create_aoj_cavc_affinity_cases
      create_aoj_aod_affinity_cases
      create_aoj_affinity_cases
    end

    private

    def initialize_ssn
      @ssn ||= 210_000_000
      # n is (@file_number + 1) because @file_number is incremented before using it in factories in calling methods
      while VACOLS::Correspondent.find_by(ssn: format("%<n>09d", n: @ssn + 1))
        @ssn += 1000
      end
    end

    def create_correspondent(options = {})
      @ssn += 1 unless options[:ssn]

      params = {
        stafkey: @ssn,
        ssn: @ssn,
        susrtyp: "VETERAN",
        ssalut: nil,
        snamef: !options[:snamef].nil? ? options[:snamef] : Faker::Name.first_name,
        snamemi: Faker::Name.initials(number: 1),
        snamel: !options[:snamel].nil? ? options[:snamel] : Faker::Name.last_name,
        saddrst1: Faker::Address.street_name,
        saddrcty: Faker::Address.city,
        saddrstt: Faker::Address.state_abbr,
        saddrzip: Faker::Address.zip,
        staduser: "FAKEUSER",
        stadtime: 10.years.ago.to_datetime,
        sdob: 50.years.ago,
        sgender: Faker::Gender.short_binary_type
      }

      correspondent = VACOLS::Correspondent.find_by(ssn: options[:ssn] || @ssn) || create(:correspondent, params.merge(options))

      unless Veteran.find_by(ssn: @ssn)
        create(
          :veteran,
          first_name: correspondent.snamef,
          last_name: correspondent.snamel,
          name_suffix: correspondent.ssalut,
          ssn: correspondent.ssn,
          participant_id: correspondent.ssn,
          file_number: correspondent.ssn
        )
      end

      correspondent
    end

    def create_aoj_cavc_affinity_cases
      create_cases_for_aoj_cavc_affinity_days_lever
      create_cases_for_aoj_cavc_affinity_days_lever_excluded_judge
      create_cases_for_aoj_cavc_affinity_days_lever_ineligible_judge
      create_cases_for_aoj_cavc_with_hearing_after_decision
    end

    def create_aoj_aod_affinity_cases
      create_cases_for_aoj_aod_affinty_days_lever
      create_cases_for_aoj_aod_affinty_days_lever_excluded_judge
      create_cases_for_aoj_aod_affinity_days_lever_ineligible_judge
      create_cases_for_aoj_aod_with_hearing_after_decision
    end

    def create_aoj_affinity_cases
      create_cases_for_aoj_affinity_days_lever
      create_cases_for_aoj_affinity_days_lever_excluded_judge
      create_cases_for_aoj_affinity_days_lever_ineligible_judge
      create_cases_for_aoj_with_hearing_after_decision
    end

    def affinity_judge
      @affinity_judge ||= VACOLS::Staff.find_by_sdomainid("BVAGSPORER")
    end

    def tied_to_judge
      @tied_to_judge ||= VACOLS::Staff.find_by_sdomainid("BVABDANIEL")
    end

    def affinity_and_tied_to_judge
      @affinity_and_tied_to_judge ||= VACOLS::Staff.find_by_sdomainid("BVAEEMARD")
    end

    def excluded_judge
      @excluded_judge ||= find_or_create_active_excluded_judge("EXCL_JUDGE", "Excluded FromAffinity Judge")
    end

    def ineligible_judge
      @ineligible_judge ||= find_or_create_ineligible_judge("INEL_JUDGE", "Ineligible Vacols Judge")
    end

    def attorney
      @attorney ||= find_or_create_attorney("AFF_ATTY", "Affinity Cases Attorney")
    end

    def other_judge
      @other_judge ||= find_or_create_other_judge("OTHER_JUDGE", "Other Affinity Judge")
    end

    def find_or_create_ineligible_judge(sdomainid, full_name)
      VACOLS::Staff.find_by_sdomainid(sdomainid) || (
       user = create(:user, :judge, :with_inactive_vacols_judge_record, css_id: sdomainid, full_name: full_name)
       VACOLS::Staff.find_by_sdomainid(user.css_id))
    end

    def find_or_create_active_excluded_judge(sdomainid, full_name)
       VACOLS::Staff.find_by_sdomainid(sdomainid) || (
        user = create(:user, :judge_with_appeals_excluded_from_affinity,
               :with_vacols_judge_record, css_id: sdomainid, full_name: full_name)
        VACOLS::Staff.find_by_sdomainid(user.css_id))
    end

    def find_or_create_attorney(sdomainid, full_name)
      VACOLS::Staff.find_by_sdomainid(sdomainid) || (
       user = create(:user, :with_vacols_attorney_record, css_id: sdomainid, full_name: full_name)
       VACOLS::Staff.find_by_sdomainid(user.css_id))
    end

    def find_or_create_other_judge(sdomainid, full_name)
      VACOLS::Staff.find_by_sdomainid(sdomainid) || (
       user = create(:user, :judge, :with_vacols_judge_record, css_id: sdomainid, full_name: full_name)
       VACOLS::Staff.find_by_sdomainid(user.css_id))
    end

    def create_cases_for_aoj_cavc_affinity_days_lever
      # cavc affinity cases:
        # no hearing held but has previous decision
        create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "AffinityToBVAGSPORER", snamel: "60DaysAffinity").ssn}S",  judge: affinity_judge, attorney: attorney, tied_to: false, cavc: true)
        create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "AffinityToBVAGSPORER", snamel: "25DaysAffinity").ssn}S",  judge: affinity_judge, attorney: attorney,
                                    tied_to: false, affinity_start_date: 25.days.ago, cavc: true)
        create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "AffinityToBVAGSPORER", snamel: "3DaysAffinity").ssn}S",  judge: affinity_judge, attorney: attorney,
                                    tied_to: false, affinity_start_date: 3.days.ago, cavc: true)
        create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "AffinityToBVAGSPORER", snamel: "NoAppealAffinity").ssn}S",  judge: affinity_judge, attorney: attorney,
                                    tied_to: false, appeal_affinity: false, cavc: true)

        create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "AffinityToBVAEEMARD", snamel: "60DaysAffinity").ssn}S",  judge: affinity_and_tied_to_judge, attorney: attorney, tied_to: false, cavc: true)
        create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "AffinityToBVAEEMARD", snamel: "25DaysAffinity").ssn}S",  judge: affinity_and_tied_to_judge, attorney: attorney,
                                    tied_to: false, affinity_start_date: 25.days.ago, cavc: true)
        create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "AffinityToBVAEEMARD", snamel: "3DaysAffinity").ssn}S",  judge: affinity_and_tied_to_judge, attorney: attorney,
                                    tied_to: false, affinity_start_date: 3.days.ago, cavc: true)
        create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "AffinityToBVAEEMARD", snamel: "NoAppealAffinity").ssn}S",  judge: affinity_and_tied_to_judge, attorney: attorney,
                                    tied_to: false, appeal_affinity: false, cavc: true)

        create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "AffinityToBVABDANIEL", snamel: "60DaysAffinity").ssn}S",  judge: tied_to_judge, attorney: attorney, tied_to: false, cavc: true)
        create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "AffinityToBVABDANIEL", snamel: "25DaysAffinity").ssn}S",  judge: tied_to_judge, attorney: attorney,
                                    tied_to: false, affinity_start_date: 25.days.ago, cavc: true)
        create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "AffinityToBVABDANIEL", snamel: "3DaysAffinity").ssn}S",  judge: tied_to_judge, attorney: attorney,
                                    tied_to: false, affinity_start_date: 3.days.ago, cavc: true)
        create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "AffinityToBVABDANIEL", snamel: "NoAppealAffinity").ssn}S",  judge: tied_to_judge, attorney: attorney,
                                    tied_to: false, appeal_affinity: false, cavc: true)
        # hearing held with previous decision where judge is not the same
        a1 = create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "AffinityToBVAGSPORER", snamel: "60DaysAffinity").ssn}S", judge: other_judge, attorney: attorney, cavc: true)
        VACOLS::Case.where(bfcorlid: a1.bfcorlid, bfac: "7").update(bfmemid: affinity_judge.sattyid)

        b1 = create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "AffinityToBVAGSPORER", snamel: "25DaysAffinity").ssn}S", judge: other_judge, attorney: attorney,
                                          affinity_start_date: 25.days.ago, cavc: true)
        VACOLS::Case.where(bfcorlid: b1.bfcorlid, bfac: "7").update(bfmemid: affinity_judge.sattyid)

        a2 = create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "AffinityToBVAGSPORER", snamel: "3DaysAffinity").ssn}S", judge: other_judge, attorney: attorney,
                                          affinity_start_date: 3.days.ago, cavc: true)
        VACOLS::Case.where(bfcorlid: a2.bfcorlid, bfac: "7").update(bfmemid: affinity_judge.sattyid)

        a3 = create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "AffinityToBVAGSPORER", snamel: "NoAppealAffinity").ssn}S", judge: other_judge, attorney: attorney, appeal_affinity: false, cavc: true)
        VACOLS::Case.where(bfcorlid: a3.bfcorlid, bfac: "7").update(bfmemid: affinity_judge.sattyid)

        a4 = create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "AffinityToBVAEEMARD", snamel: "60DaysAffinity").ssn}S", judge: other_judge, attorney: attorney, cavc: true)
        VACOLS::Case.where(bfcorlid: a4.bfcorlid, bfac: "7").update(bfmemid: affinity_and_tied_to_judge.sattyid)

        b2 = create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "AffinityToBVAEEMARD", snamel: "25DaysAffinity").ssn}S", judge: other_judge, attorney: attorney,
                                          affinity_start_date: 25.days.ago, cavc: true)
        VACOLS::Case.where(bfcorlid: b2.bfcorlid, bfac: "7").update(bfmemid: affinity_and_tied_to_judge.sattyid)

        a5 = create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "AffinityToBVAEEMARD", snamel: "3DaysAffinity").ssn}S", judge: other_judge, attorney: attorney,
                                          affinity_start_date: 3.days.ago, cavc: true)
        VACOLS::Case.where(bfcorlid: a5.bfcorlid, bfac: "7").update(bfmemid: affinity_and_tied_to_judge.sattyid)

        a6 = create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "AffinityToBVAEEMARD", snamel: "NoAppealAffinity").ssn}S", judge: other_judge, attorney: attorney, appeal_affinity: false, cavc: true)
        VACOLS::Case.where(bfcorlid: a6.bfcorlid, bfac: "7").update(bfmemid: affinity_and_tied_to_judge.sattyid)

        b3 = create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "AffinityToBVABDANIEL", snamel: "60DaysAffinity").ssn}S", judge: other_judge, attorney: attorney, cavc: true)
        VACOLS::Case.where(bfcorlid: b3.bfcorlid, bfac: "7").update(bfmemid: tied_to_judge.sattyid)

        b4 = create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "AffinityToBVABDANIEL", snamel: "25DaysAffinity").ssn}S", judge: other_judge, attorney: attorney,
                                          affinity_start_date: 25.days.ago, cavc: true)
        VACOLS::Case.where(bfcorlid: b4.bfcorlid, bfac: "7").update(bfmemid: tied_to_judge.sattyid)

        b5 = create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "AffinityToBVABDANIEL", snamel: "3DaysAffinity").ssn}S", judge: other_judge, attorney: attorney,
                                          affinity_start_date: 3.days.ago, cavc: true)
        VACOLS::Case.where(bfcorlid: b5.bfcorlid, bfac: "7").update(bfmemid: tied_to_judge.sattyid)

        b6 = create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "AffinityToBVABDANIEL", snamel: "NoAppealAffinity").ssn}S", judge: other_judge, attorney: attorney, appeal_affinity: false, cavc: true)
        VACOLS::Case.where(bfcorlid: b6.bfcorlid, bfac: "7").update(bfmemid: tied_to_judge.sattyid)

        # hearing held with previous decision where judge is same (THIS IS TIED TO)
        create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "TiedToBVABDANIEL", snamel: "60DaysAffinity").ssn}S", judge: tied_to_judge, attorney: attorney, cavc: true)
        create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "TiedToBVABDANIEL", snamel: "25DaysAffinity").ssn}S", judge: tied_to_judge, attorney: attorney, affinity_start_date: 25.days.ago, cavc: true)
        create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "TiedToBVABDANIEL", snamel: "3DaysAffinity").ssn}S", judge: tied_to_judge, attorney: attorney, affinity_start_date: 3.days.ago, cavc: true)
        create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "TiedToBVABDANIEL", snamel: "NoAppealAffinity").ssn}S", judge: tied_to_judge, attorney: attorney, appeal_affinity: false, cavc: true)
        create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "TiedToBVAEEMARD", snamel: "60DaysAffinity").ssn}S",  judge: affinity_and_tied_to_judge, attorney: attorney, cavc: true)
        create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "TiedToBVAEEMARD", snamel: "25DaysAffinity").ssn}S",  judge: affinity_and_tied_to_judge, attorney: attorney, affinity_start_date: 25.days.ago, cavc: true)
        create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "TiedToBVAEEMARD", snamel: "3DaysAffinity").ssn}S",  judge: affinity_and_tied_to_judge, attorney: attorney, affinity_start_date: 3.days.ago, cavc: true)
        create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "TiedToBVAEEMARD", snamel: "NoAppealAffinity").ssn}S",  judge: affinity_and_tied_to_judge, attorney: attorney, appeal_affinity: false, cavc: true)
        create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "TiedToBVAGSPORER", snamel: "60DaysAffinity").ssn}S",  judge: affinity_judge, attorney: attorney, cavc: true)
        create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "TiedToBVAGSPORER", snamel: "25DaysAffinity").ssn}S",  judge: affinity_judge, attorney: attorney, affinity_start_date: 25.days.ago, cavc: true)
        create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "TiedToBVAGSPORER", snamel: "3DaysAffinity").ssn}S",  judge: affinity_judge, attorney: attorney, affinity_start_date: 3.days.ago, cavc: true)
        create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "TiedToBVAGSPORER", snamel: "NoAppealAffinity").ssn}S",  judge: affinity_judge, attorney: attorney, appeal_affinity: false, cavc: true)

        # hearing held but no previous deciding judge
        a7 = create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "Genpop60Days", snamel: "AffinityStartDate").ssn}S", judge: tied_to_judge, attorney: attorney, cavc: true)
        VACOLS::Case.where(bfcorlid: a7.bfcorlid, bfac: "7").update(bfmemid: nil)
        a8 = create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "Genpop60Days", snamel: "AffinityStartDate").ssn}S",  judge: affinity_and_tied_to_judge, attorney: attorney, cavc: true)
        VACOLS::Case.where(bfcorlid: a8.bfcorlid, bfac: "7").update(bfmemid: nil)

        # no hearing held, no previous deciding judge
        a9 = create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "Genpop60Days", snamel: "AffinityStartDate").ssn}S", judge: affinity_judge, attorney: attorney,
                                          tied_to: false, cavc: true)
        VACOLS::Case.where(bfcorlid: a9.bfcorlid, bfac: "7").update(bfmemid: nil)
        a10 = create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "Genpop60Days", snamel: "AffinityStartDate").ssn}S",  judge: affinity_and_tied_to_judge, attorney: attorney,
                                          tied_to: false, cavc: true)
        VACOLS::Case.where(bfcorlid: a10.bfcorlid, bfac: "7").update(bfmemid: nil)

        b18 = create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "Genpop3Days", snamel: "AffinityStartDate").ssn}S", judge: affinity_judge, attorney: attorney,
                                          tied_to: false, affinity_start_date: 3.days.ago, cavc: true)
        VACOLS::Case.where(bfcorlid: b18.bfcorlid, bfac: "7").update(bfmemid: nil)
        b19 = create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "Genpop3Days", snamel: "AffinityStartDate").ssn}S",  judge: affinity_and_tied_to_judge, attorney: attorney,
                                          tied_to: false, affinity_start_date: 3.days.ago, cavc: true)
        VACOLS::Case.where(bfcorlid: b19.bfcorlid, bfac: "7").update(bfmemid: nil)
    end

    def create_cases_for_aoj_cavc_affinity_days_lever_excluded_judge
      # excluded judge cases:
        # no hearing held but has previous decision
        create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "AffinityToExcludedJudge", snamel: "60DaysAffinity").ssn}S", judge: excluded_judge, attorney: attorney, tied_to: false, cavc: true)
        create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "AffinityToExcludedJudge", snamel: "25DaysAffinity").ssn}S", judge: excluded_judge, attorney: attorney,
                                      tied_to: false, affinity_start_date: 25.days.ago, cavc: true)
        create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "AffinityToExcludedJudge", snamel: "3DaysAffinity").ssn}S", judge: excluded_judge, attorney: attorney,
                                      tied_to: false, affinity_start_date: 3.days.ago, cavc: true)
        create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "AffinityToExcludedJudge", snamel: "NoAppealAffinity").ssn}S", judge: excluded_judge, attorney: attorney,
                                      tied_to: false, appeal_affinity: false, cavc: true)
        # hearing held with previous decision where judge is not the same
        a11 = create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "AffinityToExcludedJudge", snamel: "60DaysAffinity").ssn}S", judge: other_judge, attorney: attorney, cavc: true)
        VACOLS::Case.where(bfcorlid: a11.bfcorlid, bfac: "7").update(bfmemid: excluded_judge.sattyid)

        b7 = create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "AffinityToExcludedJudge", snamel: "25DaysAffinity").ssn}S", judge: other_judge, attorney: attorney,
                                      affinity_start_date: 25.days.ago, cavc: true)
        VACOLS::Case.where(bfcorlid: b7.bfcorlid, bfac: "7").update(bfmemid: excluded_judge.sattyid)

        a12 = create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "AffinityToExcludedJudge", snamel: "3DaysAffinity").ssn}S", judge: other_judge, attorney: attorney,
                                      affinity_start_date: 3.days.ago, cavc: true)
        VACOLS::Case.where(bfcorlid: a12.bfcorlid, bfac: "7").update(bfmemid: excluded_judge.sattyid)

        a13 = create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "AffinityToExcludedJudge", snamel: "NoAppealAffinity").ssn}S", judge: other_judge, attorney: attorney, appeal_affinity: false, cavc: true)
        VACOLS::Case.where(bfcorlid: a13.bfcorlid, bfac: "7").update(bfmemid: excluded_judge.sattyid)

        b8 = create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "AffinityToBVAGSPORER", snamel: "25DaysAffinity").ssn}S", judge: excluded_judge, attorney: attorney,
                                      affinity_start_date: 25.days.ago, cavc: true)
        VACOLS::Case.where(bfcorlid: b8.bfcorlid, bfac: "7").update(bfmemid: affinity_judge.sattyid)

        b9 = create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "AffinityToBVAEEMARD", snamel: "25DaysAffinity").ssn}S", judge: excluded_judge, attorney: attorney,
                                      affinity_start_date: 25.days.ago, cavc: true)
        VACOLS::Case.where(bfcorlid: b9.bfcorlid, bfac: "7").update(bfmemid: affinity_and_tied_to_judge.sattyid)

        b10 = create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "AffinityToBVABDANIEL", snamel: "25DaysAffinity").ssn}S", judge: excluded_judge, attorney: attorney,
                                      affinity_start_date: 25.days.ago, cavc: true)
        VACOLS::Case.where(bfcorlid: b10.bfcorlid, bfac: "7").update(bfmemid: tied_to_judge.sattyid)

        # hearing held with previous decision where judge is same (THIS IS TIED TO)
        create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "TiedToExcludedJudge", snamel: "60DaysAffinity").ssn}S", judge: excluded_judge, attorney: attorney, cavc: true)
        create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "TiedToExcludedJudge", snamel: "25DaysAffinity").ssn}S", judge: excluded_judge, attorney: attorney, affinity_start_date: 25.days.ago, cavc: true)
        create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "TiedToExcludedJudge", snamel: "3DaysAffinity").ssn}S", judge: excluded_judge, attorney: attorney, affinity_start_date: 3.days.ago, cavc: true)
        create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "TiedToExcludedJudge", snamel: "NoAppealAffinity").ssn}S", judge: excluded_judge, attorney: attorney, appeal_affinity: false, cavc: true)
    end

    def create_cases_for_aoj_cavc_affinity_days_lever_ineligible_judge
      # ineligible judge cases:
        # no hearing held but has previous decision
        create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "AffinityToIneligibleUser", snamel: "60DaysAffinity").ssn}S", judge: ineligible_judge, attorney: attorney, tied_to: false, cavc: true)
        create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "AffinityToIneligibleUser", snamel: "25DaysAffinity").ssn}S", judge: ineligible_judge, attorney: attorney,
                                      tied_to: false, affinity_start_date: 25.days.ago, cavc: true)
        create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "AffinityToIneligibleUser", snamel: "3DaysAffinity").ssn}S", judge: ineligible_judge, attorney: attorney,
                                      tied_to: false, affinity_start_date: 3.days.ago, cavc: true)
        create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "AffinityToIneligibleUser", snamel: "NoAppealAffinity").ssn}S", judge: ineligible_judge, attorney: attorney,
                                      tied_to: false, appeal_affinity: false, cavc: true)
        # hearing held with previous decision where judge is not the same
        a14 = create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "AffinityToIneligibleUser", snamel: "60DaysAffinity").ssn}S", judge: other_judge, attorney: attorney, cavc: true)
        VACOLS::Case.where(bfcorlid: a14.bfcorlid, bfac: "7").update(bfmemid: ineligible_judge.sattyid)

        b11 = create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "AffinityToIneligibleUser", snamel: "25DaysAffinity").ssn}S", judge: other_judge, attorney: attorney,
                                            affinity_start_date: 25.days.ago, cavc: true)
        VACOLS::Case.where(bfcorlid: b11.bfcorlid, bfac: "7").update(bfmemid: ineligible_judge.sattyid)

        a15 = create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "AffinityToIneligibleUser", snamel: "3DaysAffinity").ssn}S", judge: other_judge, attorney: attorney,
                                            affinity_start_date: 3.days.ago, cavc: true)
        VACOLS::Case.where(bfcorlid: a15.bfcorlid, bfac: "7").update(bfmemid: ineligible_judge.sattyid)

        a16 = create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "AffinityToIneligibleUser", snamel: "NoAppealAffinity").ssn}S", judge: other_judge, attorney: attorney, appeal_affinity: false, cavc: true)
        VACOLS::Case.where(bfcorlid: a16.bfcorlid, bfac: "7").update(bfmemid: ineligible_judge.sattyid)

        b12 = create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "AffinityToBVAGSPORER", snamel: "25DaysAffinity").ssn}S", judge: ineligible_judge, attorney: attorney,
                                            affinity_start_date: 25.days.ago, cavc: true)
        VACOLS::Case.where(bfcorlid: b12.bfcorlid, bfac: "7").update(bfmemid: affinity_judge.sattyid)

        b13 = create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "AffinityToBVAEEMARD", snamel: "25DaysAffinity").ssn}S", judge: ineligible_judge, attorney: attorney,
                                            affinity_start_date: 25.days.ago, cavc: true)
        VACOLS::Case.where(bfcorlid: b13.bfcorlid, bfac: "7").update(bfmemid: affinity_and_tied_to_judge.sattyid)

        b14 = create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "AffinityToBVABDANIEL", snamel: "25DaysAffinity").ssn}S", judge: ineligible_judge, attorney: attorney,
                                            affinity_start_date: 25.days.ago, cavc: true)
        VACOLS::Case.where(bfcorlid: b14.bfcorlid, bfac: "7").update(bfmemid: tied_to_judge.sattyid)

        b15 = create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "AffinityToBVAGSPORER", snamel: "3DaysAffinity").ssn}S", judge: ineligible_judge, attorney: attorney,
                                            affinity_start_date: 3.days.ago, cavc: true)
        VACOLS::Case.where(bfcorlid: b15.bfcorlid, bfac: "7").update(bfmemid: affinity_judge.sattyid)

        b16 = create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "AffinityToBVAEEMARD", snamel: "3DaysAffinity").ssn}S", judge: ineligible_judge, attorney: attorney,
                                            affinity_start_date: 3.days.ago, cavc: true)
        VACOLS::Case.where(bfcorlid: b16.bfcorlid, bfac: "7").update(bfmemid: affinity_and_tied_to_judge.sattyid)

        b17 = create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "AffinityToBVABDANIEL", snamel: "3DaysAffinity").ssn}S", judge: ineligible_judge, attorney: attorney,
                                            affinity_start_date: 3.days.ago, cavc: true)
        VACOLS::Case.where(bfcorlid: b17.bfcorlid, bfac: "7").update(bfmemid: tied_to_judge.sattyid)

        # hearing held with previous decision where judge is same (THIS IS TIED TO)
        create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "TiedToIneligibleJudge", snamel: "60DaysAffinity").ssn}S", judge: ineligible_judge, attorney: attorney, cavc: true)
        create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "TiedToIneligibleJudge", snamel: "25DaysAffinity").ssn}S", judge: ineligible_judge, attorney: attorney,  affinity_start_date: 25.days.ago, cavc: true)
        create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "TiedToIneligibleJudge", snamel: "3DaysAffinity").ssn}S", judge: ineligible_judge, attorney: attorney,  affinity_start_date: 3.days.ago, cavc: true)
        create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "TiedToIneligibleJudge", snamel: "NoAppealAffinity").ssn}S", judge: ineligible_judge, attorney: attorney,  appeal_affinity: false, cavc: true)
        # hearing held but no previous deciding judge
        a17 = create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "Genpop60Days", snamel: "AffinityStartDate").ssn}S", judge: ineligible_judge, attorney: attorney, cavc: true)
        VACOLS::Case.where(bfcorlid: a17.bfcorlid, bfac: "7").update(bfmemid: nil)
    end

    def create_cases_for_aoj_cavc_with_hearing_after_decision
      h1 = create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "TiedToBVAGSPORER", snamel: "60DaysAffinityAfterDec").ssn}S", judge: affinity_judge, attorney: attorney, cavc: true, hearing_after_decision: true)
        VACOLS::Case.where(bfcorlid: h1.bfcorlid, bfac: "7").update(bfmemid: nil)
      h2 = create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "TiedToBVAEEMARD", snamel: "60DaysAffinityAfterDec").ssn}S", judge: affinity_and_tied_to_judge, attorney: attorney, cavc: true, hearing_after_decision: true)
        VACOLS::Case.where(bfcorlid: h2.bfcorlid, bfac: "7").update(bfmemid: nil)
      h3 = create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "TiedToBVABDANIEL", snamel: "60DaysAffinityAfterDec").ssn}S", judge: tied_to_judge, attorney: attorney, cavc: true, hearing_after_decision: true)
        VACOLS::Case.where(bfcorlid: h3.bfcorlid, bfac: "7").update(bfmemid: nil)

      h4 = create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "TiedToBVAGSPORER", snamel: "3DaysAffinityAfterDec").ssn}S", judge: affinity_judge, attorney: attorney, affinity_start_date: 3.days.ago, cavc: true, hearing_after_decision: true)
        VACOLS::Case.where(bfcorlid: h4.bfcorlid, bfac: "7").update(bfmemid: nil)
      h5 = create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "TiedToBVAEEMARD", snamel: "3DaysAffinityAfterDec").ssn}S", judge: affinity_and_tied_to_judge, attorney: attorney, affinity_start_date: 3.days.ago, cavc: true, hearing_after_decision: true)
        VACOLS::Case.where(bfcorlid: h5.bfcorlid, bfac: "7").update(bfmemid: nil)
      h6 = create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "TiedToBVABDANIEL", snamel: "3DaysAffinityAfterDec").ssn}S", judge: tied_to_judge, attorney: attorney, affinity_start_date: 3.days.ago, cavc: true, hearing_after_decision: true)
        VACOLS::Case.where(bfcorlid: h6.bfcorlid, bfac: "7").update(bfmemid: nil)

      h7 = create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "TiedToBVAEEMARD", snamel: "60DaysAffinityAfterDec").ssn}S", judge: affinity_and_tied_to_judge, attorney: attorney, cavc: true, hearing_after_decision: true)
        VACOLS::Case.where(bfcorlid: h7.bfcorlid, bfac: "7").update(bfmemid: affinity_judge.sattyid)
      h8 = create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "TiedToBVABDANIEL", snamel: "60DaysAffinityAfterDec").ssn}S", judge: tied_to_judge, attorney: attorney, cavc: true, hearing_after_decision: true)
        VACOLS::Case.where(bfcorlid: h8.bfcorlid, bfac: "7").update(bfmemid: affinity_and_tied_to_judge.sattyid)
      h9 = create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "TiedToBVAGSPORER", snamel: "60DaysAffinityAfterDec").ssn}S", judge: affinity_judge, attorney: attorney, cavc: true, hearing_after_decision: true)
        VACOLS::Case.where(bfcorlid: h9.bfcorlid, bfac: "7").update(bfmemid: tied_to_judge.sattyid)
      h10 = create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "TiedToExcludedJudge", snamel: "60DaysAffinityAfterDec").ssn}S", judge: excluded_judge, attorney: attorney, cavc: true, hearing_after_decision: true)
        VACOLS::Case.where(bfcorlid: h10.bfcorlid, bfac: "7").update(bfmemid: affinity_judge.sattyid)
      h11 = create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "TiedToExcludedJudge", snamel: "60DaysAffinityAfterDec").ssn}S", judge: excluded_judge, attorney: attorney, cavc: true, hearing_after_decision: true)
        VACOLS::Case.where(bfcorlid: h11.bfcorlid, bfac: "7").update(bfmemid: affinity_and_tied_to_judge.sattyid)
      h12 = create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "TiedToExcludedJudge", snamel: "60DaysAffinityAfterDec").ssn}S", judge: excluded_judge, attorney: attorney, cavc: true, hearing_after_decision: true)
        VACOLS::Case.where(bfcorlid: h12.bfcorlid, bfac: "7").update(bfmemid: tied_to_judge.sattyid)
      h13 = create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "AffinityToBVAGSPORER", snamel: "3DaysAffinityAfterDec").ssn}S", judge: ineligible_judge, attorney: attorney, affinity_start_date: 3.days.ago, cavc: true, hearing_after_decision: true)
        VACOLS::Case.where(bfcorlid: h13.bfcorlid, bfac: "7").update(bfmemid: affinity_judge.sattyid)
      h14 = create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "AffinityToBVAEEMARD", snamel: "3DaysAffinityAfterDec").ssn}S", judge: ineligible_judge, attorney: attorney, affinity_start_date: 3.days.ago, cavc: true, hearing_after_decision: true)
        VACOLS::Case.where(bfcorlid: h14.bfcorlid, bfac: "7").update(bfmemid: affinity_and_tied_to_judge.sattyid)
      h15 = create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "AffinityToBVABDANIEL", snamel: "3DaysAffinityAfterDec").ssn}S", judge: ineligible_judge, attorney: attorney, affinity_start_date: 3.days.ago, cavc: true, hearing_after_decision: true)
        VACOLS::Case.where(bfcorlid: h15.bfcorlid, bfac: "7").update(bfmemid: tied_to_judge.sattyid)

      create(:legacy_cavc_appeal, bfcorlid: "#{create_correspondent(snamef: "Genpop90Days", snamel: "AffinityStartDate").ssn}S",  judge: affinity_judge, attorney: attorney,
                                  tied_to: false, affinity_start_date: 90.days.ago, cavc: true)
      create(:legacy_cavc_appeal, bfcorlid: "#{create_correspondent(snamef: "Genpop60Days", snamel: "AffinityStartDate").ssn}S",  judge: affinity_judge, attorney: attorney,
                                  tied_to: false, affinity_start_date: 60.days.ago, cavc: true)
      create(:legacy_cavc_appeal, bfcorlid: "#{create_correspondent(snamef: "Genpop25Days", snamel: "AffinityStartDate").ssn}S",  judge: affinity_judge, attorney: attorney,
                                  tied_to: false, affinity_start_date: 25.days.ago, cavc: true)
      create(:legacy_cavc_appeal, bfcorlid: "#{create_correspondent(snamef: "Genpop3Days", snamel: "AffinityStartDate").ssn}S",  judge: affinity_judge, attorney: attorney,
                                  tied_to: false, affinity_start_date: 3.days.ago, cavc: true)
    end

    def create_cases_for_aoj_aod_affinty_days_lever
      # aoj aod affinity cases:
        # no hearing held but has previous decision
        create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent(snamef: "AffinityToBVAGSPORER", snamel: "60DaysAffinity").ssn}S",  judge: affinity_judge, attorney: attorney, tied_to: false)
        create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent(snamef: "AffinityToBVAGSPORER", snamel: "25DaysAffinity").ssn}S",  judge: affinity_judge, attorney: attorney,
                                    tied_to: false, affinity_start_date: 25.days.ago)
        create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent(snamef: "AffinityToBVAGSPORER", snamel: "3DaysAffinity").ssn}S",  judge: affinity_judge, attorney: attorney,
                                    tied_to: false, affinity_start_date: 3.days.ago)
        create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent(snamef: "AffinityToBVAGSPORER", snamel: "30DaysAffinity").ssn}S",  judge: affinity_judge, attorney: attorney,
                                    tied_to: false, affinity_start_date: 30.days.ago, cavc: true)
        create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent(snamef: "AffinityToBVAGSPORER", snamel: "60DaysAffinity").ssn}S",  judge: affinity_judge, attorney: attorney,
                                    tied_to: false, affinity_start_date: 60.days.ago, cavc: true)
        create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent(snamef: "AffinityToBVAGSPORER", snamel: "NoAppealAffinity").ssn}S",  judge: affinity_judge, attorney: attorney,
                                    tied_to: false, appeal_affinity: false)

        create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent(snamef: "AffinityToBVAEEMARD", snamel: "60DaysAffinity").ssn}S",  judge: affinity_and_tied_to_judge, attorney: attorney, tied_to: false)
        create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent(snamef: "AffinityToBVAEEMARD", snamel: "25DaysAffinity").ssn}S",  judge: affinity_and_tied_to_judge, attorney: attorney,
                                    tied_to: false, affinity_start_date: 25.days.ago)
        create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent(snamef: "AffinityToBVAEEMARD", snamel: "3DaysAffinity").ssn}S",  judge: affinity_and_tied_to_judge, attorney: attorney,
                                    tied_to: false, affinity_start_date: 3.days.ago)
        create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent(snamef: "AffinityToBVAEEMARD", snamel: "NoAppealAffinity").ssn}S",  judge: affinity_and_tied_to_judge, attorney: attorney,
                                    tied_to: false, appeal_affinity: false)

        create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent(snamef: "AffinityToBVABDANIEL", snamel: "60DaysAffinity").ssn}S",  judge: tied_to_judge, attorney: attorney, tied_to: false)
        create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent(snamef: "AffinityToBVABDANIEL", snamel: "25DaysAffinity").ssn}S", judge: tied_to_judge, attorney: attorney,
                                    tied_to: false, affinity_start_date: 25.days.ago)
        create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent(snamef: "AffinityToBVABDANIEL", snamel: "3DaysAffinity").ssn}S",  judge: tied_to_judge, attorney: attorney,
                                    tied_to: false, affinity_start_date: 3.days.ago)
        create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent(snamef: "AffinityToBVABDANIEL", snamel: "NoAppealAffinity").ssn}S",  judge: tied_to_judge, attorney: attorney,
                                    tied_to: false, appeal_affinity: false)
        # hearing held with previous decision where judge is not the same
        ca1 = create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent(snamef: "AffinityToBVAGSPORER", snamel: "60DaysAffinity").ssn}S", judge: other_judge, attorney: attorney)
        VACOLS::Case.where(bfcorlid: ca1.bfcorlid, bfac: "1").update(bfmemid: affinity_judge.sattyid)

        cb1 = create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent(snamef: "AffinityToBVAGSPORER", snamel: "25DaysAffinity").ssn}S", judge: other_judge, attorney: attorney,
                                          affinity_start_date: 25.days.ago)
        VACOLS::Case.where(bfcorlid: cb1.bfcorlid, bfac: "1").update(bfmemid: affinity_judge.sattyid)

        ca2 = create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent(snamef: "AffinityToBVAGSPORER", snamel: "3DaysAffinity").ssn}S", judge: other_judge, attorney: attorney,
                                          affinity_start_date: 3.days.ago)
        VACOLS::Case.where(bfcorlid: ca2.bfcorlid, bfac: "1").update(bfmemid: affinity_judge.sattyid)

        ca3 = create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent(snamef: "AffinityToBVAGSPORER", snamel: "NoAppealAffinity").ssn}S", judge: other_judge, attorney: attorney, appeal_affinity: false)
        VACOLS::Case.where(bfcorlid: ca3.bfcorlid, bfac: "1").update(bfmemid: affinity_judge.sattyid)

        ca4 = create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent(snamef: "AffinityToBVAEEMARD", snamel: "60DaysAffinity").ssn}S", judge: other_judge, attorney: attorney)
        VACOLS::Case.where(bfcorlid: ca4.bfcorlid, bfac: "1").update(bfmemid: affinity_and_tied_to_judge.sattyid)

        cb2 = create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent(snamef: "AffinityToBVAEEMARD", snamel: "25DaysAffinity").ssn}S", judge: other_judge, attorney: attorney,
                                          affinity_start_date: 25.days.ago)
        VACOLS::Case.where(bfcorlid: cb2.bfcorlid, bfac: "1").update(bfmemid: affinity_and_tied_to_judge.sattyid)

        ca5 = create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent(snamef: "AffinityToBVAEEMARD", snamel: "3DaysAffinity").ssn}S", judge: other_judge, attorney: attorney,
                                          affinity_start_date: 3.days.ago)
        VACOLS::Case.where(bfcorlid: ca5.bfcorlid, bfac: "1").update(bfmemid: affinity_and_tied_to_judge.sattyid)

        ca6 = create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent(snamef: "AffinityToBVAEEMARD", snamel: "NoAppealAffinity").ssn}S", judge: other_judge, attorney: attorney, appeal_affinity: false)
        VACOLS::Case.where(bfcorlid: ca6.bfcorlid, bfac: "1").update(bfmemid: affinity_and_tied_to_judge.sattyid)

        cb3 = create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent(snamef: "AffinityToBVABDANIEL", snamel: "60DaysAffinity").ssn}S", judge: other_judge, attorney: attorney)
        VACOLS::Case.where(bfcorlid: cb3.bfcorlid, bfac: "1").update(bfmemid: tied_to_judge.sattyid)

        cb4 = create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent(snamef: "AffinityToBVABDANIEL", snamel: "25DaysAffinity").ssn}S", judge: other_judge, attorney: attorney,
                                          affinity_start_date: 25.days.ago)
        VACOLS::Case.where(bfcorlid: cb4.bfcorlid, bfac: "1").update(bfmemid: tied_to_judge.sattyid)

        cb5 = create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent(snamef: "AffinityToBVABDANIEL", snamel: "3DaysAffinity").ssn}S", judge: other_judge, attorney: attorney,
                                          affinity_start_date: 3.days.ago)
        VACOLS::Case.where(bfcorlid: cb5.bfcorlid, bfac: "1").update(bfmemid: tied_to_judge.sattyid)

        cb6 = create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent(snamef: "AffinityToBVABDANIEL", snamel: "NoAppealAffinity").ssn}S", judge: other_judge, attorney: attorney, appeal_affinity: false)
        VACOLS::Case.where(bfcorlid: cb6.bfcorlid, bfac: "1").update(bfmemid: tied_to_judge.sattyid)

        # hearing held with previous decision where judge is same (THIS IS TIED TO)
        create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent(snamef: "TiedToBVABDANIEL", snamel: "60DaysAffinity").ssn}S", judge: tied_to_judge, attorney: attorney)
        create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent(snamef: "TiedToBVABDANIEL", snamel: "25DaysAffinity").ssn}S", judge: tied_to_judge, attorney: attorney, affinity_start_date: 25.days.ago)
        create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent(snamef: "TiedToBVABDANIEL", snamel: "3DaysAffinity").ssn}S", judge: tied_to_judge, attorney: attorney, affinity_start_date: 3.days.ago)
        create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent(snamef: "TiedToBVABDANIEL", snamel: "NoAppealAffinity").ssn}S", judge: tied_to_judge, attorney: attorney, appeal_affinity: false)
        create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent(snamef: "TiedToBVAEEMARD", snamel: "60DaysAffinity").ssn}S",  judge: affinity_and_tied_to_judge, attorney: attorney)
        create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent(snamef: "TiedToBVAEEMARD", snamel: "25DaysAffinity").ssn}S",  judge: affinity_and_tied_to_judge, attorney: attorney, affinity_start_date: 25.days.ago)
        create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent(snamef: "TiedToBVAEEMARD", snamel: "3DaysAffinity").ssn}S",  judge: affinity_and_tied_to_judge, attorney: attorney, affinity_start_date: 3.days.ago)
        create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent(snamef: "TiedToBVAEEMARD", snamel: "NoAppealAffinity").ssn}S",  judge: affinity_and_tied_to_judge, attorney: attorney, appeal_affinity: false)
        create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent(snamef: "TiedToBVAGSPORER", snamel: "60DaysAffinity").ssn}S",  judge: affinity_judge, attorney: attorney)
        create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent(snamef: "TiedToBVAGSPORER", snamel: "25DaysAffinity").ssn}S",  judge: affinity_judge, attorney: attorney, affinity_start_date: 25.days.ago)
        create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent(snamef: "TiedToBVAGSPORER", snamel: "3DaysAffinity").ssn}S",  judge: affinity_judge, attorney: attorney, affinity_start_date: 3.days.ago)
        create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent(snamef: "TiedToBVAGSPORER", snamel: "NoAppealAffinity").ssn}S",  judge: affinity_judge, attorney: attorney, appeal_affinity: false)
        # hearing held but no previous deciding judge
        ca7 = create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent(snamef: "Genpop60Days", snamel: "AffinityStartDate").ssn}S", judge: tied_to_judge, attorney: attorney)
        VACOLS::Case.where(bfcorlid: ca7.bfcorlid, bfac: "1").update(bfmemid: nil)

        ca8 = create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent(snamef: "Genpop60Days", snamel: "AffinityStartDate").ssn}S",  judge: affinity_and_tied_to_judge, attorney: attorney)
        VACOLS::Case.where(bfcorlid: ca8.bfcorlid, bfac: "1").update(bfmemid: nil)

        # no hearing held, no previous deciding judge
        ca9 = create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent(snamef: "Genpop60Days", snamel: "AffinityStartDate").ssn}S", judge: affinity_judge, attorney: attorney,
                                          tied_to: false)
        VACOLS::Case.where(bfcorlid: ca9.bfcorlid, bfac: "1").update(bfmemid: nil)

        ca10 = create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent(snamef: "Genpop60Days", snamel: "AffinityStartDate").ssn}S",  judge: affinity_and_tied_to_judge, attorney: attorney,
                                          tied_to: false)
        VACOLS::Case.where(bfcorlid: ca10.bfcorlid, bfac: "1").update(bfmemid: nil)

        cb18 = create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent(snamef: "Genpop3Days", snamel: "AffinityStartDate").ssn}S", judge: affinity_judge, attorney: attorney,
                                          tied_to: false, affinity_start_date: 3.days.ago)
        VACOLS::Case.where(bfcorlid: cb18.bfcorlid, bfac: "1").update(bfmemid: nil)

        cb19 = create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent(snamef: "Genpop3Days", snamel: "AffinityStartDate").ssn}S",  judge: affinity_and_tied_to_judge, attorney: attorney,
                                          tied_to: false, affinity_start_date: 3.days.ago)
        VACOLS::Case.where(bfcorlid: cb19.bfcorlid, bfac: "1").update(bfmemid: nil)
    end

    def create_cases_for_aoj_aod_affinty_days_lever_excluded_judge
      # excluded judge cases:
        # no hearing held but has previous decision
        create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent(snamef: "AffinityToExcludedJudge", snamel: "60DaysAffinity").ssn}S", judge: excluded_judge, attorney: attorney, tied_to: false)
        create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent(snamef: "AffinityToExcludedJudge", snamel: "25DaysAffinity").ssn}S", judge: excluded_judge, attorney: attorney,
                                      tied_to: false, affinity_start_date: 25.days.ago)
        create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent(snamef: "AffinityToExcludedJudge", snamel: "3DaysAffinity").ssn}S", judge: excluded_judge, attorney: attorney,
                                      tied_to: false, affinity_start_date: 3.days.ago)
        create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent(snamef: "AffinityToExcludedJudge", snamel: "NoAppealAffinity").ssn}S", judge: excluded_judge, attorney: attorney,
                                      tied_to: false, appeal_affinity: false)
        # hearing held with previous decision where judge is not the same
        ca11 = create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent(snamef: "AffinityToExcludedJudge", snamel: "60DaysAffinity").ssn}S", judge: other_judge, attorney: attorney)
        VACOLS::Case.where(bfcorlid: ca11.bfcorlid, bfac: "1").update(bfmemid: excluded_judge.sattyid)

        cb7 = create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent(snamef: "AffinityToExcludedJudge", snamel: "25DaysAffinity").ssn}S", judge: other_judge, attorney: attorney,
                                      affinity_start_date: 25.days.ago)
        VACOLS::Case.where(bfcorlid: cb7.bfcorlid, bfac: "1").update(bfmemid: excluded_judge.sattyid)

        ca12 = create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent(snamef: "AffinityToExcludedJudge", snamel: "3DaysAffinity").ssn}S", judge: other_judge, attorney: attorney,
                                      affinity_start_date: 3.days.ago)
        VACOLS::Case.where(bfcorlid: ca12.bfcorlid, bfac: "1").update(bfmemid: excluded_judge.sattyid)

        ca13 = create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent(snamef: "AffinityToExcludedJudge", snamel: "NoAppealAffinity").ssn}S", judge: other_judge, attorney: attorney, appeal_affinity: false)
        VACOLS::Case.where(bfcorlid: ca13.bfcorlid, bfac: "1").update(bfmemid: excluded_judge.sattyid)

        cb8 = create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent(snamef: "AffinityToBVAGSPORER", snamel: "25DaysAffinity").ssn}S", judge: excluded_judge, attorney: attorney,
                                      affinity_start_date: 25.days.ago)
        VACOLS::Case.where(bfcorlid: cb8.bfcorlid, bfac: "1").update(bfmemid: affinity_judge.sattyid)

        cb9 = create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent(snamef: "AffinityToBVAEEMARD", snamel: "25DaysAffinity").ssn}S", judge: excluded_judge, attorney: attorney,
                                      affinity_start_date: 25.days.ago)
        VACOLS::Case.where(bfcorlid: cb9.bfcorlid, bfac: "1").update(bfmemid: affinity_and_tied_to_judge.sattyid)

        cb10 = create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent(snamef: "AffinityToBVABDANIEL", snamel: "25DaysAffinity").ssn}S", judge: excluded_judge, attorney: attorney,
                                      affinity_start_date: 25.days.ago)
        VACOLS::Case.where(bfcorlid: cb10.bfcorlid, bfac: "1").update(bfmemid: tied_to_judge.sattyid)

        # hearing held with previous decision where judge is same (THIS IS TIED TO)
        create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent(snamef: "TiedToExcludedJudge", snamel: "60DaysAffinity").ssn}S", judge: excluded_judge, attorney: attorney)
        create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent(snamef: "TiedToExcludedJudge", snamel: "25DaysAffinity").ssn}S", judge: excluded_judge, attorney: attorney, affinity_start_date: 25.days.ago)
        create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent(snamef: "TiedToExcludedJudge", snamel: "3DaysAffinity").ssn}S", judge: excluded_judge, attorney: attorney, affinity_start_date: 3.days.ago)
        create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent(snamef: "TiedToExcludedJudge", snamel: "NoAppealAffinity").ssn}S", judge: excluded_judge, attorney: attorney, appeal_affinity: false)
    end

    def create_cases_for_aoj_aod_affinity_days_lever_ineligible_judge
      # ineligible judge cases:
        # no hearing held but has previous decision
        create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent(snamef: "AffinityToIneligibleUser", snamel: "60DaysAffinity").ssn}S", judge: ineligible_judge, attorney: attorney, tied_to: false)
        create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent(snamef: "AffinityToIneligibleUser", snamel: "25DaysAffinity").ssn}S", judge: ineligible_judge, attorney: attorney,
                                      tied_to: false, affinity_start_date: 25.days.ago)
        create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent(snamef: "AffinityToIneligibleUser", snamel: "3DaysAffinity").ssn}S", judge: ineligible_judge, attorney: attorney,
                                      tied_to: false, affinity_start_date: 3.days.ago)
        create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent(snamef: "AffinityToIneligibleUser", snamel: "NoAppealAffinity").ssn}S", judge: ineligible_judge, attorney: attorney,
                                      tied_to: false, appeal_affinity: false)
        # hearing held with previous decision where judge is not the same
        ca14 = create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent(snamef: "AffinityToIneligibleUser", snamel: "60DaysAffinity").ssn}S", judge: other_judge, attorney: attorney)
        VACOLS::Case.where(bfcorlid: ca14.bfcorlid, bfac: "1").update(bfmemid: ineligible_judge.sattyid)

        cb11 = create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent(snamef: "AffinityToIneligibleUser", snamel: "25DaysAffinity").ssn}S", judge: other_judge, attorney: attorney,
                                            affinity_start_date: 25.days.ago)
        VACOLS::Case.where(bfcorlid: cb11.bfcorlid, bfac: "1").update(bfmemid: ineligible_judge.sattyid)

        ca15 = create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent(snamef: "AffinityToIneligibleUser", snamel: "3DaysAffinity").ssn}S", judge: other_judge, attorney: attorney,
                                            affinity_start_date: 3.days.ago)
        VACOLS::Case.where(bfcorlid: ca15.bfcorlid, bfac: "1").update(bfmemid: ineligible_judge.sattyid)

        ca16 = create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent(snamef: "AffinityToIneligibleUser", snamel: "NoAppealAffinity").ssn}S", judge: other_judge, attorney: attorney, appeal_affinity: false)
        VACOLS::Case.where(bfcorlid: ca16.bfcorlid, bfac: "1").update(bfmemid: ineligible_judge.sattyid)

        cb12 = create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent(snamef: "AffinityToBVAGSPORER", snamel: "25DaysAffinity").ssn}S", judge: ineligible_judge, attorney: attorney,
                                            affinity_start_date: 25.days.ago)
        VACOLS::Case.where(bfcorlid: cb12.bfcorlid, bfac: "1").update(bfmemid: affinity_judge.sattyid)

        cb13 = create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent(snamef: "AffinityToBVAEEMARD", snamel: "25DaysAffinity").ssn}S", judge: ineligible_judge, attorney: attorney,
                                            affinity_start_date: 25.days.ago)
        VACOLS::Case.where(bfcorlid: cb13.bfcorlid, bfac: "1").update(bfmemid: affinity_and_tied_to_judge.sattyid)

        cb14 = create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent(snamef: "AffinityToBVABDANIEL", snamel: "25DaysAffinity").ssn}S", judge: ineligible_judge, attorney: attorney,
                                            affinity_start_date: 25.days.ago)
        VACOLS::Case.where(bfcorlid: cb14.bfcorlid, bfac: "1").update(bfmemid: tied_to_judge.sattyid)

        cb15 = create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent(snamef: "AffinityToBVAGSPORER", snamel: "3DaysAffinity").ssn}S", judge: ineligible_judge, attorney: attorney,
                                            affinity_start_date: 3.days.ago)
        VACOLS::Case.where(bfcorlid: cb15.bfcorlid, bfac: "1").update(bfmemid: affinity_judge.sattyid)

        cb16 = create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent(snamef: "AffinityToBVAEEMARD", snamel: "3DaysAffinity").ssn}S", judge: ineligible_judge, attorney: attorney,
                                            affinity_start_date: 3.days.ago)
        VACOLS::Case.where(bfcorlid: cb16.bfcorlid, bfac: "1").update(bfmemid: affinity_and_tied_to_judge.sattyid)

        cb17 = create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent(snamef: "AffinityToBVABDANIEL", snamel: "3DaysAffinity").ssn}S", judge: ineligible_judge, attorney: attorney,
                                            affinity_start_date: 3.days.ago)
        VACOLS::Case.where(bfcorlid: cb17.bfcorlid, bfac: "1").update(bfmemid: tied_to_judge.sattyid)

        # hearing held with previous decision where judge is same (THIS IS TIED TO)
        create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent(snamef: "TiedToIneligibleJudge", snamel: "60DaysAffinity").ssn}S", judge: ineligible_judge, attorney: attorney)
        create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent(snamef: "TiedToIneligibleJudge", snamel: "25DaysAffinity").ssn}S", judge: ineligible_judge, attorney: attorney,  affinity_start_date: 25.days.ago)
        create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent(snamef: "TiedToIneligibleJudge", snamel: "3DaysAffinity").ssn}S", judge: ineligible_judge, attorney: attorney,  affinity_start_date: 3.days.ago)
        create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent(snamef: "TiedToIneligibleJudge", snamel: "NoAppealAffinity").ssn}S", judge: ineligible_judge, attorney: attorney,  appeal_affinity: false)
        # hearing held but no previous deciding judge
        ca17 = create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "Genpop60Days", snamel: "AffinityStartDate").ssn}S", judge: ineligible_judge, attorney: attorney)
        VACOLS::Case.where(bfcorlid: ca17.bfcorlid, bfac: "1").update(bfmemid: nil)
    end

    def create_cases_for_aoj_aod_with_hearing_after_decision
      ch1 = create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent(snamef: "TiedToBVAGSPORER", snamel: "60DaysAffinityAfterDec").ssn}S", judge: affinity_judge, attorney: attorney, hearing_after_decision: true)
        VACOLS::Case.where(bfcorlid: ch1.bfcorlid, bfac: "1").update(bfmemid: nil)

      ch2 = create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent(snamef: "TiedToBVAEEMARD", snamel: "60DaysAffinityAfterDec").ssn}S", judge: affinity_and_tied_to_judge, attorney: attorney, hearing_after_decision: true)
        VACOLS::Case.where(bfcorlid: ch2.bfcorlid, bfac: "1").update(bfmemid: nil)

      ch3 = create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent(snamef: "TiedToBVABDANIEL", snamel: "60DaysAffinityAfterDec").ssn}S", judge: tied_to_judge, attorney: attorney, hearing_after_decision: true)
        VACOLS::Case.where(bfcorlid: ch3.bfcorlid, bfac: "1").update(bfmemid: nil)

      ch4 = create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent(snamef: "TiedToBVAGSPORER", snamel: "3DaysAffinityAfterDec").ssn}S", judge: affinity_judge, attorney: attorney, affinity_start_date: 3.days.ago, hearing_after_decision: true)
        VACOLS::Case.where(bfcorlid: ch4.bfcorlid, bfac: "1").update(bfmemid: nil)

      ch5 = create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent(snamef: "TiedToBVAEEMARD", snamel: "3DaysAffinityAfterDec").ssn}S", judge: affinity_and_tied_to_judge, attorney: attorney, affinity_start_date: 3.days.ago, hearing_after_decision: true)
        VACOLS::Case.where(bfcorlid: ch5.bfcorlid, bfac: "1").update(bfmemid: nil)

      ch6 = create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent(snamef: "TiedToBVABDANIEL", snamel: "3DaysAffinityAfterDec").ssn}S", judge: tied_to_judge, attorney: attorney, affinity_start_date: 3.days.ago, hearing_after_decision: true)
        VACOLS::Case.where(bfcorlid: ch6.bfcorlid, bfac: "1").update(bfmemid: nil)

      ch7 = create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent(snamef: "TiedToBVAEEMARD", snamel: "60DaysAffinityAfterDec").ssn}S", judge: affinity_and_tied_to_judge, attorney: attorney, hearing_after_decision: true)
        VACOLS::Case.where(bfcorlid: ch7.bfcorlid, bfac: "1").update(bfmemid: affinity_judge.sattyid)

      ch8 = create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent(snamef: "TiedToBVABDANIEL", snamel: "60DaysAffinityAfterDec").ssn}S", judge: tied_to_judge, attorney: attorney, hearing_after_decision: true)
        VACOLS::Case.where(bfcorlid: ch8.bfcorlid, bfac: "1").update(bfmemid: affinity_and_tied_to_judge.sattyid)

      ch9 = create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent(snamef: "TiedToBVAGSPORER", snamel: "60DaysAffinityAfterDec").ssn}S", judge: affinity_judge, attorney: attorney, hearing_after_decision: true)
        VACOLS::Case.where(bfcorlid: ch9.bfcorlid, bfac: "1").update(bfmemid: tied_to_judge.sattyid)

      ch10 = create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent(snamef: "TiedToExcludedJudge", snamel: "60DaysAffinityAfterDec").ssn}S", judge: excluded_judge, attorney: attorney, hearing_after_decision: true)
        VACOLS::Case.where(bfcorlid: ch10.bfcorlid, bfac: "1").update(bfmemid: affinity_judge.sattyid)

      ch11 = create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent(snamef: "TiedToExcludedJudge", snamel: "60DaysAffinityAfterDec").ssn}S", judge: excluded_judge, attorney: attorney, hearing_after_decision: true)
        VACOLS::Case.where(bfcorlid: ch11.bfcorlid, bfac: "1").update(bfmemid: affinity_and_tied_to_judge.sattyid)

      ch12 = create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent(snamef: "TiedToExcludedJudge", snamel: "60DaysAffinityAfterDec").ssn}S", judge: excluded_judge, attorney: attorney, hearing_after_decision: true)
        VACOLS::Case.where(bfcorlid: ch12.bfcorlid, bfac: "1").update(bfmemid: tied_to_judge.sattyid)
      ch13 = create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent(snamef: "AffinityToBVAGSPORER", snamel: "3DaysAffinityAfterDec").ssn}S", judge: ineligible_judge, attorney: attorney, affinity_start_date: 3.days.ago, hearing_after_decision: true)
        VACOLS::Case.where(bfcorlid: ch13.bfcorlid, bfac: "1").update(bfmemid: affinity_judge.sattyid)

      ch14 = create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent(snamef: "AffinityToBVAEEMARD", snamel: "3DaysAffinityAfterDec").ssn}S", judge: ineligible_judge, attorney: attorney, affinity_start_date: 3.days.ago, hearing_after_decision: true)
        VACOLS::Case.where(bfcorlid: ch14.bfcorlid, bfac: "1").update(bfmemid: affinity_and_tied_to_judge.sattyid)

      ch15 = create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent(snamef: "AffinityToBVABDANIEL", snamel: "3DaysAffinityAfterDec").ssn}S", judge: ineligible_judge, attorney: attorney, affinity_start_date: 3.days.ago, hearing_after_decision: true)
        VACOLS::Case.where(bfcorlid: ch15.bfcorlid, bfac: "1").update(bfmemid: tied_to_judge.sattyid)

      create(:legacy_cavc_appeal, :aod, bfcorlid: "#{create_correspondent(snamef: "Genpop90Days", snamel: "AffinityStartDate").ssn}S",  judge: affinity_judge, attorney: attorney,
                                  tied_to: false, affinity_start_date: 90.days.ago)
      create(:legacy_cavc_appeal, :aod, bfcorlid: "#{create_correspondent(snamef: "Genpop60Days", snamel: "AffinityStartDate").ssn}S",  judge: affinity_judge, attorney: attorney,
                                  tied_to: false, affinity_start_date: 60.days.ago)
      create(:legacy_cavc_appeal, :aod, bfcorlid: "#{create_correspondent(snamef: "Genpop25Days", snamel: "AffinityStartDate").ssn}S",  judge: affinity_judge, attorney: attorney,
                                  tied_to: false, affinity_start_date: 25.days.ago)
      create(:legacy_cavc_appeal, :aod, bfcorlid: "#{create_correspondent(snamef: "Genpop3Days", snamel: "AffinityStartDate").ssn}S",  judge: affinity_judge, attorney: attorney,
                                  tied_to: false, affinity_start_date: 3.days.ago)
    end

    def create_cases_for_aoj_affinity_days_lever
      # aoj affinity cases:
        # no hearing held but has previous decision
        create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "AffinityToBVAGSPORER", snamel: "60DaysAffinity").ssn}S",  judge: affinity_judge, attorney: attorney, tied_to: false)
        create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "AffinityToBVAGSPORER", snamel: "25DaysAffinity").ssn}S",  judge: affinity_judge, attorney: attorney,
                                    tied_to: false, affinity_start_date: 25.days.ago)
        create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "AffinityToBVAGSPORER", snamel: "3DaysAffinity").ssn}S",  judge: affinity_judge, attorney: attorney,
                                    tied_to: false, affinity_start_date: 3.days.ago)
        create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "AffinityToBVAGSPORER", snamel: "30DaysAffinity").ssn}S",  judge: affinity_judge, attorney: attorney,
                                    tied_to: false, affinity_start_date: 30.days.ago, cavc: true)
        create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "AffinityToBVAGSPORER", snamel: "60DaysAffinity").ssn}S",  judge: affinity_judge, attorney: attorney,
                                    tied_to: false, affinity_start_date: 60.days.ago, cavc: true)
        create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "AffinityToBVAGSPORER", snamel: "NoAppealAffinity").ssn}S",  judge: affinity_judge, attorney: attorney,
                                    tied_to: false, appeal_affinity: false)

        create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "AffinityToBVAEEMARD", snamel: "60DaysAffinity").ssn}S",  judge: affinity_and_tied_to_judge, attorney: attorney, tied_to: false)
        create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "AffinityToBVAEEMARD", snamel: "25DaysAffinity").ssn}S",  judge: affinity_and_tied_to_judge, attorney: attorney,
                                    tied_to: false, affinity_start_date: 25.days.ago)
        create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "AffinityToBVAEEMARD", snamel: "3DaysAffinity").ssn}S",  judge: affinity_and_tied_to_judge, attorney: attorney,
                                    tied_to: false, affinity_start_date: 3.days.ago)
        create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "AffinityToBVAEEMARD", snamel: "NoAppealAffinity").ssn}S",  judge: affinity_and_tied_to_judge, attorney: attorney,
                                    tied_to: false, appeal_affinity: false)

        create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "AffinityToBVABDANIEL", snamel: "60DaysAffinity").ssn}S",  judge: tied_to_judge, attorney: attorney, tied_to: false)
        create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "AffinityToBVABDANIEL", snamel: "25DaysAffinity").ssn}S", judge: tied_to_judge, attorney: attorney,
                                    tied_to: false, affinity_start_date: 25.days.ago)
        create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "AffinityToBVABDANIEL", snamel: "3DaysAffinity").ssn}S",  judge: tied_to_judge, attorney: attorney,
                                    tied_to: false, affinity_start_date: 3.days.ago)
        create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "AffinityToBVABDANIEL", snamel: "NoAppealAffinity").ssn}S",  judge: tied_to_judge, attorney: attorney,
                                    tied_to: false, appeal_affinity: false)
        # hearing held with previous decision where judge is not the same
        ca1 = create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "AffinityToBVAGSPORER", snamel: "60DaysAffinity").ssn}S", judge: other_judge, attorney: attorney)
        VACOLS::Case.where(bfcorlid: ca1.bfcorlid, bfac: "1").update(bfmemid: affinity_judge.sattyid)

        cb1 = create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "AffinityToBVAGSPORER", snamel: "25DaysAffinity").ssn}S", judge: other_judge, attorney: attorney,
                                          affinity_start_date: 25.days.ago)
        VACOLS::Case.where(bfcorlid: cb1.bfcorlid, bfac: "1").update(bfmemid: affinity_judge.sattyid)

        ca2 = create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "AffinityToBVAGSPORER", snamel: "3DaysAffinity").ssn}S", judge: other_judge, attorney: attorney,
                                          affinity_start_date: 3.days.ago)
        VACOLS::Case.where(bfcorlid: ca2.bfcorlid, bfac: "1").update(bfmemid: affinity_judge.sattyid)

        ca3 = create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "AffinityToBVAGSPORER", snamel: "NoAppealAffinity").ssn}S", judge: other_judge, attorney: attorney, appeal_affinity: false)
        VACOLS::Case.where(bfcorlid: ca3.bfcorlid, bfac: "1").update(bfmemid: affinity_judge.sattyid)

        ca4 = create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "AffinityToBVAEEMARD", snamel: "60DaysAffinity").ssn}S", judge: other_judge, attorney: attorney)
        VACOLS::Case.where(bfcorlid: ca4.bfcorlid, bfac: "1").update(bfmemid: affinity_and_tied_to_judge.sattyid)

        cb2 = create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "AffinityToBVAEEMARD", snamel: "25DaysAffinity").ssn}S", judge: other_judge, attorney: attorney,
                                          affinity_start_date: 25.days.ago)
        VACOLS::Case.where(bfcorlid: cb2.bfcorlid, bfac: "1").update(bfmemid: affinity_and_tied_to_judge.sattyid)

        ca5 = create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "AffinityToBVAEEMARD", snamel: "3DaysAffinity").ssn}S", judge: other_judge, attorney: attorney,
                                          affinity_start_date: 3.days.ago)
        VACOLS::Case.where(bfcorlid: ca5.bfcorlid, bfac: "1").update(bfmemid: affinity_and_tied_to_judge.sattyid)

        ca6 = create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "AffinityToBVAEEMARD", snamel: "NoAppealAffinity").ssn}S", judge: other_judge, attorney: attorney, appeal_affinity: false)
        VACOLS::Case.where(bfcorlid: ca6.bfcorlid, bfac: "1").update(bfmemid: affinity_and_tied_to_judge.sattyid)

        cb3 = create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "AffinityToBVABDANIEL", snamel: "60DaysAffinity").ssn}S", judge: other_judge, attorney: attorney)
        VACOLS::Case.where(bfcorlid: cb3.bfcorlid, bfac: "1").update(bfmemid: tied_to_judge.sattyid)

        cb4 = create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "AffinityToBVABDANIEL", snamel: "25DaysAffinity").ssn}S", judge: other_judge, attorney: attorney,
                                          affinity_start_date: 25.days.ago)
        VACOLS::Case.where(bfcorlid: cb4.bfcorlid, bfac: "1").update(bfmemid: tied_to_judge.sattyid)

        cb5 = create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "AffinityToBVABDANIEL", snamel: "3DaysAffinity").ssn}S", judge: other_judge, attorney: attorney,
                                          affinity_start_date: 3.days.ago)
        VACOLS::Case.where(bfcorlid: cb5.bfcorlid, bfac: "1").update(bfmemid: tied_to_judge.sattyid)

        cb6 = create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "AffinityToBVABDANIEL", snamel: "NoAppealAffinity").ssn}S", judge: other_judge, attorney: attorney, appeal_affinity: false)
        VACOLS::Case.where(bfcorlid: cb6.bfcorlid, bfac: "1").update(bfmemid: tied_to_judge.sattyid)

        # hearing held with previous decision where judge is same (THIS IS TIED TO)
        create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "TiedToBVABDANIEL", snamel: "60DaysAffinity").ssn}S", judge: tied_to_judge, attorney: attorney)
        create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "TiedToBVABDANIEL", snamel: "25DaysAffinity").ssn}S", judge: tied_to_judge, attorney: attorney, affinity_start_date: 25.days.ago)
        create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "TiedToBVABDANIEL", snamel: "3DaysAffinity").ssn}S", judge: tied_to_judge, attorney: attorney, affinity_start_date: 3.days.ago)
        create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "TiedToBVABDANIEL", snamel: "NoAppealAffinity").ssn}S", judge: tied_to_judge, attorney: attorney, appeal_affinity: false)
        create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "TiedToBVAEEMARD", snamel: "60DaysAffinity").ssn}S",  judge: affinity_and_tied_to_judge, attorney: attorney)
        create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "TiedToBVAEEMARD", snamel: "25DaysAffinity").ssn}S",  judge: affinity_and_tied_to_judge, attorney: attorney, affinity_start_date: 25.days.ago)
        create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "TiedToBVAEEMARD", snamel: "3DaysAffinity").ssn}S",  judge: affinity_and_tied_to_judge, attorney: attorney, affinity_start_date: 3.days.ago)
        create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "TiedToBVAEEMARD", snamel: "NoAppealAffinity").ssn}S",  judge: affinity_and_tied_to_judge, attorney: attorney, appeal_affinity: false)
        create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "TiedToBVAGSPORER", snamel: "60DaysAffinity").ssn}S", judge: affinity_judge, attorney: attorney)
        create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "TiedToBVAGSPORER", snamel: "25DaysAffinity").ssn}S",  judge: affinity_judge, attorney: attorney, affinity_start_date: 25.days.ago)
        create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "TiedToBVAGSPORER", snamel: "3DaysAffinity").ssn}S",  judge: affinity_judge, attorney: attorney, affinity_start_date: 3.days.ago)
        create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "TiedToBVAGSPORER", snamel: "NoAppealAffinity").ssn}S",  judge: affinity_judge, attorney: attorney, appeal_affinity: false)
        # hearing held but no previous deciding judge
        ca7 = create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "Genpop60Days", snamel: "AffinityStartDate").ssn}S", judge: tied_to_judge, attorney: attorney)
        VACOLS::Case.where(bfcorlid: ca7.bfcorlid, bfac: "1").update(bfmemid: nil)

        ca8 = create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "Genpop60Days", snamel: "AffinityStartDate").ssn}S",  judge: affinity_and_tied_to_judge, attorney: attorney)
        VACOLS::Case.where(bfcorlid: ca8.bfcorlid, bfac: "1").update(bfmemid: nil)

        caa8 = create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "Genpop60Days", snamel: "AffinityStartDate").ssn}S",  judge: affinity_judge, attorney: attorney)
        VACOLS::Case.where(bfcorlid: caa8.bfcorlid, bfac: "1").update(bfmemid: nil)

        # no hearing held, no previous deciding judge
        ca9 = create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "Genpop60Days", snamel: "AffinityStartDate").ssn}S", judge: affinity_judge, attorney: attorney,
                                          tied_to: false)
        VACOLS::Case.where(bfcorlid: ca9.bfcorlid, bfac: "1").update(bfmemid: nil)

        ca10 = create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "Genpop60Days", snamel: "AffinityStartDate").ssn}S",  judge: affinity_and_tied_to_judge, attorney: attorney,
                                          tied_to: false)
        VACOLS::Case.where(bfcorlid: ca10.bfcorlid, bfac: "1").update(bfmemid: nil)

        cb18 = create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "Genpop3Days", snamel: "AffinityStartDate").ssn}S", judge: affinity_judge, attorney: attorney,
                                          tied_to: false, affinity_start_date: 3.days.ago)
        VACOLS::Case.where(bfcorlid: cb18.bfcorlid, bfac: "1").update(bfmemid: nil)

        cb19 = create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "Genpop3Days", snamel: "AffinityStartDate").ssn}S",  judge: affinity_and_tied_to_judge, attorney: attorney,
                                          tied_to: false, affinity_start_date: 3.days.ago)
        VACOLS::Case.where(bfcorlid: cb19.bfcorlid, bfac: "1").update(bfmemid: nil)
    end

    def create_cases_for_aoj_affinity_days_lever_excluded_judge
      # excluded judge cases:
        # no hearing held but has previous decision
        create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "AffinityToExcludedJudge", snamel: "60DaysAffinity").ssn}S", judge: excluded_judge, attorney: attorney, tied_to: false)
        create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "AffinityToExcludedJudge", snamel: "25DaysAffinity").ssn}S", judge: excluded_judge, attorney: attorney,
                                      tied_to: false, affinity_start_date: 25.days.ago)
        create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "AffinityToExcludedJudge", snamel: "3DaysAffinity").ssn}S", judge: excluded_judge, attorney: attorney,
                                      tied_to: false, affinity_start_date: 3.days.ago)
        create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "AffinityToExcludedJudge", snamel: "NoAppealAffinity").ssn}S", judge: excluded_judge, attorney: attorney,
                                      tied_to: false, appeal_affinity: false)
        # hearing held with previous decision where judge is not the same
        ca11 = create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "AffinityToExcludedJudge", snamel: "60DaysAffinity").ssn}S", judge: other_judge, attorney: attorney)
        VACOLS::Case.where(bfcorlid: ca11.bfcorlid, bfac: "1").update(bfmemid: excluded_judge.sattyid)

        cb7 = create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "AffinityToExcludedJudge", snamel: "25DaysAffinity").ssn}S", judge: other_judge, attorney: attorney,
                                      affinity_start_date: 25.days.ago)
        VACOLS::Case.where(bfcorlid: cb7.bfcorlid, bfac: "1").update(bfmemid: excluded_judge.sattyid)

        ca12 = create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "AffinityToExcludedJudge", snamel: "3DaysAffinity").ssn}S", judge: other_judge, attorney: attorney,
                                      affinity_start_date: 3.days.ago)
        VACOLS::Case.where(bfcorlid: ca12.bfcorlid, bfac: "1").update(bfmemid: excluded_judge.sattyid)

        ca13 = create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "AffinityToExcludedJudge", snamel: "NoAppealAffinity").ssn}S", judge: other_judge, attorney: attorney, appeal_affinity: false)
        VACOLS::Case.where(bfcorlid: ca13.bfcorlid, bfac: "1").update(bfmemid: excluded_judge.sattyid)

        cb8 = create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "AffinityToBVAGSPORER", snamel: "25DaysAffinity").ssn}S", judge: excluded_judge, attorney: attorney,
                                      affinity_start_date: 25.days.ago)
        VACOLS::Case.where(bfcorlid: cb8.bfcorlid, bfac: "1").update(bfmemid: affinity_judge.sattyid)

        cb9 = create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "AffinityToBVAEEMARD", snamel: "25DaysAffinity").ssn}S", judge: excluded_judge, attorney: attorney,
                                      affinity_start_date: 25.days.ago)
        VACOLS::Case.where(bfcorlid: cb9.bfcorlid, bfac: "1").update(bfmemid: affinity_and_tied_to_judge.sattyid)

        cb10 = create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "AffinityToBVABDANIEL", snamel: "25DaysAffinity").ssn}S", judge: excluded_judge, attorney: attorney,
                                      affinity_start_date: 25.days.ago)
        VACOLS::Case.where(bfcorlid: cb10.bfcorlid, bfac: "1").update(bfmemid: tied_to_judge.sattyid)

        # hearing held with previous decision where judge is same (THIS IS TIED TO)
        create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "TiedToExcludedJudge", snamel: "60DaysAffinity").ssn}S", judge: excluded_judge, attorney: attorney)
        create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "TiedToExcludedJudge", snamel: "25DaysAffinity").ssn}S", judge: excluded_judge, attorney: attorney, affinity_start_date: 25.days.ago)
        create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "TiedToExcludedJudge", snamel: "3DaysAffinity").ssn}S", judge: excluded_judge, attorney: attorney, affinity_start_date: 3.days.ago)
        create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "TiedToExcludedJudge", snamel: "NoAppealAffinity").ssn}S", judge: excluded_judge, attorney: attorney, appeal_affinity: false)
    end

    def create_cases_for_aoj_affinity_days_lever_ineligible_judge
      # ineligible judge cases:
        # no hearing held but has previous decision
        create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "AffinityToIneligibleUser", snamel: "60DaysAffinity").ssn}S", judge: ineligible_judge, attorney: attorney, tied_to: false)
        create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "AffinityToIneligibleUser", snamel: "25DaysAffinity").ssn}S", judge: ineligible_judge, attorney: attorney,
                                      tied_to: false, affinity_start_date: 25.days.ago)
        create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "AffinityToIneligibleUser", snamel: "3DaysAffinity").ssn}S", judge: ineligible_judge, attorney: attorney,
                                      tied_to: false, affinity_start_date: 3.days.ago)
        create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "AffinityToIneligibleUser", snamel: "NoAppealAffinity").ssn}S", judge: ineligible_judge, attorney: attorney,
                                      tied_to: false, appeal_affinity: false)
        # hearing held with previous decision where judge is not the same
        ca14 = create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "AffinityToIneligibleUser", snamel: "60DaysAffinity").ssn}S", judge: other_judge, attorney: attorney)
        VACOLS::Case.where(bfcorlid: ca14.bfcorlid, bfac: "1").update(bfmemid: ineligible_judge.sattyid)

        cb11 = create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "AffinityToIneligibleUser", snamel: "25DaysAffinity").ssn}S", judge: other_judge, attorney: attorney,
                                            affinity_start_date: 25.days.ago)
        VACOLS::Case.where(bfcorlid: cb11.bfcorlid, bfac: "1").update(bfmemid: ineligible_judge.sattyid)

        ca15 = create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "AffinityToIneligibleUser", snamel: "3DaysAffinity").ssn}S", judge: other_judge, attorney: attorney,
                                            affinity_start_date: 3.days.ago)
        VACOLS::Case.where(bfcorlid: ca15.bfcorlid, bfac: "1").update(bfmemid: ineligible_judge.sattyid)

        ca16 = create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "AffinityToIneligibleUser", snamel: "NoAppealAffinity").ssn}S", judge: other_judge, attorney: attorney, appeal_affinity: false)
        VACOLS::Case.where(bfcorlid: ca16.bfcorlid, bfac: "1").update(bfmemid: ineligible_judge.sattyid)

        cb12 = create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "AffinityToBVAGSPORER", snamel: "25DaysAffinity").ssn}S", judge: ineligible_judge, attorney: attorney,
                                            affinity_start_date: 25.days.ago)
        VACOLS::Case.where(bfcorlid: cb12.bfcorlid, bfac: "1").update(bfmemid: affinity_judge.sattyid)

        cb13 = create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "AffinityToBVAEEMARD", snamel: "25DaysAffinity").ssn}S", judge: ineligible_judge, attorney: attorney,
                                            affinity_start_date: 25.days.ago)
        VACOLS::Case.where(bfcorlid: cb13.bfcorlid, bfac: "1").update(bfmemid: affinity_and_tied_to_judge.sattyid)

        cb14 = create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "AffinityToBVABDANIEL", snamel: "25DaysAffinity").ssn}S", judge: ineligible_judge, attorney: attorney,
                                            affinity_start_date: 25.days.ago)
        VACOLS::Case.where(bfcorlid: cb14.bfcorlid, bfac: "1").update(bfmemid: tied_to_judge.sattyid)

        cb15 = create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "AffinityToBVAGSPORER", snamel: "3DaysAffinity").ssn}S", judge: ineligible_judge, attorney: attorney,
                                            affinity_start_date: 3.days.ago)
        VACOLS::Case.where(bfcorlid: cb15.bfcorlid, bfac: "1").update(bfmemid: affinity_judge.sattyid)

        cb16 = create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "AffinityToBVAEEMARD", snamel: "3DaysAffinity").ssn}S", judge: ineligible_judge, attorney: attorney,
                                            affinity_start_date: 3.days.ago)
        VACOLS::Case.where(bfcorlid: cb16.bfcorlid, bfac: "1").update(bfmemid: affinity_and_tied_to_judge.sattyid)

        cb17 = create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "AffinityToBVABDANIEL", snamel: "3DaysAffinity").ssn}S", judge: ineligible_judge, attorney: attorney,
                                            affinity_start_date: 3.days.ago)
        VACOLS::Case.where(bfcorlid: cb17.bfcorlid, bfac: "1").update(bfmemid: tied_to_judge.sattyid)

        # hearing held with previous decision where judge is same (THIS IS TIED TO)
        create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "TiedToIneligibleJudge", snamel: "60DaysAffinity").ssn}S", judge: ineligible_judge, attorney: attorney)
        create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "TiedToIneligibleJudge", snamel: "25DaysAffinity").ssn}S", judge: ineligible_judge, attorney: attorney,  affinity_start_date: 25.days.ago)
        create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "TiedToIneligibleJudge", snamel: "3DaysAffinity").ssn}S", judge: ineligible_judge, attorney: attorney,  affinity_start_date: 3.days.ago)
        create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "TiedToIneligibleJudge", snamel: "NoAppealAffinity").ssn}S", judge: ineligible_judge, attorney: attorney,  appeal_affinity: false)
        # hearing held but no previous deciding judge
        ca17 = create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "Genpop60Days", snamel: "AffinityStartDate").ssn}S", judge: ineligible_judge, attorney: attorney)
        VACOLS::Case.where(bfcorlid: ca17.bfcorlid, bfac: "1").update(bfmemid: nil)
    end

    def create_cases_for_aoj_with_hearing_after_decision
      ch1 = create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "TiedToBVAGSPORER", snamel: "60DaysAffinityAfterDec").ssn}S", judge: affinity_judge, attorney: attorney, hearing_after_decision: true)
      VACOLS::Case.where(bfcorlid: ch1.bfcorlid, bfac: "1").update(bfmemid: nil)

      ch2 = create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "TiedToBVAEEMARD", snamel: "60DaysAffinityAfterDec").ssn}S", judge: affinity_and_tied_to_judge, attorney: attorney, hearing_after_decision: true)
      VACOLS::Case.where(bfcorlid: ch2.bfcorlid, bfac: "1").update(bfmemid: nil)

      ch3 = create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "TiedToBVABDANIEL", snamel: "60DaysAffinityAfterDec").ssn}S", judge: tied_to_judge, attorney: attorney, hearing_after_decision: true)
      VACOLS::Case.where(bfcorlid: ch3.bfcorlid, bfac: "1").update(bfmemid: nil)

      ch4 = create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "TiedToBVAGSPORER", snamel: "3DaysAffinityAfterDec").ssn}S", judge: affinity_judge, attorney: attorney, affinity_start_date: 3.days.ago, hearing_after_decision: true)
      VACOLS::Case.where(bfcorlid: ch4.bfcorlid, bfac: "1").update(bfmemid: nil)

      ch5 = create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "TiedToBVAEEMARD", snamel: "3DaysAffinityAfterDec").ssn}S", judge: affinity_and_tied_to_judge, attorney: attorney, affinity_start_date: 3.days.ago, hearing_after_decision: true)
      VACOLS::Case.where(bfcorlid: ch5.bfcorlid, bfac: "1").update(bfmemid: nil)

      ch6 = create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "TiedToBVABDANIEL", snamel: "3DaysAffinityAfterDec").ssn}S", judge: tied_to_judge, attorney: attorney, affinity_start_date: 3.days.ago, hearing_after_decision: true)
      VACOLS::Case.where(bfcorlid: ch6.bfcorlid, bfac: "1").update(bfmemid: nil)

      ch7 = create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "TiedToBVAEEMARD", snamel: "60DaysAffinityAfterDec").ssn}S", judge: affinity_and_tied_to_judge, attorney: attorney, hearing_after_decision: true)
      VACOLS::Case.where(bfcorlid: ch7.bfcorlid, bfac: "1").update(bfmemid: affinity_judge.sattyid)

      ch8 = create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "TiedToBVABDANIEL", snamel: "60DaysAffinityAfterDec").ssn}S", judge: tied_to_judge, attorney: attorney, hearing_after_decision: true)
      VACOLS::Case.where(bfcorlid: ch8.bfcorlid, bfac: "1").update(bfmemid: affinity_and_tied_to_judge.sattyid)

      ch9 = create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "TiedToBVAGSPORER", snamel: "60DaysAffinityAfterDec").ssn}S", judge: affinity_judge, attorney: attorney, hearing_after_decision: true)
      VACOLS::Case.where(bfcorlid: ch9.bfcorlid, bfac: "1").update(bfmemid: tied_to_judge.sattyid)

      ch10 = create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "TiedToExcludedJudge", snamel: "60DaysAffinityAfterDec").ssn}S", judge: excluded_judge, attorney: attorney, hearing_after_decision: true)
      VACOLS::Case.where(bfcorlid: ch10.bfcorlid, bfac: "1").update(bfmemid: affinity_judge.sattyid)

      ch11 = create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "TiedToExcludedJudge", snamel: "60DaysAffinityAfterDec").ssn}S", judge: excluded_judge, attorney: attorney, hearing_after_decision: true)
      VACOLS::Case.where(bfcorlid: ch11.bfcorlid, bfac: "1").update(bfmemid: affinity_and_tied_to_judge.sattyid)

      ch12 = create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "TiedToExcludedJudge", snamel: "60DaysAffinityAfterDec").ssn}S", judge: excluded_judge, attorney: attorney, hearing_after_decision: true)
      VACOLS::Case.where(bfcorlid: ch12.bfcorlid, bfac: "1").update(bfmemid: tied_to_judge.sattyid)
      ch13 = create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "AffinityToBVAGSPORER", snamel: "3DaysAffinityAfterDec").ssn}S", judge: ineligible_judge, attorney: attorney, affinity_start_date: 3.days.ago, hearing_after_decision: true)
      VACOLS::Case.where(bfcorlid: ch13.bfcorlid, bfac: "1").update(bfmemid: affinity_judge.sattyid)

      ch14 = create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "AffinityToBVAEEMARD", snamel: "3DaysAffinityAfterDec").ssn}S", judge: ineligible_judge, attorney: attorney, affinity_start_date: 3.days.ago, hearing_after_decision: true)
      VACOLS::Case.where(bfcorlid: ch14.bfcorlid, bfac: "1").update(bfmemid: affinity_and_tied_to_judge.sattyid)

      ch15 = create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent(snamef: "AffinityToBVABDANIEL", snamel: "3DaysAffinityAfterDec").ssn}S", judge: ineligible_judge, attorney: attorney, affinity_start_date: 3.days.ago, hearing_after_decision: true)
      VACOLS::Case.where(bfcorlid: ch15.bfcorlid, bfac: "1").update(bfmemid: tied_to_judge.sattyid)

      create(:legacy_cavc_appeal, bfcorlid: "#{create_correspondent(snamef: "Genpop90Days", snamel: "AffinityStartDate").ssn}S",  judge: affinity_judge, attorney: attorney,
                                tied_to: false, affinity_start_date: 90.days.ago)
      create(:legacy_cavc_appeal, bfcorlid: "#{create_correspondent(snamef: "Genpop60Days", snamel: "AffinityStartDate").ssn}S",  judge: affinity_judge, attorney: attorney,
                                tied_to: false, affinity_start_date: 60.days.ago)
      create(:legacy_cavc_appeal, bfcorlid: "#{create_correspondent(snamef: "Genpop25Days", snamel: "AffinityStartDate").ssn}S",  judge: affinity_judge, attorney: attorney,
                                tied_to: false, affinity_start_date: 25.days.ago)
      create(:legacy_cavc_appeal, bfcorlid: "#{create_correspondent(snamef: "Genpop3Days", snamel: "AffinityStartDate").ssn}S",  judge: affinity_judge, attorney: attorney,
                                tied_to: false, affinity_start_date: 3.days.ago)
    end
  end
end
