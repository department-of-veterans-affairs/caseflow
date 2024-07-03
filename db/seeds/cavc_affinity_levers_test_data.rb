# frozen_string_literal: true

module Seeds
  class CavcAffinityLeversTestData < Base
    APPEALS_LIMIT = 10

    def initialize
      RequestStore[:current_user] = User.system_user
      initialize_bvagsporer_file_number_and_participant_id
      initialize_bvaeemard_file_number_and_participant_id
      initialize_bvabdaniel_file_number_and_participant_id
      initialize_bvadcremin_file_number_and_participant_id
      initialize_bvaoschowalt_file_number_and_participant_id
      initialize_bvaawakefield_file_number_and_participant_id
      initialize_activejudgeteam_file_number_and_participant_id
      initialize_bvacgislason1_file_number_and_participant_id
      initialize_inactivejudge_file_number_and_participant_id
      initialize_inactivecfjudge_file_number_and_participant_id
      initialize_inactivejudge101_file_number_and_participant_id
      initialize_bvaabode_file_number_and_participant_id
      initialize_bvakkeeling_file_number_and_participant_id
      initialize_bvaaabshire_file_number_and_participant_id
      initialize_veteran_file_number_and_participant_id
    end

    def seed!
      create_cavc_affinity_days_data
      create_cavc_aod_affinity_days_data
    end

    def find_veteran(file_number)
      Veteran.find_by(file_number: format("%<n>09d", n: file_number + 1))
    end

    def initialize_bvagsporer_file_number_and_participant_id
      @bvagsporer_file_number ||= 400_000_000
      @bvagsporer_participant_id ||= 420_000_000

      while find_veteran(@bvagsporer_file_number)
        @bvagsporer_file_number += 2000
        @bvagsporer_participant_id += 2000
      end
    end

    def initialize_bvaeemard_file_number_and_participant_id
      @bvaeemard_file_number ||= 401_000_000
      @bvaeemard_participant_id ||= 421_000_000

      while find_veteran(@bvaeemard_file_number)
        @bvaeemard_file_number += 2000
        @bvaeemard_participant_id += 2000
      end
    end

    def initialize_bvabdaniel_file_number_and_participant_id
      @bvabdaniel_file_number ||= 402_000_000
      @bvabdaniel_participant_id ||= 422_000_000

      while find_veteran(@bvabdaniel_file_number)
        @bvabdaniel_file_number += 2000
        @bvabdaniel_participant_id += 2000
      end
    end

    def initialize_bvadcremin_file_number_and_participant_id
      @bvadcremin_file_number ||= 403_000_000
      @bvadcremin_participant_id ||= 423_000_000

      while find_veteran(@bvadcremin_file_number)
        @bvadcremin_file_number += 2000
        @bvadcremin_participant_id += 2000
      end
    end

    def initialize_bvaoschowalt_file_number_and_participant_id
      @bvaoschowalt_file_number ||= 404_000_000
      @bvaoschowalt_participant_id ||= 424_000_000
      while find_veteran(@bvaoschowalt_file_number)
        @bvaoschowalt_file_number += 2000
        @bvaoschowalt_participant_id += 2000
      end
    end

    def initialize_bvaawakefield_file_number_and_participant_id
      @bvaawakefield_file_number ||= 500_000_000
      @bvaawakefield_participant_id ||= 425_000_000

      while find_veteran(@bvaawakefield_file_number)
        @bvaawakefield_file_number += 2000
        @bvaawakefield_participant_id += 2000
      end
    end

    def initialize_activejudgeteam_file_number_and_participant_id
      @activejudgeteam_file_number ||= 501_000_000
      @activejudgeteam_participant_id ||= 426_000_000

      while find_veteran(@activejudgeteam_file_number)
        @activejudgeteam_file_number += 2000
        @activejudgeteam_participant_id += 2000
      end
    end

    def initialize_bvacgislason1_file_number_and_participant_id
      @bvacgislason1_file_number ||= 502_000_000
      @bvacgislason1_participant_id ||= 427_000_000

      while find_veteran(@bvacgislason1_file_number)
        @bvacgislason1_file_number += 2000
        @bvacgislason1_participant_id += 2000
      end
    end

    def initialize_inactivejudge_file_number_and_participant_id
      @inactivejudge_file_number ||= 600_000_000
      @inactivejudge_participant_id ||= 428_000_000

      while find_veteran(@inactivejudge_file_number)
        @inactivejudge_file_number += 2000
        @inactivejudge_participant_id += 2000
      end
    end

    def initialize_inactivecfjudge_file_number_and_participant_id
      @inactivecfjudge_file_number ||= 601_000_000
      @inactivecfjudge_participant_id ||= 429_000_000
      while find_veteran(@inactivecfjudge_file_number)
        @inactivecfjudge_file_number += 2000
        @inactivecfjudge_participant_id += 2000
      end
    end

    def initialize_inactivejudge101_file_number_and_participant_id
      @inactivejudge101_file_number ||= 602_000_000
      @inactivejudge101_participant_id ||= 430_000_000

      while find_veteran(@inactivejudge101_file_number)
        @inactivejudge101_file_number += 2000
        @inactivejudge101_participant_id += 2000
      end
    end

    def initialize_bvaabode_file_number_and_participant_id
      @bvaabode_file_number ||= 603_000_000
      @bvaabode_participant_id ||= 431_000_000

      while find_veteran(@bvaabode_file_number)
        @bvaabode_file_number += 2000
        @bvaabode_participant_id += 2000
      end
    end

    def initialize_bvakkeeling_file_number_and_participant_id
      @bvakkeeling_file_number ||= 604_000_000
      @bvakkeeling_participant_id ||= 432_000_000

      while find_veteran(@bvakkeeling_file_number)
        @bvakkeeling_file_number += 2000
        @bvakkeeling_participant_id += 2000
      end
    end

    def initialize_bvaaabshire_file_number_and_participant_id
      @bvaaabshire_file_number ||= 605_000_000
      @bvaaabshire_participant_id ||= 433_000_000

      while find_veteran(@bvaaabshire_file_number)
        @bvaaabshire_file_number += 2000
        @bvaaabshire_participant_id += 2000
      end
    end

    def initialize_veteran_file_number_and_participant_id
      @veteran_file_number ||= 700_000_000
      @veteran_participant_id ||= 434_000_000

      while find_veteran(@veteran_file_number)
        @veteran_file_number += 2000
        @veteran_participant_id += 2000
      end
    end

    def create_veteran(options = {})
      params = {
        file_number: format("%<n>09d", n: options[:file_number]),
        participant_id: format("%<n>09d", n: options[:participant_id])
      }

      if options[:last_name].nil?
        options[:last_name] = "Smith#{Faker::Name.last_name.downcase.tr('\'', '')}"
      end
      create(:veteran, params.merge(options))
    end

    def find_or_create_active_judge(css_id, full_name)
      User.find_by_css_id(css_id) ||
        create(:user, :judge, :with_vacols_judge_record, css_id: css_id, full_name: full_name)
    end

    def find_or_create_inactive_judge(css_id, full_name)
      User.find_by_css_id(css_id) ||
        create(:user, :judge, :with_inactive_vacols_judge_record, css_id: css_id, full_name: full_name)
    end

    def judge_bvagsporer
      @judge_bvagsporer ||= find_or_create_active_judge("BVAGSPORER", "Gilbert P Sporer")
    end

    def judge_bvaeemard
     @judge_bvaeemard ||= find_or_create_active_judge("BVAEEMARD", "Evangeline Y Emard")
    end

    def judge_bvabdaniel
     @judge_bvabdaniel ||= find_or_create_active_judge("BVABDANIEL", "Bridgette P Daniel")
    end

    def judge_bvadcremin
     @judge_bvadcremin ||= find_or_create_active_judge("BVADCREMIN", "Daija K Cremin")
    end

    def judge_bvaoschowalt
     @judge_bvaoschowalt ||= find_or_create_active_judge("BVAOSCHOWALT", "Ophelia L Schowalter")
    end

    def judge_bvaawakefield
     @judge_bvaawakefield ||=
     (judge = find_or_create_active_judge("BVAAWAKEFIELD", "Apurva Judge_CaseAtDispatch Wakefield")
     JudgeTeam.for_judge(judge).update!(exclude_appeals_from_affinity: true)
     judge)
    end

    def judge_activejudgeteam
     @judge_activejudgeteam ||=
     (judge = find_or_create_active_judge("ACTIVEJUDGETEAM", "Judge WithJudgeTeam Active")
     JudgeTeam.for_judge(judge).update!(exclude_appeals_from_affinity: true)
     judge)
    end

    def judge_bvacgislason1
     @judge_bvacgislason1 ||=
     (judge = find_or_create_active_judge("BVACGISLASON1", "Chester F Gislason")
     JudgeTeam.for_judge(judge).update!(exclude_appeals_from_affinity: true)
     judge)
    end

    def judge_inactivejudge
     @judge_inactivejudge ||=
     (judge = find_or_create_inactive_judge("INACTIVEJUDGE", "Judge InactiveInVacols User")
        vacols_record = VACOLS::Staff.find_by_sdomainid(judge.css_id)
        vacols_record.update!(sactive: "I") if vacols_record.sactive == "A"
        judge)
    end

    def judge_inactivecfjudge
     @judge_inactivecfjudge ||=
     (judge = find_or_create_inactive_judge("INACTIVECFJUDGE", "Judge InactiveInCF User")
        vacols_record = VACOLS::Staff.find_by_sdomainid(judge.css_id)
        vacols_record.update!(sactive: "I") if vacols_record.sactive == "A"
        judge)
    end

    def judge_inactivejudge101
     @judge_inactivejudge101 ||=
     (judge = find_or_create_inactive_judge("INACTIVEJUDGE101", "Judge InactiveAt101 User")
        vacols_record = VACOLS::Staff.find_by_sdomainid(judge.css_id)
        vacols_record.update!(sactive: "I") if vacols_record.sactive == "A"
        judge)
    end

    def judge_bvaabode
     @judge_bvaabode ||=
     (judge = find_or_create_inactive_judge("BVAABODE", "Anastacio H Bode")
        vacols_record = VACOLS::Staff.find_by_sdomainid(judge.css_id)
        vacols_record.update!(sactive: "I") if vacols_record.sactive == "A"
        judge)
    end

    def judge_bvakkeeling
     @judge_bvakkeeling ||=
     (judge = find_or_create_inactive_judge("BVAKKEELING", "Keith Judge_CaseToAssign_NoTeam Keeling")
        vacols_record = VACOLS::Staff.find_by_sdomainid(judge.css_id)
        vacols_record.update!(sactive: "I") if vacols_record.sactive == "A"
        judge)
    end

    def judge_bvaaabshire
     @judge_bvaaabshire ||=
     (judge = find_or_create_inactive_judge("BVAAABSHIRE", "Aaron Judge_HearingsAndCases Abshire")
        vacols_record = VACOLS::Staff.find_by_sdomainid(judge.css_id)
        vacols_record.update!(sactive: "I") if vacols_record.sactive == "A"
        judge)
    end

    def find_or_create_attorney(css_id, full_name)
      User.find_by_css_id(css_id) ||
        create(:user, :with_vacols_attorney_record, css_id: css_id, full_name: full_name)
    end

    def create_veteran_for_bvagsporer_judge(last_name = nil)
      @bvagsporer_file_number += 1
      @bvagsporer_participant_id += 1
      create_veteran(
        file_number: @bvagsporer_file_number,
        participant_id: @bvagsporer_participant_id,
        last_name: last_name
      )
    end

    def create_veteran_for_bvaeemard_judge(last_name = nil)
      @bvaeemard_file_number += 1
      @bvaeemard_participant_id += 1
      create_veteran(
        file_number: @bvaeemard_file_number,
        participant_id: @bvaeemard_participant_id,
        last_name: last_name
      )
    end

    def create_veteran_for_bvabdaniel_judge(last_name = nil)
      @bvabdaniel_file_number += 1
      @bvabdaniel_participant_id += 1
      create_veteran(
        file_number: @bvabdaniel_file_number,
        participant_id: @bvabdaniel_participant_id,
        last_name: last_name
      )
    end

    def create_veteran_for_bvadcremin_judge(last_name = nil)
      @bvadcremin_file_number += 1
      @bvadcremin_participant_id += 1
      create_veteran(
        file_number: @bvadcremin_file_number,
        participant_id: @bvadcremin_participant_id,
        last_name: last_name
      )
    end

    def create_veteran_for_bvaoschowalt_judge(last_name = nil)
      @bvaoschowalt_file_number += 1
      @bvaoschowalt_participant_id += 1
      create_veteran(
        file_number: @bvaoschowalt_file_number,
        participant_id: @bvaoschowalt_participant_id,
        last_name: last_name
      )
    end

    def create_veteran_for_bvaawakefield_judge(last_name = nil)
      @bvaawakefield_file_number += 1
      @bvaawakefield_participant_id += 1
      create_veteran(
        file_number: @bvaawakefield_file_number,
        participant_id: @bvaawakefield_participant_id,
        last_name: last_name
      )
    end

    def create_veteran_for_activejudgeteam_judge(last_name = nil)
      @activejudgeteam_file_number += 1
      @activejudgeteam_participant_id += 1
      create_veteran(
        file_number: @activejudgeteam_file_number,
        participant_id: @activejudgeteam_participant_id,
        last_name: last_name
      )
    end

    def create_veteran_for_bvacgislason1_judge(last_name = nil)
      @bvacgislason1_file_number += 1
      @bvacgislason1_participant_id += 1
      create_veteran(
        file_number: @bvacgislason1_file_number,
        participant_id: @bvacgislason1_participant_id,
        last_name: last_name
      )
    end

    def create_veteran_for_inactivejudge_judge(last_name = nil)
      @inactivejudge_file_number += 1
      @inactivejudge_participant_id += 1
      create_veteran(
        file_number: @inactivejudge_file_number,
        participant_id: @inactivejudge_participant_id,
        last_name: last_name
      )
    end

    def create_veteran_for_inactivecfjudge_judge(last_name = nil)
      @inactivecfjudge_file_number += 1
      @inactivecfjudge_participant_id += 1
      create_veteran(
        file_number: @inactivecfjudge_file_number,
        participant_id: @inactivecfjudge_participant_id,
        last_name: last_name
      )
    end

    def create_veteran_for_inactivejudge101_judge(last_name = nil)
      @inactivejudge101_file_number += 1
      @inactivejudge101_participant_id += 1
      create_veteran(
        file_number: @inactivejudge101_file_number,
        participant_id: @inactivejudge101_participant_id,
        last_name: last_name
      )
    end

    def create_veteran_for_bvaabode_judge(last_name = nil)
      @bvaabode_file_number += 1
      @bvaabode_participant_id += 1
      create_veteran(
        file_number: @bvaabode_file_number,
        participant_id: @bvaabode_participant_id,
        last_name: last_name
      )
    end

    def create_veteran_for_bvakkeeling_judge(last_name = nil)
      @bvakkeeling_file_number += 1
      @bvakkeeling_participant_id += 1
      create_veteran(
        file_number: @bvakkeeling_file_number,
        participant_id: @bvakkeeling_participant_id,
        last_name: last_name
      )
    end

    def create_veteran_for_bvaaabshire_judge(last_name = nil)
      @bvaaabshire_file_number += 1
      @bvaaabshire_participant_id += 1
      create_veteran(
        file_number: @bvaaabshire_file_number,
        participant_id: @bvaaabshire_participant_id,
        last_name: last_name
      )
    end

    def create_veteran_for_genpop(last_name = nil)
      @veteran_file_number += 1
      @veteran_participant_id += 1
      create_veteran(
        file_number: @veteran_file_number,
        participant_id: @veteran_participant_id,
        last_name: last_name
      )
    end

    def create_cavc_affinity_days_data
      create_legacy_appeals_without_hearing_held
      create_legacy_appeals_with_hearing_and_excluded_or_ineligible_judge
      create_ama_cavc_appeals_with_no_hearing_held
      create_legacy_appeals_with_null_judge_value
      create_ama_aod_appeals_with_null_judge_value
      create_ama_cavc_appeals_with_null_judge_value
    end

    def create_cavc_aod_affinity_days_data
      create_ama_cavc_appeals
      create_legacy_appeals_with_hearing_and_excluded_or_ineligible_judge
      ama_cavc_aod_appeals_with_no_hearing_held
      create_legacy_appeals_with_null_judge_value
      create_ama_aod_appeals_with_null_judge_value
      create_ama_cavc_appeals_with_null_judge_value
    end

    def create_legacy_appeals_without_hearing_held
      2.times do
        create_legacy_appeal_without_hearing_held(judge_bvagsporer, create_veteran_for_bvagsporer_judge())
      end
      create_legacy_appeal_without_hearing_held(judge_bvaeemard, create_veteran_for_bvaeemard_judge())
      create_legacy_appeal_without_hearing_held(judge_bvabdaniel, create_veteran_for_bvabdaniel_judge())
      create_legacy_appeal_without_hearing_held(judge_bvadcremin, create_veteran_for_bvadcremin_judge())
      create_legacy_appeal_without_hearing_held(judge_bvaoschowalt, create_veteran_for_bvaoschowalt_judge())
      create_legacy_appeal_without_hearing_held(judge_inactivejudge, create_veteran_for_inactivejudge_judge())
      create_legacy_appeal_without_hearing_held(judge_inactivecfjudge, create_veteran_for_inactivecfjudge_judge())
      create_legacy_appeal_without_hearing_held(judge_inactivejudge101, create_veteran_for_inactivejudge101_judge())
      create_legacy_appeal_without_hearing_held(judge_bvaabode, create_veteran_for_bvaabode_judge())
      create_legacy_appeal_without_hearing_held(judge_bvakkeeling, create_veteran_for_bvakkeeling_judge())
      create_legacy_appeal_without_hearing_held(judge_bvaaabshire, create_veteran_for_bvaaabshire_judge())
    end

    def create_legacy_appeals_with_hearing_and_excluded_or_ineligible_judge
      2.times do
        create_legacy_appeal_with_hearing_and_excluded_or_ineligible_judge(judge_bvaawakefield, create_veteran_for_bvaawakefield_judge("TiedToWakefield"))
        create_legacy_appeal_with_hearing_and_excluded_or_ineligible_judge(judge_bvacgislason1, create_veteran_for_bvacgislason1_judge("TiedToGislason"))
        create_legacy_appeal_with_hearing_and_excluded_or_ineligible_judge(judge_activejudgeteam, create_veteran_for_activejudgeteam_judge("TiedToActiveJudgeTeam"))
      end
      create_legacy_appeal_with_hearing_and_excluded_or_ineligible_judge(judge_inactivejudge, create_veteran_for_inactivejudge_judge("TiedToInactiveJudge"))
      create_legacy_appeal_with_hearing_and_excluded_or_ineligible_judge(judge_inactivecfjudge, create_veteran_for_inactivecfjudge_judge("TiedToInactiveCFJudge"))
      create_legacy_appeal_with_hearing_and_excluded_or_ineligible_judge(judge_inactivejudge101, create_veteran_for_inactivejudge101_judge("TiedToInactiveJudge101"))
      create_legacy_appeal_with_hearing_and_excluded_or_ineligible_judge(judge_bvaabode, create_veteran_for_bvaabode_judge("TiedToBode"))
      create_legacy_appeal_with_hearing_and_excluded_or_ineligible_judge(judge_bvakkeeling, create_veteran_for_bvakkeeling_judge("TiedToKeeling"))
      create_legacy_appeal_with_hearing_and_excluded_or_ineligible_judge(judge_bvaaabshire, create_veteran_for_bvaaabshire_judge("TiedToAbshire"))
    end

    def create_ama_cavc_appeals_with_no_hearing_held
      create_ama_cavc_appeal_with_no_hearing_held(judge_bvagsporer, create_veteran_for_bvagsporer_judge(),14.days.ago)
      create_ama_cavc_appeal_with_no_hearing_held(judge_bvaeemard, create_veteran_for_bvaeemard_judge(),14.days.ago)
      create_ama_cavc_appeal_with_no_hearing_held(judge_bvabdaniel, create_veteran_for_bvabdaniel_judge(),14.days.ago)
      create_ama_cavc_appeal_with_no_hearing_held(judge_bvadcremin, create_veteran_for_bvadcremin_judge(),14.days.ago)
      create_ama_cavc_appeal_with_no_hearing_held(judge_bvaoschowalt, create_veteran_for_bvaoschowalt_judge(),14.days.ago)
      create_ama_cavc_appeal_with_no_hearing_held(judge_bvaeemard, create_veteran_for_bvaeemard_judge(),14.days.ago)
      create_ama_cavc_appeal_with_no_hearing_held(judge_bvagsporer, create_veteran_for_bvagsporer_judge(),30.days.ago)
      create_ama_cavc_appeal_with_no_hearing_held(judge_bvaeemard, create_veteran_for_bvaeemard_judge(),30.days.ago)
      create_ama_cavc_appeal_with_no_hearing_held(judge_bvabdaniel, create_veteran_for_bvabdaniel_judge(),30.days.ago)
      create_ama_cavc_appeal_with_no_hearing_held(judge_bvadcremin, create_veteran_for_bvadcremin_judge(),30.days.ago)
      create_ama_cavc_appeal_with_no_hearing_held(judge_bvaoschowalt, create_veteran_for_bvaoschowalt_judge(),30.days.ago)
      create_ama_cavc_appeal_with_no_hearing_held(judge_bvabdaniel, create_veteran_for_bvabdaniel_judge(),30.days.ago)
    end

    def create_ama_cavc_appeals
      2.times do
        create_ama_cavc_appeal(judge_bvaeemard, create_veteran_for_bvaeemard_judge("TiedToEmard"))
      end
      create_ama_cavc_appeal(judge_bvagsporer, create_veteran_for_bvagsporer_judge("TiedToSporer"))
      create_ama_cavc_appeal(judge_bvabdaniel, create_veteran_for_bvabdaniel_judge("TiedToDaniel"))
      create_ama_cavc_appeal(judge_bvadcremin, create_veteran_for_bvadcremin_judge("TiedToCremin"))
      create_ama_cavc_appeal(judge_bvaoschowalt, create_veteran_for_bvaoschowalt_judge("TiedToSchowalt"))
      create_ama_cavc_appeal(judge_inactivejudge, create_veteran_for_inactivejudge_judge("TiedToInactiveJudge"))
      create_ama_cavc_appeal(judge_inactivecfjudge, create_veteran_for_inactivecfjudge_judge("TiedToInactiveCFJudge"))
      create_ama_cavc_appeal(judge_inactivejudge101, create_veteran_for_inactivejudge101_judge("TiedToInactiveJudge101"))
      create_ama_cavc_appeal(judge_bvaabode, create_veteran_for_bvaabode_judge("TiedToBode"))
      create_ama_cavc_appeal(judge_bvakkeeling, create_veteran_for_bvakkeeling_judge("TiedToKeeling"))
      create_ama_cavc_appeal(judge_bvaaabshire, create_veteran_for_bvaaabshire_judge("TiedToAbshire"))
    end

    def ama_cavc_aod_appeals_with_no_hearing_held
      ama_cavc_aod_appeal_with_no_hearing_held(judge_bvagsporer, create_veteran_for_bvagsporer_judge(),7.days.ago)
      ama_cavc_aod_appeal_with_no_hearing_held(judge_bvaeemard, create_veteran_for_bvaeemard_judge(),7.days.ago)
      ama_cavc_aod_appeal_with_no_hearing_held(judge_bvabdaniel, create_veteran_for_bvabdaniel_judge(),7.days.ago)
      ama_cavc_aod_appeal_with_no_hearing_held(judge_bvadcremin, create_veteran_for_bvadcremin_judge(),7.days.ago)
      ama_cavc_aod_appeal_with_no_hearing_held(judge_bvaoschowalt, create_veteran_for_bvaoschowalt_judge(),7.days.ago)
      ama_cavc_aod_appeal_with_no_hearing_held(judge_bvadcremin, create_veteran_for_bvadcremin_judge(),7.days.ago)
      ama_cavc_aod_appeal_with_no_hearing_held(judge_bvagsporer, create_veteran_for_bvagsporer_judge(),21.days.ago)
      ama_cavc_aod_appeal_with_no_hearing_held(judge_bvaeemard, create_veteran_for_bvaeemard_judge(),21.days.ago)
      ama_cavc_aod_appeal_with_no_hearing_held(judge_bvabdaniel, create_veteran_for_bvabdaniel_judge(),21.days.ago)
      ama_cavc_aod_appeal_with_no_hearing_held(judge_bvadcremin, create_veteran_for_bvadcremin_judge(),21.days.ago)
      ama_cavc_aod_appeal_with_no_hearing_held(judge_bvaoschowalt, create_veteran_for_bvaoschowalt_judge(),21.days.ago)
      ama_cavc_aod_appeal_with_no_hearing_held(judge_bvaoschowalt, create_veteran_for_bvaoschowalt_judge(),21.days.ago)
    end

    def create_legacy_appeals_with_null_judge_value
      3.times do
        create_legacy_appeal_with_null_judge_value(create_veteran_for_genpop())
      end
    end

    def create_ama_aod_appeals_with_null_judge_value
      3.times do
        create_ama_aod_appeal_with_null_judge_value(create_veteran_for_genpop())
      end
    end

    def create_ama_cavc_appeals_with_null_judge_value
      3.times do
        create_ama_cavc_appeal_with_null_judge_value(create_veteran_for_genpop())
      end
    end

    def create_legacy_appeal_without_hearing_held(judge, veteran)
      create(
        :legacy_appeal,
        :with_veteran,
        vacols_case:
          create(
          :case,
          :ready_for_distribution,
          :type_original,
          :with_appeal_affinity,
          bfcorlid: "#{veteran.file_number}S",
          bfmemid: VACOLS::Staff.find_by(sdomainid: judge.css_id).sattyid
          )
      )
    end

    def create_legacy_appeal_with_hearing_and_excluded_or_ineligible_judge(judge, veteran)
      create(
        :legacy_appeal,
        :with_veteran,
        vacols_case:
          create(
          :case,
          :tied_to_judge,
          :ready_for_distribution,
          :type_original,
          :with_appeal_affinity,
          tied_judge: judge,
          bfcorlid: "#{veteran.file_number}S",
          bfmemid: VACOLS::Staff.find_by(sdomainid: judge.css_id).sattyid
          )
      )
    end

    def create_ama_cavc_appeal_with_no_hearing_held(judge, veteran, days)
      attorney = find_or_create_attorney("CAVCATNY", "CAVC Attorney")
      Timecop.travel(days + 1.day)
        ama_cavc_appeal= create(
          :appeal,
          :dispatched,
          veteran: veteran,
          associated_judge: judge,
          associated_attorney: attorney
        )
      Timecop.return
      Timecop.travel(days)
        remand = create(:cavc_remand, source_appeal: ama_cavc_appeal)
        remand.remand_appeal.tasks.where(type: SendCavcRemandProcessedLetterTask.name).first.completed!
        create(:appeal_affinity, appeal: remand.remand_appeal)
      Timecop.return
    end

    def create_legacy_appeal_with_null_judge_value(veteran)
      create(
        :legacy_appeal,
        :with_veteran,
        vacols_case:
          create(
          :case,
          :ready_for_distribution,
          :type_original,
          :with_appeal_affinity,
          bfcorlid: "#{veteran.file_number}S",
          )
      )
    end

    def create_ama_aod_appeal_with_null_judge_value(veteran)
        create(
          :appeal,
          :advanced_on_docket_due_to_age,
          :ready_for_distribution,
          :with_appeal_affinity,
          veteran: veteran,
        )
    end

    def create_ama_cavc_appeal_with_null_judge_value(veteran)
      attorney = find_or_create_attorney("CAVCATNY", "CAVC Attorney")
      Timecop.travel(1.day.ago)
        ama_cavc_appeal= create(
          :appeal,
          :dispatched,
          veteran: veteran,
          associated_attorney: attorney
        )
      Timecop.return
        remand = create(:cavc_remand, source_appeal: ama_cavc_appeal)
        remand.remand_appeal.tasks.where(type: SendCavcRemandProcessedLetterTask.name).first.completed!
        create(:appeal_affinity, appeal: remand.remand_appeal)
    end

    def create_ama_cavc_appeal(judge, veteran)
      attorney = find_or_create_attorney("CAVCATNY", "CAVC Attorney")
      Timecop.travel(1.day.ago)
        ama_hearing_cavc_appeal = create(
          :appeal,
          :hearing_docket,
          :held_hearing,
          :tied_to_judge,
          :dispatched,
          veteran: veteran,
          tied_judge: judge,
          associated_judge: judge,
          adding_user: User.first,
          associated_attorney: attorney
        )
      Timecop.return
        remand = create(:cavc_remand, source_appeal: ama_hearing_cavc_appeal)
        remand.remand_appeal.tasks.where(type: SendCavcRemandProcessedLetterTask.name).first.completed!
        create(:appeal_affinity, appeal: remand.remand_appeal)
    end

    def ama_cavc_aod_appeal_with_no_hearing_held(judge, veteran, days)
      attorney = find_or_create_attorney("CAVCATNY", "CAVC Attorney")
      Timecop.travel(days + 1.day)
        ama_cavc_aod_appeal= create(
          :appeal,
          :advanced_on_docket_due_to_age,
          :dispatched,
          veteran: veteran,
          associated_judge: judge,
          associated_attorney: attorney
        )
      Timecop.return
      Timecop.travel(days)
        remand = create(:cavc_remand, source_appeal: ama_cavc_aod_appeal)
        remand.remand_appeal.tasks.where(type: SendCavcRemandProcessedLetterTask.name).first.completed!
        create(:appeal_affinity, appeal: remand.remand_appeal)
      Timecop.return
    end
  end
end
