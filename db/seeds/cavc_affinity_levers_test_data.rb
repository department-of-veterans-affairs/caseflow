# frozen_string_literal: true

module Seeds
  class CavcAffinityLeversTestData < Base

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
      create_legacy_cavc_affinity_cases
      create_legacy_cavc_aod_affinity_cases
      create_legacy_cavc_cases_with_new_hearings
      update_ineligible_users
    end

    private

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
        user = User.find_by_css_id(css_id)

        if user && !user.judge_in_vacols?
          create(:staff, :judge_role, slogid: user.css_id, user: user)
        elsif !user
          user = create(:user, :judge, :with_vacols_judge_record, css_id: css_id, full_name: full_name)
        end

        user
    end

    def find_or_create_attorney(css_id, full_name)
      User.find_by_css_id(css_id) ||
        create(:user, :with_vacols_attorney_record, css_id: css_id, full_name: full_name)
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
     @judge_inactivejudge ||= find_or_create_active_judge("INACTIVEJUDGE", "Inactive InVacols Judge")
    end

    def judge_inactivecfjudge
     @judge_inactivecfjudge ||= find_or_create_active_judge("INACTIVECFJUDGE", "InactiveCF InactiveInCF Judge")
    end

    def judge_inactivejudge101
     @judge_inactivejudge101 ||= find_or_create_active_judge("INACTIVEJUDGE101", "Inactive101 InactiveAt101 Judge")
    end

    def judge_bvaabode
     @judge_bvaabode ||= find_or_create_active_judge("BVAABODE", "Anastacio H Bode")
    end

    def judge_bvakkeeling
     @judge_bvakkeeling ||= find_or_create_active_judge("BVAKKEELING", "Keith Judge_CaseToAssign_NoTeam Keeling")
    end

    def judge_bvaaabshire
     @judge_bvaaabshire ||= find_or_create_active_judge("BVAAABSHIRE", "Aaron Judge_HearingsAndCases Abshire")
    end

    def attorney
      @attorney ||= find_or_create_attorney("CAVCATNY", "CAVC Attorney")
    end

    def update_ineligible_users
      ineligible_users = ["INACTIVEJUDGE", "INACTIVECFJUDGE", "INACTIVEJUDGE101",
         "BVAABODE", "BVAKKEELING", "BVAAABSHIRE"]

         ineligible_users.each { |sdomainid|
          vacols_record = VACOLS::Staff.find_by_sdomainid(sdomainid)
          vacols_record.update!(sactive: "I") if vacols_record.sactive == "A"
        }
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
      create_legacy_aod_appeals_with_hearing_and_excluded_or_ineligible_judge
      ama_cavc_aod_appeals_with_no_hearing_held
      create_legacy_aod_appeals_with_null_judge_value
      create_ama_aod_appeals_with_null_judge_value
      create_ama_cavc_aod_appeals_with_null_judge_value
    end

    def create_legacy_cavc_affinity_cases
      create_cases_for_cavc_affinty_days_lever
      create_cases_for_cavc_affinty_days_lever_excluded_judge
      create_cases_for_cavc_affinity_days_lever_ineligible_judge
    end

    def create_legacy_cavc_aod_affinity_cases
      create_cases_for_cavc_aod_affinty_days_lever
      create_cases_for_cavc_aod_affinty_days_lever_excluded_judge
      create_cases_for_cavc_aod_affinity_days_lever_ineligible_judge
    end

    def create_legacy_cavc_cases_with_new_hearings
      # original hearing held by SPORER, decided by SPORER, new hearing held by BDANIEL => tied to BDANIEL
      c1 = create(:legacy_cavc_appeal, bfd19: 5.years.ago, bfcorlid: "#{create_veteran_for_bvabdaniel_judge("TiedToDaniel").file_number}S", judge: VACOLS::Staff.find_by(sdomainid: judge_bvagsporer.css_id), attorney: VACOLS::Staff.find_by(sdomainid: attorney.css_id), tied_to: true)
      create(:case_hearing, :disposition_held, folder_nr: (c1.bfkey.to_i + 1).to_s, hearing_date: Time.zone.today, user: judge_bvabdaniel)

      # original hearing held by SPORER, decided by bvadcremin, new hearing held by BDANIEL => tied to EEMARD
      c2 = create(:legacy_cavc_appeal, bfd19: 5.years.ago, bfcorlid: "#{create_veteran_for_bvabdaniel_judge("TiedToEemard").file_number}S", judge: VACOLS::Staff.find_by(sdomainid: judge_bvagsporer.css_id), attorney: VACOLS::Staff.find_by(sdomainid: attorney.css_id), tied_to: true)
      c2.update!(bfmemid: judge_bvadcremin.vacols_attorney_id)
      create(:case_hearing, :disposition_held, folder_nr: (c2.bfkey.to_i + 1).to_s, hearing_date: Time.zone.today, user: judge_bvaeemard)

      # no original hearing, decided by BVADCREMIN, new hearing held by BDANIEL => tied to SCHOWALT
      c3 = create(:legacy_cavc_appeal, bfd19: 5.years.ago, bfcorlid: "#{create_veteran_for_bvabdaniel_judge("TiedToSchowalt").file_number}S", judge: VACOLS::Staff.find_by(sdomainid: judge_bvadcremin.css_id), attorney: VACOLS::Staff.find_by(sdomainid: attorney.css_id), tied_to: false)
      create(:case_hearing, :disposition_held, folder_nr: (c3.bfkey.to_i + 1).to_s, hearing_date: Time.zone.today, user: judge_bvaoschowalt)

      # original hearing held by SPORER, no original deciding judge, new hearing held by BDANIEL => tied to BDANIEL
      c4 = create(:legacy_cavc_appeal, bfd19: 5.years.ago, bfcorlid: "#{create_veteran_for_bvabdaniel_judge("TiedToDaniel").file_number}S", judge: VACOLS::Staff.find_by(sdomainid: judge_bvagsporer.css_id), attorney: VACOLS::Staff.find_by(sdomainid: attorney.css_id), tied_to: true)
      c4.update!(bfmemid: nil)
      create(:case_hearing, :disposition_held, folder_nr: (c4.bfkey.to_i + 1).to_s, hearing_date: Time.zone.today, user: judge_bvabdaniel)

      # no original hearing, no original deciding judge, new hearing held by BDANIEL => tied to BDANIEL
      c5 = create(:legacy_cavc_appeal, bfd19: 5.years.ago, bfcorlid: "#{create_veteran_for_bvabdaniel_judge("TiedToDaniel").file_number}S", judge: VACOLS::Staff.find_by(sdomainid: judge_bvagsporer.css_id), attorney: VACOLS::Staff.find_by(sdomainid: attorney.css_id), tied_to: false)
      c5.update!(bfmemid: nil)
      create(:case_hearing, :disposition_held, folder_nr: (c5.bfkey.to_i + 1).to_s, hearing_date: Time.zone.today, user: judge_bvabdaniel)

      # original hearing held by SPORER, decided by SPORER, no new hearing => tied to SPORER
      create(:legacy_cavc_appeal, bfd19: 5.years.ago, bfcorlid: "#{create_veteran_for_bvagsporer_judge("TiedToSporer").file_number}S", judge: VACOLS::Staff.find_by(sdomainid: judge_bvagsporer.css_id), attorney: VACOLS::Staff.find_by(sdomainid: attorney.css_id), tied_to: true)

      # original hearing held by SPORER, decided by BVADCREMIN, no new hearing => affinity to BVADCREMIN
      c7 = create(:legacy_cavc_appeal, bfd19: 5.years.ago, bfcorlid: "#{create_veteran_for_bvadcremin_judge("AffinityToCremin").file_number}S", judge: VACOLS::Staff.find_by(sdomainid: judge_bvagsporer.css_id), attorney: VACOLS::Staff.find_by(sdomainid: attorney.css_id), tied_to: true, affinity_start_date: 3.days.ago)
      c7.update!(bfmemid: judge_bvadcremin.vacols_attorney_id)

      # no original hearing, decided by BVADCREMIN, no new hearing => affintiy to BVADCREMIN
      create(:legacy_cavc_appeal, bfd19: 5.years.ago, bfcorlid: "#{create_veteran_for_bvadcremin_judge("AffinityToCremin").file_number}S", judge: VACOLS::Staff.find_by(sdomainid: judge_bvadcremin.css_id), attorney: VACOLS::Staff.find_by(sdomainid: attorney.css_id), tied_to: false, affinity_start_date: 3.days.ago)

      # original hearing held by SPORER, no original deciding judge, no new hearing => genpop
      c9 = create(:legacy_cavc_appeal, bfd19: 5.years.ago, bfcorlid: "#{create_veteran_for_genpop("Genpop").file_number}S", judge: VACOLS::Staff.find_by(sdomainid: judge_bvagsporer.css_id), attorney: VACOLS::Staff.find_by(sdomainid: attorney.css_id), tied_to: true)
      c9.update!(bfmemid: nil)

      # no original hearing, no original deciding judge, no new hearing => genpop
      c10 = create(:legacy_cavc_appeal, bfd19: 5.years.ago, bfcorlid: "#{create_veteran_for_genpop("Genpop").file_number}S", judge: VACOLS::Staff.find_by(sdomainid: judge_bvagsporer.css_id), attorney: VACOLS::Staff.find_by(sdomainid: attorney.css_id), tied_to: false)
      c10.update!(bfmemid: nil)

      # original hearing held by SPORER, decided by SPORER, new hearing held by judge_inactivejudge
      c11 = create(:legacy_cavc_appeal, bfd19: 5.years.ago, bfcorlid: "#{create_veteran_for_inactivejudge_judge("Genpop").file_number}S", judge: VACOLS::Staff.find_by(sdomainid: judge_bvagsporer.css_id), attorney: VACOLS::Staff.find_by(sdomainid: attorney.css_id), tied_to: true)
      create(:case_hearing, :disposition_held, folder_nr: (c11.bfkey.to_i + 1).to_s, hearing_date: Time.zone.today, user: judge_inactivejudge)

      # original hearing held by judge_inactivejudge, decided by judge_inactivejudge, no new hearing => genpop
      create(:legacy_cavc_appeal, bfd19: 5.years.ago, bfcorlid: "#{create_veteran_for_inactivejudge_judge("Genpop").file_number}S", judge: VACOLS::Staff.find_by(sdomainid: judge_inactivejudge.css_id), attorney: VACOLS::Staff.find_by(sdomainid: attorney.css_id), tied_to: true)

      # original hearing held by SPORER, decided by SPORER, new hearing held by judge_inactivejudge
      c13 = create(:legacy_cavc_appeal, bfd19: 5.years.ago, bfcorlid: "#{create_veteran_for_inactivejudge_judge("Genpop").file_number}S", judge: VACOLS::Staff.find_by(sdomainid: judge_bvagsporer.css_id), attorney: VACOLS::Staff.find_by(sdomainid: attorney.css_id), tied_to: true, affinity_start_date: 3.days.ago)
      create(:case_hearing, :disposition_held, folder_nr: (c13.bfkey.to_i + 1).to_s, hearing_date: Time.zone.today, user: judge_inactivejudge)
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

    #{ TIED TO ?? }
    def create_legacy_appeals_with_hearing_and_excluded_or_ineligible_judge
      2.times do
        create_legacy_appeal_with_hearing_and_excluded_or_ineligible_judge(judge_bvaawakefield, create_veteran_for_bvaawakefield_judge("TiedToWakefield"))
        create_legacy_appeal_with_hearing_and_excluded_or_ineligible_judge(judge_bvacgislason1, create_veteran_for_bvacgislason1_judge("TiedToGislason"))
      end
      create_legacy_appeal_with_hearing_and_excluded_or_ineligible_judge(judge_activejudgeteam, create_veteran_for_activejudgeteam_judge("TiedToActiveJudgeTeam"))
      create_legacy_appeal_with_hearing_and_excluded_or_ineligible_judge(judge_inactivejudge, create_veteran_for_inactivejudge_judge("TiedToInactiveJudge"))
      create_legacy_appeal_with_hearing_and_excluded_or_ineligible_judge(judge_inactivecfjudge, create_veteran_for_inactivecfjudge_judge("TiedToInactiveCFJudge"))
      create_legacy_appeal_with_hearing_and_excluded_or_ineligible_judge(judge_inactivejudge101, create_veteran_for_inactivejudge101_judge("TiedToInactiveJudge101"))
      create_legacy_appeal_with_hearing_and_excluded_or_ineligible_judge(judge_bvaabode, create_veteran_for_bvaabode_judge("TiedToBode"))
      create_legacy_appeal_with_hearing_and_excluded_or_ineligible_judge(judge_bvakkeeling, create_veteran_for_bvakkeeling_judge("TiedToKeeling"))
      create_legacy_appeal_with_hearing_and_excluded_or_ineligible_judge(judge_bvaaabshire, create_veteran_for_bvaaabshire_judge("TiedToAbshire"))
    end

    def create_legacy_aod_appeals_with_hearing_and_excluded_or_ineligible_judge
      2.times do
        create_legacy_aod_appeal_with_hearing_and_excluded_or_ineligible_judge(judge_bvaawakefield, create_veteran_for_bvaawakefield_judge("TiedToWakefield"))
        create_legacy_aod_appeal_with_hearing_and_excluded_or_ineligible_judge(judge_bvacgislason1, create_veteran_for_bvacgislason1_judge("TiedToGislason"))
      end
      create_legacy_aod_appeal_with_hearing_and_excluded_or_ineligible_judge(judge_activejudgeteam, create_veteran_for_activejudgeteam_judge("TiedToActiveJudgeTeam"))
      create_legacy_aod_appeal_with_hearing_and_excluded_or_ineligible_judge(judge_inactivejudge, create_veteran_for_inactivejudge_judge("TiedToInactiveJudge"))
      create_legacy_aod_appeal_with_hearing_and_excluded_or_ineligible_judge(judge_inactivecfjudge, create_veteran_for_inactivecfjudge_judge("TiedToInactiveCFJudge"))
      create_legacy_aod_appeal_with_hearing_and_excluded_or_ineligible_judge(judge_inactivejudge101, create_veteran_for_inactivejudge101_judge("TiedToInactiveJudge101"))
      create_legacy_aod_appeal_with_hearing_and_excluded_or_ineligible_judge(judge_bvaabode, create_veteran_for_bvaabode_judge("TiedToBode"))
      create_legacy_aod_appeal_with_hearing_and_excluded_or_ineligible_judge(judge_bvakkeeling, create_veteran_for_bvakkeeling_judge("TiedToKeeling"))
      create_legacy_aod_appeal_with_hearing_and_excluded_or_ineligible_judge(judge_bvaaabshire, create_veteran_for_bvaaabshire_judge("TiedToAbshire"))
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

    #{ TIED TO ??}
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

    def create_legacy_aod_appeals_with_null_judge_value
      3.times do
        create_legacy_aod_appeal_with_null_judge_value(create_veteran_for_genpop())
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

    def create_ama_cavc_aod_appeals_with_null_judge_value
      3.times do
        create_ama_cavc_aod_appeal_with_null_judge_value(create_veteran_for_genpop())
      end
    end

    def create_legacy_appeal_without_hearing_held(judge, veteran)
      create(:legacy_cavc_appeal, cavc: false, tied_to: false, affinity_start_date: Time.zone.now, bfcorlid: "#{veteran.file_number}S", judge: VACOLS::Staff.find_by(sdomainid: judge.css_id), attorney: VACOLS::Staff.find_by(sdomainid: attorney.css_id))
    end

    def create_legacy_appeal_with_hearing_and_excluded_or_ineligible_judge(judge, veteran)
      create(:legacy_cavc_appeal, cavc: false, affinity_start_date: Time.zone.now, bfcorlid: "#{veteran.file_number}S", judge: VACOLS::Staff.find_by(sdomainid: judge.css_id), attorney: VACOLS::Staff.find_by(sdomainid: attorney.css_id))
    end

    def create_legacy_aod_appeal_with_hearing_and_excluded_or_ineligible_judge(judge, veteran)
      create(:legacy_cavc_appeal, cavc: false, aod:true, affinity_start_date: Time.zone.now, bfcorlid: "#{veteran.file_number}S", judge: VACOLS::Staff.find_by(sdomainid: judge.css_id), attorney: VACOLS::Staff.find_by(sdomainid: attorney.css_id))
    end

    def create_ama_cavc_appeal_with_no_hearing_held(judge, veteran, days)
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
          bfcorlid: "#{veteran.file_number}S"
          )
      )
    end

    def create_legacy_aod_appeal_with_null_judge_value(veteran)
      create(
        :legacy_appeal,
        :with_veteran,
        vacols_case:
          create(
          :case,
          :aod,
          :ready_for_distribution,
          :type_original,
          :with_appeal_affinity,
          bfcorlid: "#{veteran.file_number}S"
          )
      )
    end

    def create_ama_aod_appeal_with_null_judge_value(veteran)
        create(
          :appeal,
          :advanced_on_docket_due_to_age,
          :ready_for_distribution,
          :with_appeal_affinity,
          veteran: veteran
        )
    end

    def create_ama_cavc_appeal_with_null_judge_value(veteran)
      Timecop.travel(1.day.ago)
        ama_cavc_appeal= create(
          :appeal,
          :cavc_ready_for_distribution,
          veteran: veteran,
          associated_attorney: attorney
        )
      Timecop.return
        remand = create(:cavc_remand, source_appeal: ama_cavc_appeal)
        remand.remand_appeal.tasks.where(type: SendCavcRemandProcessedLetterTask.name).first.completed!
        create(:appeal_affinity, appeal: remand.remand_appeal)
    end

    def create_ama_cavc_aod_appeal_with_null_judge_value(veteran)
      Timecop.travel(1.day.ago)
        ama_cavc_aod_appeal= create(
          :appeal,
          :advanced_on_docket_due_to_age,
          :cavc_ready_for_distribution,
          veteran: veteran
        )
      Timecop.return
        remand = create(:cavc_remand, source_appeal: ama_cavc_aod_appeal)
        remand.remand_appeal.tasks.where(type: SendCavcRemandProcessedLetterTask.name).first.completed!
        create(:appeal_affinity, appeal: remand.remand_appeal)
    end

    def create_ama_cavc_appeal(judge, veteran)
      # Go back to when we want the original appeal to have been decided
      Timecop.travel(4.years.ago)

      # Create a decided appeal. all tasks are marked complete at the same time which won't affect distribution
      source = create(:appeal, :dispatched, :hearing_docket, associated_judge: judge, veteran: veteran)

      Timecop.travel(1.year.from_now)
      remand = create(:cavc_remand, source_appeal: source).remand_appeal
      Timecop.return

      # Travel to 9 mo. ago and then in smaller increments for a more "realistic" looking task tree
      Timecop.travel(9.months.ago)
      remand.tasks.where(type: SendCavcRemandProcessedLetterTask.name).map(&:completed!)
      create(:appeal_affinity, appeal: remand)

      Timecop.travel(1.month.from_now)
      # Call the creator class which will handle the task manipulation normally done by a distribution
      jat = JudgeAssignTaskCreator.new(appeal: remand, judge: judge, assigned_by_id: judge.id).call
      # Create and complete a ScheduleHearingColocatedTask, which will create a new DistributionTask and
      # HearingTask subtree to mimic how this would happen in a higher environment
      create(:colocated_task, :schedule_hearing, parent: jat, assigned_by: judge).completed!

      Timecop.travel(1.month.from_now)
      create(:hearing, :held, appeal: remand, judge: judge, adding_user: User.system_user)

      Timecop.travel(3.months.from_now)
      # Completes the remaining open HearingTask descendant tasks to make appeal ready to distribute
      remand.tasks.where(type: AssignHearingDispositionTask.name).flat_map(&:children).map(&:completed!)
      Timecop.return

      # When a DistributionTask goes to assigned it clears the affinity start date, so restore that at the right date
      remand.appeal_affinity.update!(affinity_start_date: Time.zone.now)
    end

    def ama_cavc_aod_appeal_with_no_hearing_held(judge, veteran, days)
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

    def create_cases_for_cavc_affinty_days_lever
      # cavc affinity cases:
        # no hearing held but has previous decision
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran_for_bvagsporer_judge().file_number}S",  judge: VACOLS::Staff.find_by(sdomainid: judge_bvagsporer.css_id), attorney: VACOLS::Staff.find_by(sdomainid: attorney.css_id), tied_to: false)
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran_for_bvagsporer_judge().file_number}S",  judge: VACOLS::Staff.find_by(sdomainid: judge_bvagsporer.css_id), attorney: VACOLS::Staff.find_by(sdomainid: attorney.css_id),
                                    tied_to: false, affinity_start_date: 3.days.ago)
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran_for_bvagsporer_judge().file_number}S",  judge: VACOLS::Staff.find_by(sdomainid: judge_bvagsporer.css_id), attorney: VACOLS::Staff.find_by(sdomainid: attorney.css_id),
                                    tied_to: false, appeal_affinity: false)
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran_for_bvaeemard_judge().file_number}S",  judge: VACOLS::Staff.find_by(sdomainid: judge_bvaeemard.css_id), attorney: VACOLS::Staff.find_by(sdomainid: attorney.css_id), tied_to: false)
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran_for_bvaeemard_judge().file_number}S",  judge: VACOLS::Staff.find_by(sdomainid: judge_bvaeemard.css_id), attorney: VACOLS::Staff.find_by(sdomainid: attorney.css_id),
                                    tied_to: false, affinity_start_date: 3.days.ago)
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran_for_bvaeemard_judge().file_number}S",  judge: VACOLS::Staff.find_by(sdomainid: judge_bvaeemard.css_id), attorney: VACOLS::Staff.find_by(sdomainid: attorney.css_id),
                                    tied_to: false, appeal_affinity: false)
        # hearing held with previous decision where judge is not the same
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran_for_bvagsporer_judge().file_number}S", judge: VACOLS::Staff.find_by(sdomainid: judge_bvaoschowalt.css_id), attorney: VACOLS::Staff.find_by(sdomainid: attorney.css_id))
        .update!(bfmemid: VACOLS::Staff.find_by(sdomainid: judge_bvagsporer.css_id).sattyid)

        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran_for_bvagsporer_judge().file_number}S", judge: VACOLS::Staff.find_by(sdomainid: judge_bvaoschowalt.css_id), attorney: VACOLS::Staff.find_by(sdomainid: attorney.css_id),
                                          affinity_start_date: 3.days.ago)
                                          .update!(bfmemid: VACOLS::Staff.find_by(sdomainid: judge_bvagsporer.css_id).sattyid)

        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran_for_bvagsporer_judge().file_number}S", judge: VACOLS::Staff.find_by(sdomainid: judge_bvaoschowalt.css_id), attorney: VACOLS::Staff.find_by(sdomainid: attorney.css_id), appeal_affinity: false)
        .update!(bfmemid: VACOLS::Staff.find_by(sdomainid: judge_bvagsporer.css_id).sattyid)

        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran_for_bvaeemard_judge().file_number}S", judge: VACOLS::Staff.find_by(sdomainid: judge_bvaoschowalt.css_id), attorney: VACOLS::Staff.find_by(sdomainid: attorney.css_id))
        .update!(bfmemid: VACOLS::Staff.find_by(sdomainid: judge_bvaeemard.css_id).sattyid)

        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran_for_bvaeemard_judge().file_number}S", judge: VACOLS::Staff.find_by(sdomainid: judge_bvaoschowalt.css_id), attorney: VACOLS::Staff.find_by(sdomainid: attorney.css_id),
                                          affinity_start_date: 3.days.ago)
                                          .update!(bfmemid: VACOLS::Staff.find_by(sdomainid: judge_bvaeemard.css_id).sattyid)

        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran_for_bvaeemard_judge().file_number}S", judge: VACOLS::Staff.find_by(sdomainid: judge_bvaoschowalt.css_id), attorney: VACOLS::Staff.find_by(sdomainid: attorney.css_id), appeal_affinity: false)
        .update!(bfmemid: VACOLS::Staff.find_by(sdomainid: judge_bvaeemard.css_id).sattyid)

        # hearing held with previous decision where judge is same (THIS IS TIED TO)
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran_for_bvabdaniel_judge("TiedToDaniel").file_number}S", judge: VACOLS::Staff.find_by(sdomainid: judge_bvabdaniel.css_id), attorney: VACOLS::Staff.find_by(sdomainid: attorney.css_id))
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran_for_bvabdaniel_judge("TiedToDaniel").file_number}S", judge: VACOLS::Staff.find_by(sdomainid: judge_bvabdaniel.css_id), attorney: VACOLS::Staff.find_by(sdomainid: attorney.css_id), affinity_start_date: 3.days.ago)
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran_for_bvabdaniel_judge("TiedToDaniel").file_number}S", judge: VACOLS::Staff.find_by(sdomainid: judge_bvabdaniel.css_id), attorney: VACOLS::Staff.find_by(sdomainid: attorney.css_id), appeal_affinity: false)
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran_for_bvaeemard_judge("TiedToEmard").file_number}S", judge: VACOLS::Staff.find_by(sdomainid: judge_bvaeemard.css_id), attorney: VACOLS::Staff.find_by(sdomainid: attorney.css_id))
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran_for_bvaeemard_judge("TiedToEmard").file_number}S", judge: VACOLS::Staff.find_by(sdomainid: judge_bvaeemard.css_id), attorney: VACOLS::Staff.find_by(sdomainid: attorney.css_id), affinity_start_date: 3.days.ago)
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran_for_bvaeemard_judge("TiedToEmard").file_number}S", judge: VACOLS::Staff.find_by(sdomainid: judge_bvaeemard.css_id), attorney: VACOLS::Staff.find_by(sdomainid: attorney.css_id), appeal_affinity: false)

        # hearing held but no previous deciding judge
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran_for_genpop().file_number}S", judge: VACOLS::Staff.find_by(sdomainid: judge_bvabdaniel.css_id), attorney: VACOLS::Staff.find_by(sdomainid: attorney.css_id))
        .update!(bfmemid: nil)
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran_for_genpop().file_number}S", judge: VACOLS::Staff.find_by(sdomainid: judge_bvaeemard.css_id), attorney: VACOLS::Staff.find_by(sdomainid: attorney.css_id))
        .update!(bfmemid: nil)

        # no hearing held, no previous deciding judge
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran_for_genpop().file_number}S", judge: VACOLS::Staff.find_by(sdomainid: judge_bvagsporer.css_id), attorney: VACOLS::Staff.find_by(sdomainid: attorney.css_id),
                                          tied_to: false).update!(bfmemid: nil)
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran_for_genpop().file_number}S", judge: VACOLS::Staff.find_by(sdomainid: judge_bvaeemard.css_id), attorney: VACOLS::Staff.find_by(sdomainid: attorney.css_id),
                                          tied_to: false).update!(bfmemid: nil)
    end

    def create_cases_for_cavc_affinty_days_lever_excluded_judge
      # excluded judge cases:
        # no hearing held but has previous decision
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran_for_bvaawakefield_judge().file_number}S", judge: VACOLS::Staff.find_by(sdomainid: judge_bvaawakefield.css_id), attorney: VACOLS::Staff.find_by(sdomainid: attorney.css_id), tied_to: false)
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran_for_bvaawakefield_judge().file_number}S", judge: VACOLS::Staff.find_by(sdomainid: judge_bvaawakefield.css_id), attorney: VACOLS::Staff.find_by(sdomainid: attorney.css_id),
                                      tied_to: false, affinity_start_date: 3.days.ago)
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran_for_bvaawakefield_judge().file_number}S", judge: VACOLS::Staff.find_by(sdomainid: judge_bvaawakefield.css_id), attorney: VACOLS::Staff.find_by(sdomainid: attorney.css_id),
                                      tied_to: false, appeal_affinity: false)
        # hearing held with previous decision where judge is not the same
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran_for_bvaawakefield_judge().file_number}S", judge: VACOLS::Staff.find_by(sdomainid: judge_bvaoschowalt.css_id), attorney: VACOLS::Staff.find_by(sdomainid: attorney.css_id))
        .update!(bfmemid: VACOLS::Staff.find_by(sdomainid: judge_bvaawakefield.css_id).sattyid)

        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran_for_bvaawakefield_judge().file_number}S", judge: VACOLS::Staff.find_by(sdomainid: judge_bvaoschowalt.css_id), attorney: VACOLS::Staff.find_by(sdomainid: attorney.css_id),
                                      affinity_start_date: 3.days.ago)
                                      .update!(bfmemid: VACOLS::Staff.find_by(sdomainid: judge_bvaawakefield.css_id).sattyid)

        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran_for_bvaawakefield_judge().file_number}S", judge: VACOLS::Staff.find_by(sdomainid: judge_bvaoschowalt.css_id), attorney: VACOLS::Staff.find_by(sdomainid: attorney.css_id), appeal_affinity: false)
        .update!(bfmemid: VACOLS::Staff.find_by(sdomainid: judge_bvaawakefield.css_id).sattyid)

        # hearing held with previous decision where judge is same (THIS IS TIED TO)
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran_for_bvaawakefield_judge("TiedToWakefield").file_number}S", judge: VACOLS::Staff.find_by(sdomainid: judge_bvaawakefield.css_id), attorney: VACOLS::Staff.find_by(sdomainid: attorney.css_id))
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran_for_bvaawakefield_judge("TiedToWakefield").file_number}S", judge: VACOLS::Staff.find_by(sdomainid: judge_bvaawakefield.css_id), attorney: VACOLS::Staff.find_by(sdomainid: attorney.css_id), affinity_start_date: 3.days.ago)
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran_for_bvaawakefield_judge("TiedToWakefield").file_number}S", judge: VACOLS::Staff.find_by(sdomainid: judge_bvaawakefield.css_id), attorney: VACOLS::Staff.find_by(sdomainid: attorney.css_id), appeal_affinity: false)
    end

    def create_cases_for_cavc_affinity_days_lever_ineligible_judge
      # ineligible judge cases:
        # no hearing held but has previous decision
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran_for_inactivejudge_judge().file_number}S", judge: VACOLS::Staff.find_by(sdomainid: judge_inactivejudge.css_id), attorney: VACOLS::Staff.find_by(sdomainid: attorney.css_id), tied_to: false)
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran_for_inactivejudge_judge().file_number}S", judge: VACOLS::Staff.find_by(sdomainid: judge_inactivejudge.css_id), attorney: VACOLS::Staff.find_by(sdomainid: attorney.css_id),
                                      tied_to: false, affinity_start_date: 3.days.ago)
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran_for_inactivejudge_judge().file_number}S", judge: VACOLS::Staff.find_by(sdomainid: judge_inactivejudge.css_id), attorney: VACOLS::Staff.find_by(sdomainid: attorney.css_id),
                                      tied_to: false, appeal_affinity: false)
        # hearing held with previous decision where judge is not the same
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran_for_inactivejudge_judge().file_number}S", judge: VACOLS::Staff.find_by(sdomainid: judge_bvaoschowalt.css_id), attorney: VACOLS::Staff.find_by(sdomainid: attorney.css_id))
          .update!(bfmemid: VACOLS::Staff.find_by(sdomainid: judge_inactivejudge.css_id).sattyid)
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran_for_inactivejudge_judge().file_number}S", judge: VACOLS::Staff.find_by(sdomainid: judge_bvaoschowalt.css_id), attorney: VACOLS::Staff.find_by(sdomainid: attorney.css_id),
                                            affinity_start_date: 3.days.ago)
                                            .update!(bfmemid: VACOLS::Staff.find_by(sdomainid: judge_inactivejudge.css_id).sattyid)
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran_for_inactivejudge_judge().file_number}S", judge: VACOLS::Staff.find_by(sdomainid: judge_bvaoschowalt.css_id), attorney: VACOLS::Staff.find_by(sdomainid: attorney.css_id), appeal_affinity: false)
        .update!(bfmemid: VACOLS::Staff.find_by(sdomainid: judge_inactivejudge.css_id).sattyid)
        # hearing held with previous decision where judge is same (THIS IS TIED TO)
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran_for_inactivejudge_judge("TiedToInactiveJudge").file_number}S", judge: VACOLS::Staff.find_by(sdomainid: judge_inactivejudge.css_id), attorney: VACOLS::Staff.find_by(sdomainid: attorney.css_id))
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran_for_inactivejudge_judge("TiedToInactiveJudge").file_number}S", judge: VACOLS::Staff.find_by(sdomainid: judge_inactivejudge.css_id), attorney: VACOLS::Staff.find_by(sdomainid: attorney.css_id),  affinity_start_date: 3.days.ago)
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran_for_inactivejudge_judge("TiedToInactiveJudge").file_number}S", judge: VACOLS::Staff.find_by(sdomainid: judge_inactivejudge.css_id), attorney: VACOLS::Staff.find_by(sdomainid: attorney.css_id),  appeal_affinity: false)
        # hearing held but no previous deciding judge
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran_for_genpop().file_number}S", judge: VACOLS::Staff.find_by(sdomainid: judge_inactivejudge.css_id), attorney: VACOLS::Staff.find_by(sdomainid: attorney.css_id)).update!(bfmemid: nil)
    end

    def create_cases_for_cavc_aod_affinty_days_lever
      # cavc aod affinity cases:
        # no hearing held but has previous decision
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran_for_bvagsporer_judge().file_number}S", judge: VACOLS::Staff.find_by(sdomainid: judge_bvagsporer.css_id), attorney: VACOLS::Staff.find_by(sdomainid: attorney.css_id), aod: true, tied_to: false)
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran_for_bvagsporer_judge().file_number}S", judge: VACOLS::Staff.find_by(sdomainid: judge_bvagsporer.css_id), attorney: VACOLS::Staff.find_by(sdomainid: attorney.css_id), aod: true, tied_to: false, affinity_start_date: 3.days.ago)
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran_for_bvagsporer_judge().file_number}S", judge: VACOLS::Staff.find_by(sdomainid: judge_bvagsporer.css_id), attorney: VACOLS::Staff.find_by(sdomainid: attorney.css_id), aod: true, tied_to: false, appeal_affinity: false)
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran_for_bvaeemard_judge().file_number}S", judge: VACOLS::Staff.find_by(sdomainid: judge_bvaeemard.css_id), attorney: VACOLS::Staff.find_by(sdomainid: attorney.css_id), aod: true, tied_to: false)
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran_for_bvaeemard_judge().file_number}S", judge: VACOLS::Staff.find_by(sdomainid: judge_bvaeemard.css_id), attorney: VACOLS::Staff.find_by(sdomainid: attorney.css_id), aod: true, tied_to: false, affinity_start_date: 3.days.ago)
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran_for_bvaeemard_judge().file_number}S", judge: VACOLS::Staff.find_by(sdomainid: judge_bvaeemard.css_id), attorney: VACOLS::Staff.find_by(sdomainid: attorney.css_id), aod: true, tied_to: false, appeal_affinity: false)
        # hearing held with previous decision where judge is not the same
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran_for_bvagsporer_judge().file_number}S", judge: VACOLS::Staff.find_by(sdomainid: judge_bvaoschowalt.css_id), attorney: VACOLS::Staff.find_by(sdomainid: attorney.css_id), aod: true)
          .update!(bfmemid: VACOLS::Staff.find_by(sdomainid: judge_bvagsporer.css_id).sattyid)
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran_for_bvagsporer_judge().file_number}S", judge: VACOLS::Staff.find_by(sdomainid: judge_bvaoschowalt.css_id), attorney: VACOLS::Staff.find_by(sdomainid: attorney.css_id), aod: true, affinity_start_date: 3.days.ago)
          .update!(bfmemid: VACOLS::Staff.find_by(sdomainid: judge_bvagsporer.css_id).sattyid)
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran_for_bvagsporer_judge().file_number}S", judge: VACOLS::Staff.find_by(sdomainid: judge_bvaoschowalt.css_id), attorney: VACOLS::Staff.find_by(sdomainid: attorney.css_id), aod: true, appeal_affinity: false)
          .update!(bfmemid: VACOLS::Staff.find_by(sdomainid: judge_bvagsporer.css_id).sattyid)
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran_for_bvaeemard_judge().file_number}S", judge: VACOLS::Staff.find_by(sdomainid: judge_bvaoschowalt.css_id), attorney: VACOLS::Staff.find_by(sdomainid: attorney.css_id), aod: true)
          .update!(bfmemid: VACOLS::Staff.find_by(sdomainid: judge_bvaeemard.css_id).sattyid)
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran_for_bvaeemard_judge().file_number}S", judge: VACOLS::Staff.find_by(sdomainid: judge_bvaoschowalt.css_id), attorney: VACOLS::Staff.find_by(sdomainid: attorney.css_id), aod: true, affinity_start_date: 3.days.ago)
          .update!(bfmemid: VACOLS::Staff.find_by(sdomainid: judge_bvaeemard.css_id).sattyid)
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran_for_bvaeemard_judge().file_number}S", judge: VACOLS::Staff.find_by(sdomainid: judge_bvaoschowalt.css_id), attorney: VACOLS::Staff.find_by(sdomainid: attorney.css_id), aod: true, appeal_affinity: false)
          .update!(bfmemid: VACOLS::Staff.find_by(sdomainid: judge_bvaeemard.css_id).sattyid)

        # hearing held with previous decision where judge is same (THIS IS TIED TO)
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran_for_bvabdaniel_judge("TiedToDaniel").file_number}S", judge: VACOLS::Staff.find_by(sdomainid: judge_bvabdaniel.css_id), attorney: VACOLS::Staff.find_by(sdomainid: attorney.css_id), aod: true)
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran_for_bvabdaniel_judge("TiedToDaniel").file_number}S", judge: VACOLS::Staff.find_by(sdomainid: judge_bvabdaniel.css_id), attorney: VACOLS::Staff.find_by(sdomainid: attorney.css_id), aod: true, affinity_start_date: 3.days.ago)
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran_for_bvabdaniel_judge("TiedToDaniel").file_number}S", judge: VACOLS::Staff.find_by(sdomainid: judge_bvabdaniel.css_id), attorney: VACOLS::Staff.find_by(sdomainid: attorney.css_id), aod: true, appeal_affinity: false)
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran_for_bvaeemard_judge("TiedToEmard").file_number}S", judge: VACOLS::Staff.find_by(sdomainid: judge_bvaeemard.css_id), attorney: VACOLS::Staff.find_by(sdomainid: attorney.css_id), aod: true)
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran_for_bvaeemard_judge("TiedToEmard").file_number}S", judge: VACOLS::Staff.find_by(sdomainid: judge_bvaeemard.css_id), attorney: VACOLS::Staff.find_by(sdomainid: attorney.css_id), aod: true, affinity_start_date: 3.days.ago)
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran_for_bvaeemard_judge("TiedToEmard").file_number}S", judge: VACOLS::Staff.find_by(sdomainid: judge_bvaeemard.css_id), attorney: VACOLS::Staff.find_by(sdomainid: attorney.css_id), aod: true, appeal_affinity: false)
        # hearing held but no previous deciding judge
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran_for_genpop().file_number}S", judge: VACOLS::Staff.find_by(sdomainid: judge_bvabdaniel.css_id), attorney: VACOLS::Staff.find_by(sdomainid: attorney.css_id), aod: true)
        .update!(bfmemid: nil)
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran_for_genpop().file_number}S", judge: VACOLS::Staff.find_by(sdomainid: judge_bvaeemard.css_id), attorney: VACOLS::Staff.find_by(sdomainid: attorney.css_id), aod: true)
        .update!(bfmemid: nil)
        # no hearing held, no previous deciding judge
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran_for_genpop().file_number}S", judge: VACOLS::Staff.find_by(sdomainid: judge_bvagsporer.css_id), attorney: VACOLS::Staff.find_by(sdomainid: attorney.css_id), aod: true, tied_to: false)
          .update!(bfmemid: nil)
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran_for_genpop().file_number}S", judge: VACOLS::Staff.find_by(sdomainid: judge_bvaeemard.css_id), attorney: VACOLS::Staff.find_by(sdomainid: attorney.css_id), aod: true, tied_to: false)
          .update!(bfmemid: nil)
    end

    def create_cases_for_cavc_aod_affinty_days_lever_excluded_judge
      # excluded judge cases:
        # no hearing held but has previous decision
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran_for_bvaawakefield_judge().file_number}S", judge: VACOLS::Staff.find_by(sdomainid: judge_bvaawakefield.css_id), attorney: VACOLS::Staff.find_by(sdomainid: attorney.css_id), aod: true, tied_to: false)
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran_for_bvaawakefield_judge().file_number}S", judge: VACOLS::Staff.find_by(sdomainid: judge_bvaawakefield.css_id), attorney: VACOLS::Staff.find_by(sdomainid: attorney.css_id), aod: true, tied_to: false, affinity_start_date: 3.days.ago)
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran_for_bvaawakefield_judge().file_number}S", judge: VACOLS::Staff.find_by(sdomainid: judge_bvaawakefield.css_id), attorney: VACOLS::Staff.find_by(sdomainid: attorney.css_id), aod: true, tied_to: false, appeal_affinity: false)
        # hearing held with previous decision where judge is not the same
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran_for_bvaawakefield_judge().file_number}S", judge: VACOLS::Staff.find_by(sdomainid: judge_bvaoschowalt.css_id), attorney: VACOLS::Staff.find_by(sdomainid: attorney.css_id), aod: true)
          .update!(bfmemid: VACOLS::Staff.find_by(sdomainid: judge_bvaawakefield.css_id).sattyid)
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran_for_bvaawakefield_judge().file_number}S", judge: VACOLS::Staff.find_by(sdomainid: judge_bvaoschowalt.css_id), attorney: VACOLS::Staff.find_by(sdomainid: attorney.css_id), aod: true, affinity_start_date: 3.days.ago)
          .update!(bfmemid: VACOLS::Staff.find_by(sdomainid: judge_bvaawakefield.css_id).sattyid)
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran_for_bvaawakefield_judge().file_number}S", judge: VACOLS::Staff.find_by(sdomainid: judge_bvaoschowalt.css_id), attorney: VACOLS::Staff.find_by(sdomainid: attorney.css_id), aod: true, appeal_affinity: false)
          .update!(bfmemid: VACOLS::Staff.find_by(sdomainid: judge_bvaawakefield.css_id).sattyid)
        # hearing held with previous decision where judge is same (THIS IS TIED TO)
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran_for_bvaawakefield_judge("TiedToWakefield").file_number}S", judge: VACOLS::Staff.find_by(sdomainid: judge_bvaawakefield.css_id), attorney: VACOLS::Staff.find_by(sdomainid: attorney.css_id), aod: true)
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran_for_bvaawakefield_judge("TiedToWakefield").file_number}S", judge: VACOLS::Staff.find_by(sdomainid: judge_bvaawakefield.css_id), attorney: VACOLS::Staff.find_by(sdomainid: attorney.css_id), aod: true, affinity_start_date: 3.days.ago)
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran_for_bvaawakefield_judge("TiedToWakefield").file_number}S", judge: VACOLS::Staff.find_by(sdomainid: judge_bvaawakefield.css_id), attorney: VACOLS::Staff.find_by(sdomainid: attorney.css_id), aod: true, appeal_affinity: false)
    end

    def create_cases_for_cavc_aod_affinity_days_lever_ineligible_judge
      # ineligible judge cases:
        # no hearing held but has previous decision
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran_for_inactivejudge_judge().file_number}S", judge: VACOLS::Staff.find_by(sdomainid: judge_inactivejudge.css_id), attorney: VACOLS::Staff.find_by(sdomainid: attorney.css_id), aod: true, tied_to: false)
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran_for_inactivejudge_judge().file_number}S", judge: VACOLS::Staff.find_by(sdomainid: judge_inactivejudge.css_id), attorney: VACOLS::Staff.find_by(sdomainid: attorney.css_id), aod: true, tied_to: false, affinity_start_date: 3.days.ago)
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran_for_inactivejudge_judge().file_number}S", judge: VACOLS::Staff.find_by(sdomainid: judge_inactivejudge.css_id), attorney: VACOLS::Staff.find_by(sdomainid: attorney.css_id), aod: true, tied_to: false, appeal_affinity: false)
        # hearing held with previous decision where judge is not the same
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran_for_inactivejudge_judge().file_number}S", judge: VACOLS::Staff.find_by(sdomainid: judge_bvaoschowalt.css_id), attorney: VACOLS::Staff.find_by(sdomainid: attorney.css_id), aod: true)
          .update!(bfmemid: VACOLS::Staff.find_by(sdomainid: judge_inactivejudge.css_id).sattyid)
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran_for_inactivejudge_judge().file_number}S", judge: VACOLS::Staff.find_by(sdomainid: judge_bvaoschowalt.css_id), attorney: VACOLS::Staff.find_by(sdomainid: attorney.css_id), aod: true, affinity_start_date: 3.days.ago)
          .update!(bfmemid: VACOLS::Staff.find_by(sdomainid: judge_inactivejudge.css_id).sattyid)
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran_for_inactivejudge_judge().file_number}S", judge: VACOLS::Staff.find_by(sdomainid: judge_bvaoschowalt.css_id), attorney: VACOLS::Staff.find_by(sdomainid: attorney.css_id), aod: true, appeal_affinity: false)
          .update!(bfmemid: VACOLS::Staff.find_by(sdomainid: judge_inactivejudge.css_id).sattyid)
        # hearing held with previous decision where judge is same (THIS IS TIED TO)
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran_for_inactivejudge_judge("TiedToInactiveJudge").file_number}S", judge: VACOLS::Staff.find_by(sdomainid: judge_inactivejudge.css_id), attorney: VACOLS::Staff.find_by(sdomainid: attorney.css_id), aod: true)
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran_for_inactivejudge_judge("TiedToInactiveJudge").file_number}S", judge: VACOLS::Staff.find_by(sdomainid: judge_inactivejudge.css_id), attorney: VACOLS::Staff.find_by(sdomainid: attorney.css_id), aod: true, affinity_start_date: 3.days.ago)
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran_for_inactivejudge_judge("TiedToInactiveJudge").file_number}S", judge: VACOLS::Staff.find_by(sdomainid: judge_inactivejudge.css_id), attorney: VACOLS::Staff.find_by(sdomainid: attorney.css_id), aod: true, appeal_affinity: false)
        # hearing held but no previous deciding judge
        create(:legacy_cavc_appeal, bfcorlid: "#{create_veteran_for_genpop().file_number}S", judge: VACOLS::Staff.find_by(sdomainid: judge_inactivejudge.css_id), attorney: VACOLS::Staff.find_by(sdomainid: attorney.css_id), aod: true)
          .update!(bfmemid: nil)
    end
  end
end
