# frozen_string_literal: true

module Seeds
  class AojRemandReturnLegacyAppeals < Base
    def initialize
      RequestStore[:current_user] = User.system_user
      initialize_ssn
    end

    def seed!
      create_aoj_cavc_affinity_cases
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
        snamef: Faker::Name.first_name,
        snamemi: Faker::Name.initials(number: 1),
        snamel: Faker::Name.last_name,
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
      @excluded_judge ||= find_or_create_active_excluded_judge("EXCLUDED_JUDGE", "Excluded FromAffinity Judge")
    end

    def ineligible_judge
      @ineligible_judge ||= find_or_create_ineligible_judge("INELIGIBLE_JUDGE", "Ineligible Vacols Judge")
    end

    def attorney
      @attorney ||= find_or_create_attorney("AFFINITY_ATTORNEY", "Affinity Cases Attorney")
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
        create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent.ssn}S",  judge: affinity_judge, attorney: attorney, tied_to: false, cavc: true)
        create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent.ssn}S",  judge: affinity_judge, attorney: attorney,
                                    tied_to: false, affinity_start_date: 3.days.ago, cavc: true)
        create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent.ssn}S",  judge: affinity_judge, attorney: attorney,
                                    tied_to: false, appeal_affinity: false, cavc: true)
        create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent.ssn}S",  judge: affinity_and_tied_to_judge, attorney: attorney, tied_to: false, cavc: true)
        create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent.ssn}S",  judge: affinity_and_tied_to_judge, attorney: attorney,
                                    tied_to: false, affinity_start_date: 3.days.ago, cavc: true)
        create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent.ssn}S",  judge: affinity_and_tied_to_judge, attorney: attorney,
                                    tied_to: false, appeal_affinity: false, cavc: true)
        # hearing held with previous decision where judge is not the same
        a1 = create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent.ssn}S", judge: other_judge, attorney: attorney, cavc: true)
        VACOLS::Case.where(bfcorlid: a1.bfcorlid, bfac: "7").update(bfmemid: affinity_judge.sattyid)

        a2 = create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent.ssn}S", judge: other_judge, attorney: attorney,
                                          affinity_start_date: 3.days.ago, cavc: true)
        VACOLS::Case.where(bfcorlid: a2.bfcorlid, bfac: "7").update(bfmemid: affinity_judge.sattyid)

        a3 = create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent.ssn}S", judge: other_judge, attorney: attorney, appeal_affinity: false, cavc: true)
        VACOLS::Case.where(bfcorlid: a3.bfcorlid, bfac: "7").update(bfmemid: affinity_judge.sattyid)

        a4 = create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent.ssn}S", judge: other_judge, attorney: attorney, cavc: true)
        VACOLS::Case.where(bfcorlid: a4.bfcorlid, bfac: "7").update(bfmemid: affinity_and_tied_to_judge.sattyid)

        a5 = create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent.ssn}S", judge: other_judge, attorney: attorney,
                                          affinity_start_date: 3.days.ago, cavc: true)
        VACOLS::Case.where(bfcorlid: a5.bfcorlid, bfac: "7").update(bfmemid: affinity_and_tied_to_judge.sattyid)

        a6 = create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent.ssn}S", judge: other_judge, attorney: attorney, appeal_affinity: false, cavc: true)
        VACOLS::Case.where(bfcorlid: a6.bfcorlid, bfac: "7").update(bfmemid: affinity_and_tied_to_judge.sattyid)

        # hearing held with previous decision where judge is same (THIS IS TIED TO)
        create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent.ssn}S", judge: tied_to_judge, attorney: attorney, cavc: true)
        create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent.ssn}S", judge: tied_to_judge, attorney: attorney, affinity_start_date: 3.days.ago, cavc: true)
        create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent.ssn}S", judge: tied_to_judge, attorney: attorney, appeal_affinity: false, cavc: true)
        create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent.ssn}S", judge: affinity_and_tied_to_judge, attorney: attorney, cavc: true)
        create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent.ssn}S", judge: affinity_and_tied_to_judge, attorney: attorney, affinity_start_date: 3.days.ago, cavc: true)
        create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent.ssn}S", judge: affinity_and_tied_to_judge, attorney: attorney, appeal_affinity: false, cavc: true)

        # hearing held but no previous deciding judge
        a7 = create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent.ssn}S", judge: tied_to_judge, attorney: attorney, cavc: true)
        VACOLS::Case.where(bfcorlid: a7.bfcorlid, bfac: "7").update(bfmemid: nil)
        a8 = create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent.ssn}S", judge: affinity_and_tied_to_judge, attorney: attorney, cavc: true)
        VACOLS::Case.where(bfcorlid: a8.bfcorlid, bfac: "7").update(bfmemid: nil)

        # no hearing held, no previous deciding judge
        a9 = create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent.ssn}S", judge: affinity_judge, attorney: attorney,
                                          tied_to: false, cavc: true)
        VACOLS::Case.where(bfcorlid: a9.bfcorlid, bfac: "7").update(bfmemid: nil)
        a10 = create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent.ssn}S", judge: affinity_and_tied_to_judge, attorney: attorney,
                                          tied_to: false, cavc: true)
        VACOLS::Case.where(bfcorlid: a10.bfcorlid, bfac: "7").update(bfmemid: nil)
    end

    def create_cases_for_aoj_cavc_affinity_days_lever_excluded_judge
      # excluded judge cases:
        # no hearing held but has previous decision
        create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent.ssn}S", judge: excluded_judge, attorney: attorney, tied_to: false, cavc: true)
        create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent.ssn}S", judge: excluded_judge, attorney: attorney,
                                      tied_to: false, affinity_start_date: 3.days.ago, cavc: true)
        create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent.ssn}S", judge: excluded_judge, attorney: attorney,
                                      tied_to: false, appeal_affinity: false, cavc: true)
        # hearing held with previous decision where judge is not the same
        a11 = create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent.ssn}S", judge: other_judge, attorney: attorney, cavc: true)
        VACOLS::Case.where(bfcorlid: a11.bfcorlid, bfac: "7").update(bfmemid: excluded_judge.sattyid)

        a12 = create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent.ssn}S", judge: other_judge, attorney: attorney,
                                      affinity_start_date: 3.days.ago, cavc: true)
        VACOLS::Case.where(bfcorlid: a12.bfcorlid, bfac: "7").update(bfmemid: excluded_judge.sattyid)

        a13 = create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent.ssn}S", judge: other_judge, attorney: attorney, appeal_affinity: false, cavc: true)
        VACOLS::Case.where(bfcorlid: a13.bfcorlid, bfac: "7").update(bfmemid: excluded_judge.sattyid)

        # hearing held with previous decision where judge is same (THIS IS TIED TO)
        create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent.ssn}S", judge: excluded_judge, attorney: attorney, cavc: true)
        create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent.ssn}S", judge: excluded_judge, attorney: attorney, affinity_start_date: 3.days.ago, cavc: true)
        create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent.ssn}S", judge: excluded_judge, attorney: attorney, appeal_affinity: false, cavc: true)
    end

    def create_cases_for_aoj_cavc_affinity_days_lever_ineligible_judge
      # ineligible judge cases:
        # no hearing held but has previous decision
        create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent.ssn}S", judge: ineligible_judge, attorney: attorney, tied_to: false, cavc: true)
        create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent.ssn}S", judge: ineligible_judge, attorney: attorney,
                                      tied_to: false, affinity_start_date: 3.days.ago, cavc: true)
        create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent.ssn}S", judge: ineligible_judge, attorney: attorney,
                                      tied_to: false, appeal_affinity: false, cavc: true)
        # hearing held with previous decision where judge is not the same
        a14 = create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent.ssn}S", judge: other_judge, attorney: attorney, cavc: true)
        VACOLS::Case.where(bfcorlid: a14.bfcorlid, bfac: "7").update(bfmemid: ineligible_judge.sattyid)
        a15 = create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent.ssn}S", judge: other_judge, attorney: attorney,
                                            affinity_start_date: 3.days.ago, cavc: true)
        VACOLS::Case.where(bfcorlid: a15.bfcorlid, bfac: "7").update(bfmemid: ineligible_judge.sattyid)
        a16 = create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent.ssn}S", judge: other_judge, attorney: attorney, appeal_affinity: false, cavc: true)
        VACOLS::Case.where(bfcorlid: a16.bfcorlid, bfac: "7").update(bfmemid: ineligible_judge.sattyid)
        # hearing held with previous decision where judge is same (THIS IS TIED TO)
        create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent.ssn}S", judge: ineligible_judge, attorney: attorney, cavc: true)
        create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent.ssn}S", judge: ineligible_judge, attorney: attorney,  affinity_start_date: 3.days.ago, cavc: true)
        create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent.ssn}S", judge: ineligible_judge, attorney: attorney,  appeal_affinity: false, cavc: true)
        # hearing held but no previous deciding judge
        a17 = create(:legacy_aoj_appeal, bfcorlid: "#{create_correspondent.ssn}S", judge: ineligible_judge, attorney: attorney, cavc: true)
        VACOLS::Case.where(bfcorlid: a17.bfcorlid, bfac: "7").update(bfmemid: nil)
    end
  end
end
