# frozen_string_literal: true

module Seeds
  class AojRemandReturnLegacyAppeals < Base
    def initialize
      RequestStore[:current_user] = User.system_user
      initialize_ssn
    end

    def seed!
      create_aoj_aod_affinity_cases
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

    def create_aoj_aod_affinity_cases
      create_cases_for_aoj_aod_affinty_days_lever
      create_cases_for_aoj_aod_affinty_days_lever_excluded_judge
      create_cases_for_aoj_aod_affinity_days_lever_ineligible_judge
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

    def create_cases_for_aoj_aod_affinty_days_lever
      # aoj aod affinity cases:
        # no hearing held but has previous decision
       
        create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent.ssn}S", judge: affinity_judge, attorney: attorney, tied_to: false)
        create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent.ssn}S", judge: affinity_judge, attorney: attorney, tied_to: false, affinity_start_date: 3.days.ago)
        create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent.ssn}S", judge: affinity_judge, attorney: attorney, tied_to: false, appeal_affinity: false)
        create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent.ssn}S", judge: affinity_and_tied_to_judge, attorney: attorney, tied_to: false)
        create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent.ssn}S", judge: affinity_and_tied_to_judge, attorney: attorney, tied_to: false, affinity_start_date: 3.days.ago)
        create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent.ssn}S", judge: affinity_and_tied_to_judge, attorney: attorney, tied_to: false, appeal_affinity: false)
        # hearing held with previous decision where judge is not the same
        ca1 = create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent.ssn}S", judge: other_judge, attorney: attorney)
        VACOLS::Case.where(bfcorlid: ca1.bfcorlid, bfac: "1").update(bfmemid: affinity_judge.sattyid)

        ca2 = create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent.ssn}S", judge: other_judge, attorney: attorney, affinity_start_date: 3.days.ago)
        VACOLS::Case.where(bfcorlid: ca2.bfcorlid, bfac: "1").update(bfmemid: affinity_judge.sattyid)

        ca3 = create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent.ssn}S", judge: other_judge, attorney: attorney, appeal_affinity: false)
        VACOLS::Case.where(bfcorlid: ca3.bfcorlid, bfac: "1").update(bfmemid: affinity_judge.sattyid)

        ca4 = create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent.ssn}S", judge: other_judge, attorney: attorney)
        VACOLS::Case.where(bfcorlid: ca4.bfcorlid, bfac: "1").update(bfmemid: affinity_judge.sattyid)

        ca5 = create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent.ssn}S", judge: other_judge, attorney: attorney, affinity_start_date: 3.days.ago)
        VACOLS::Case.where(bfcorlid: ca5.bfcorlid, bfac: "1").update(bfmemid: affinity_judge.sattyid)

        ca6 = create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent.ssn}S", judge: other_judge, attorney: attorney, appeal_affinity: false)
        VACOLS::Case.where(bfcorlid: ca6.bfcorlid, bfac: "1").update(bfmemid: affinity_judge.sattyid)

        # hearing held with previous decision where judge is same (THIS IS TIED TO)
        create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent.ssn}S", judge: tied_to_judge, attorney: attorney)
        create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent.ssn}S", judge: tied_to_judge, attorney: attorney, affinity_start_date: 3.days.ago)
        create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent.ssn}S", judge: tied_to_judge, attorney: attorney, appeal_affinity: false)
        create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent.ssn}S", judge: affinity_and_tied_to_judge, attorney: attorney)
        create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent.ssn}S", judge: affinity_and_tied_to_judge, attorney: attorney, affinity_start_date: 3.days.ago)
        create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent.ssn}S", judge: affinity_and_tied_to_judge, attorney: attorney, appeal_affinity: false)
        # hearing held but no previous deciding judge
        ca7 = create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent.ssn}S", judge: tied_to_judge, attorney: attorney)
        VACOLS::Case.where(bfcorlid: ca7.bfcorlid, bfac: "1").update(bfmemid: nil)

        ca8 = create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent.ssn}S", judge: affinity_and_tied_to_judge, attorney: attorney)
        VACOLS::Case.where(bfcorlid: ca8.bfcorlid, bfac: "1").update(bfmemid: nil)

        # no hearing held, no previous deciding judge
        ca9 = create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent.ssn}S", judge: affinity_judge, attorney: attorney, tied_to: false)
        VACOLS::Case.where(bfcorlid: ca9.bfcorlid, bfac: "1").update(bfmemid: nil)

        ca10 = create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent.ssn}S", judge: affinity_and_tied_to_judge, attorney: attorney, tied_to: false)
        VACOLS::Case.where(bfcorlid: ca10.bfcorlid, bfac: "1").update(bfmemid: nil)
    end

    def create_cases_for_aoj_aod_affinty_days_lever_excluded_judge
      # excluded judge cases:
        # no hearing held but has previous decision
        create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent.ssn}S", judge: excluded_judge, attorney: attorney, tied_to: false)
        create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent.ssn}S", judge: excluded_judge, attorney: attorney, tied_to: false, affinity_start_date: 3.days.ago)
        create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent.ssn}S", judge: excluded_judge, attorney: attorney, tied_to: false, appeal_affinity: false)
        # hearing held with previous decision where judge is not the same
        ca11 = create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent.ssn}S", judge: other_judge, attorney: attorney)
        VACOLS::Case.where(bfcorlid: ca11.bfcorlid, bfac: "1").update(bfmemid: excluded_judge.sattyid)

        ca12 = create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent.ssn}S", judge: other_judge, attorney: attorney, affinity_start_date: 3.days.ago)
        VACOLS::Case.where(bfcorlid: ca12.bfcorlid, bfac: "1").update(bfmemid: excluded_judge.sattyid)

        ca13 = create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent.ssn}S", judge: other_judge, attorney: attorney, appeal_affinity: false)
        VACOLS::Case.where(bfcorlid: ca13.bfcorlid, bfac: "1").update(bfmemid: excluded_judge.sattyid)

        # hearing held with previous decision where judge is same (THIS IS TIED TO)
        create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent.ssn}S", judge: excluded_judge, attorney: attorney)
        create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent.ssn}S", judge: excluded_judge, attorney: attorney, affinity_start_date: 3.days.ago)
        create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent.ssn}S", judge: excluded_judge, attorney: attorney, appeal_affinity: false)
    end

    def create_cases_for_aoj_aod_affinity_days_lever_ineligible_judge
      # ineligible judge cases:
        # no hearing held but has previous decision
        create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent.ssn}S", judge: ineligible_judge, attorney: attorney, tied_to: false)
        create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent.ssn}S", judge: ineligible_judge, attorney: attorney, tied_to: false, affinity_start_date: 3.days.ago)
        create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent.ssn}S", judge: ineligible_judge, attorney: attorney, tied_to: false, appeal_affinity: false)
        # hearing held with previous decision where judge is not the same
        ca14 = create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent.ssn}S", judge: other_judge, attorney: attorney)
        VACOLS::Case.where(bfcorlid: ca14.bfcorlid, bfac: "1").update(bfmemid: ineligible_judge.sattyid)

        ca15 = create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent.ssn}S", judge: other_judge, attorney: attorney, affinity_start_date: 3.days.ago)
        VACOLS::Case.where(bfcorlid: ca15.bfcorlid, bfac: "1").update(bfmemid: ineligible_judge.sattyid)

        ca16 = create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent.ssn}S", judge: other_judge, attorney: attorney, appeal_affinity: false)
        VACOLS::Case.where(bfcorlid: ca16.bfcorlid, bfac: "1").update(bfmemid: ineligible_judge.sattyid)

        # hearing held with previous decision where judge is same (THIS IS TIED TO)
        create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent.ssn}S", judge: ineligible_judge, attorney: attorney)
        create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent.ssn}S", judge: ineligible_judge, attorney: attorney, affinity_start_date: 3.days.ago)
        create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent.ssn}S", judge: ineligible_judge, attorney: attorney, appeal_affinity: false)
        # hearing held but no previous deciding judge
        ca17 = create(:legacy_aoj_appeal, :aod, bfcorlid: "#{create_correspondent.ssn}S", judge: ineligible_judge, attorney: attorney)
        VACOLS::Case.where(bfcorlid: ca17.bfcorlid, bfac: "1").update(bfmemid: ineligible_judge.sattyid)
    end
  end
end
