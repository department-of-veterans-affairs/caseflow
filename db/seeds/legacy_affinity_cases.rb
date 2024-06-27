# frozen_string_literal: true

# This seed creates ~100 appeals which have an affinity to a judge based case distribution algorithm levers,
# and ~100 appeals which are similar but fall just outside of the affinity day levers and will be distributed
# to any judge. Used primarily in testing APPEALS-36998 and other ACD feature work
module Seeds
  class LegacyAffinityCases < Base
    def initialize
      RequestStore[:current_user] = User.system_user
      initial_file_number_and_participant_id
    end

    def seed!
      create_cavc_affinity_cases
      create_cavc_aod_affinity_cases
    end

    private

    def initial_file_number_and_participant_id
      @file_number ||= 520_000_000
      @participant_id ||= 920_000_000
      @tied_to_file_number ||= 550_000_000
      @tied_to_participant_id ||= 950_000_000
      # n is (@file_number + 1) because @file_number is incremented before using it in factories in calling methods
      while Veteran.find_by(file_number: format("%<n>09d", n: @file_number + 1))
        @file_number += 1000
        @participant_id += 1000
      end

      while Veteran.find_by(file_number: format("%<n>09d", n: @tied_to_file_number + 1))
        @tied_to_file_number += 1000
        @tied_to_participant_id += 1000
      end
    end

    def create_veteran_for_tied_to
      @tied_to_file_number += 1
      @tied_to_participant_id += 1

      Veteran.find_by_participant_id(@tied_to_participant_id) || create(
        :veteran,
        file_number: format("%<n>09d", n: @tied_to_file_number),
        participant_id: format("%<n>09d", n: @tied_to_participant_id)
      )
    end

    def create_veteran
      @file_number += 1
      @participant_id += 1

      Veteran.find_by_participant_id(@participant_id) || create(
        :veteran,
        file_number: format("%<n>09d", n: @file_number),
        participant_id: format("%<n>09d", n: @participant_id)
      )
    end

    def create_cavc_affinity_cases
      create_cases_for_cavc_affinty_days_lever
      create_cases_for_cavc_affinty_days_lever_excluded_judge
      create_cases_for_cavc_affinity_days_lever_ineligible_judge
    end

    def create_cavc_aod_affinity_cases
      create_cases_for_cavc_aod_affinty_days_lever
      create_cases_for_cavc_aod_affinty_days_lever_excluded_judge
      create_cases_for_cavc_aod_affinity_days_lever_ineligible_judge
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

    def create_cases_for_cavc_affinty_days_lever
      # cavc affinity cases:
        # no hearing held but has previous decision
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran.file_number}S",  judge: affinity_judge, attorney: attorney, tied_to: false)
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran.file_number}S",  judge: affinity_judge, attorney: attorney,
                                    tied_to: false, affinity_start_date: 3.days.ago)
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran.file_number}S",  judge: affinity_judge, attorney: attorney,
                                    tied_to: false, appeal_affinity: false)
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran.file_number}S",  judge: affinity_and_tied_to_judge, attorney: attorney, tied_to: false)
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran.file_number}S",  judge: affinity_and_tied_to_judge, attorney: attorney,
                                    tied_to: false, affinity_start_date: 3.days.ago)
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran.file_number}S",  judge: affinity_and_tied_to_judge, attorney: attorney,
                                    tied_to: false, appeal_affinity: false)
        # hearing held with previous decision where judge is not the same
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran.file_number}S", judge: other_judge, attorney: attorney)
        .update!(bfmemid: affinity_judge.sattyid)

        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran.file_number}S", judge: other_judge, attorney: attorney,
                                          affinity_start_date: 3.days.ago)
                                          .update!(bfmemid: affinity_judge.sattyid)

        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran.file_number}S", judge: other_judge, attorney: attorney, appeal_affinity: false)
        .update!(bfmemid: affinity_judge.sattyid)

        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran.file_number}S", judge: other_judge, attorney: attorney)
        .update!(bfmemid: affinity_and_tied_to_judge.sattyid)

        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran.file_number}S", judge: other_judge, attorney: attorney,
                                          affinity_start_date: 3.days.ago)
                                          .update!(bfmemid: affinity_and_tied_to_judge.sattyid)

        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran.file_number}S", judge: other_judge, attorney: attorney, appeal_affinity: false)
        .update!(bfmemid: affinity_and_tied_to_judge.sattyid)

        # hearing held with previous decision where judge is same (THIS IS TIED TO)
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran_for_tied_to.file_number}S", judge: tied_to_judge, attorney: attorney)
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran_for_tied_to.file_number}S", judge: tied_to_judge, attorney: attorney, affinity_start_date: 3.days.ago)
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran_for_tied_to.file_number}S", judge: tied_to_judge, attorney: attorney, appeal_affinity: false)
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran_for_tied_to.file_number}S", judge: affinity_and_tied_to_judge, attorney: attorney)
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran_for_tied_to.file_number}S", judge: affinity_and_tied_to_judge, attorney: attorney, affinity_start_date: 3.days.ago)
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran_for_tied_to.file_number}S", judge: affinity_and_tied_to_judge, attorney: attorney, appeal_affinity: false)

        # hearing held but no previous deciding judge
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran.file_number}S", judge: tied_to_judge, attorney: attorney)
        .update!(bfmemid: nil)
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran.file_number}S", judge: affinity_and_tied_to_judge, attorney: attorney)
        .update!(bfmemid: nil)

        # no hearing held, no previous deciding judge
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran.file_number}S", judge: affinity_judge, attorney: attorney,
                                          tied_to: false).update!(bfmemid: nil)
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran.file_number}S", judge: affinity_and_tied_to_judge, attorney: attorney,
                                          tied_to: false).update!(bfmemid: nil)
    end

    def create_cases_for_cavc_affinty_days_lever_excluded_judge
      # excluded judge cases:
        # no hearing held but has previous decision
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran.file_number}S", judge: excluded_judge, attorney: attorney, tied_to: false)
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran.file_number}S", judge: excluded_judge, attorney: attorney,
                                      tied_to: false, affinity_start_date: 3.days.ago)
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran.file_number}S", judge: excluded_judge, attorney: attorney,
                                      tied_to: false, appeal_affinity: false)
        # hearing held with previous decision where judge is not the same
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran.file_number}S", judge: other_judge, attorney: attorney)
        .update!(bfmemid: excluded_judge.sattyid)

        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran.file_number}S", judge: other_judge, attorney: attorney,
                                      affinity_start_date: 3.days.ago)
                                      .update!(bfmemid: excluded_judge.sattyid)

        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran.file_number}S", judge: other_judge, attorney: attorney, appeal_affinity: false)
        .update!(bfmemid: excluded_judge.sattyid)

        # hearing held with previous decision where judge is same (THIS IS TIED TO)
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran_for_tied_to.file_number}S", judge: excluded_judge, attorney: attorney)
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran_for_tied_to.file_number}S", judge: excluded_judge, attorney: attorney, affinity_start_date: 3.days.ago)
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran_for_tied_to.file_number}S", judge: excluded_judge, attorney: attorney, appeal_affinity: false)
    end

    def create_cases_for_cavc_affinity_days_lever_ineligible_judge
      # ineligible judge cases:
        # no hearing held but has previous decision
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran.file_number}S", judge: ineligible_judge, attorney: attorney, tied_to: false)
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran.file_number}S", judge: ineligible_judge, attorney: attorney,
                                      tied_to: false, affinity_start_date: 3.days.ago)
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran.file_number}S", judge: ineligible_judge, attorney: attorney,
                                      tied_to: false, appeal_affinity: false)
        # hearing held with previous decision where judge is not the same
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran.file_number}S", judge: other_judge, attorney: attorney)
          .update!(bfmemid: ineligible_judge.sattyid)
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran.file_number}S", judge: other_judge, attorney: attorney,
                                            affinity_start_date: 3.days.ago)
                                            .update!(bfmemid: ineligible_judge.sattyid)
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran.file_number}S", judge: other_judge, attorney: attorney, appeal_affinity: false)
        .update!(bfmemid: ineligible_judge.sattyid)
        # hearing held with previous decision where judge is same (THIS IS TIED TO)
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran_for_tied_to.file_number}S", judge: ineligible_judge, attorney: attorney)
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran_for_tied_to.file_number}S", judge: ineligible_judge, attorney: attorney,  affinity_start_date: 3.days.ago)
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran_for_tied_to.file_number}S", judge: ineligible_judge, attorney: attorney,  appeal_affinity: false)
        # hearing held but no previous deciding judge
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran_for_tied_to.file_number}S", judge: ineligible_judge, attorney: attorney).update!(bfmemid: nil)
    end

    def create_cases_for_cavc_aod_affinty_days_lever
      # cavc aod affinity cases:
        # no hearing held but has previous decision
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran.file_number}S", judge: affinity_judge, attorney: attorney, aod: true, tied_to: false)
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran.file_number}S", judge: affinity_judge, attorney: attorney, aod: true, tied_to: false, affinity_start_date: 3.days.ago)
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran.file_number}S", judge: affinity_judge, attorney: attorney, aod: true, tied_to: false, appeal_affinity: false)
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran.file_number}S", judge: affinity_and_tied_to_judge, attorney: attorney, aod: true, tied_to: false)
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran.file_number}S", judge: affinity_and_tied_to_judge, attorney: attorney, aod: true, tied_to: false, affinity_start_date: 3.days.ago)
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran.file_number}S", judge: affinity_and_tied_to_judge, attorney: attorney, aod: true, tied_to: false, appeal_affinity: false)
        # hearing held with previous decision where judge is not the same
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran.file_number}S", judge: other_judge, attorney: attorney, aod: true).update!(bfmemid: affinity_judge.sattyid)
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran.file_number}S", judge: other_judge, attorney: attorney, aod: true, affinity_start_date: 3.days.ago)
          .update!(bfmemid: affinity_judge.sattyid)
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran.file_number}S", judge: other_judge, attorney: attorney, aod: true, appeal_affinity: false)
          .update!(bfmemid: affinity_judge.sattyid)
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran.file_number}S", judge: other_judge, attorney: attorney, aod: true).update!(bfmemid: affinity_and_tied_to_judge.sattyid)
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran.file_number}S", judge: other_judge, attorney: attorney, aod: true, affinity_start_date: 3.days.ago)
          .update!(bfmemid: affinity_and_tied_to_judge.sattyid)
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran.file_number}S", judge: other_judge, attorney: attorney, aod: true, appeal_affinity: false)
          .update!(bfmemid: affinity_and_tied_to_judge.sattyid)

        # hearing held with previous decision where judge is same (THIS IS TIED TO)
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran_for_tied_to.file_number}S", judge: tied_to_judge, attorney: attorney, aod: true)
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran_for_tied_to.file_number}S", judge: tied_to_judge, attorney: attorney, aod: true, affinity_start_date: 3.days.ago)
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran_for_tied_to.file_number}S", judge: tied_to_judge, attorney: attorney, aod: true, appeal_affinity: false)
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran_for_tied_to.file_number}S", judge: affinity_and_tied_to_judge, attorney: attorney, aod: true)
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran_for_tied_to.file_number}S", judge: affinity_and_tied_to_judge, attorney: attorney, aod: true, affinity_start_date: 3.days.ago)
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran_for_tied_to.file_number}S", judge: affinity_and_tied_to_judge, attorney: attorney, aod: true, appeal_affinity: false)
        # hearing held but no previous deciding judge
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran.file_number}S", judge: tied_to_judge, attorney: attorney, aod: true)
        .update!(bfmemid: nil)
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran.file_number}S", judge: affinity_and_tied_to_judge, attorney: attorney, aod: true)
        .update!(bfmemid: nil)
        # no hearing held, no previous deciding judge
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran.file_number}S", judge: affinity_judge, attorney: attorney, aod: true, tied_to: false)
          .update!(bfmemid: nil)
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran.file_number}S", judge: affinity_and_tied_to_judge, attorney: attorney, aod: true, tied_to: false)
          .update!(bfmemid: nil)
    end

    def create_cases_for_cavc_aod_affinty_days_lever_excluded_judge
      # excluded judge cases:
        # no hearing held but has previous decision
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran.file_number}S", judge: excluded_judge, attorney: attorney, aod: true, tied_to: false)
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran.file_number}S", judge: excluded_judge, attorney: attorney, aod: true, tied_to: false, affinity_start_date: 3.days.ago)
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran.file_number}S", judge: excluded_judge, attorney: attorney, aod: true, tied_to: false, appeal_affinity: false)
        # hearing held with previous decision where judge is not the same
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran.file_number}S", judge: other_judge, attorney: attorney, aod: true)
          .update!(bfmemid: excluded_judge.sattyid)

        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran.file_number}S", judge: other_judge, attorney: attorney, aod: true, affinity_start_date: 3.days.ago).update!(bfmemid: excluded_judge.sattyid)
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran.file_number}S", judge: other_judge, attorney: attorney, aod: true, appeal_affinity: false)
          .update!(bfmemid: excluded_judge.sattyid)
        # hearing held with previous decision where judge is same (THIS IS TIED TO)
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran_for_tied_to.file_number}S", judge: excluded_judge, attorney: attorney, aod: true)
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran_for_tied_to.file_number}S", judge: excluded_judge, attorney: attorney, aod: true, affinity_start_date: 3.days.ago)
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran_for_tied_to.file_number}S", judge: excluded_judge, attorney: attorney, aod: true, appeal_affinity: false)
    end

    def create_cases_for_cavc_aod_affinity_days_lever_ineligible_judge
      # ineligible judge cases:
        # no hearing held but has previous decision
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran.file_number}S", judge: ineligible_judge, attorney: attorney, aod: true, tied_to: false)
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran.file_number}S", judge: ineligible_judge, attorney: attorney, aod: true, tied_to: false, affinity_start_date: 3.days.ago)
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran.file_number}S", judge: ineligible_judge, attorney: attorney, aod: true, tied_to: false, appeal_affinity: false)
        # hearing held with previous decision where judge is not the same
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran.file_number}S", judge: other_judge, attorney: attorney, aod: true)
          .update!(bfmemid: ineligible_judge.sattyid)
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran.file_number}S", judge: other_judge, attorney: attorney, aod: true, affinity_start_date: 3.days.ago)
          .update!(bfmemid: ineligible_judge.sattyid)
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran.file_number}S", judge: other_judge, attorney: attorney, aod: true, appeal_affinity: false)
          .update!(bfmemid: ineligible_judge.sattyid)
        # hearing held with previous decision where judge is same (THIS IS TIED TO)
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran_for_tied_to.file_number}S", judge: ineligible_judge, attorney: attorney, aod: true)
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran_for_tied_to.file_number}S", judge: ineligible_judge, attorney: attorney, aod: true, affinity_start_date: 3.days.ago)
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran_for_tied_to.file_number}S", judge: ineligible_judge, attorney: attorney, aod: true, appeal_affinity: false)
        # hearing held but no previous deciding judge
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran.file_number}S", judge: ineligible_judge, attorney: attorney, aod: true)
          .update!(bfmemid: nil)
    end

  end
end
