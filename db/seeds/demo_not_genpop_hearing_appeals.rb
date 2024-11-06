# frozen_string_literal: true

module Seeds
  class DemoNotGenpopHearingAppeals < Base
    def initialize
      initialize_ama_hearing_held_aod_file_number_and_participant_id
      initialize_ready_cavc_file_number_and_participant_id
      initialize_ready_cavc_with_new_hearing_held_file_number_and_participant_id
    end

    def seed!
      RequestStore[:current_user] = User.system_user
      create_judges
      create_appeals
    end

    private

    def create_judges
      find_or_create_judge("AMAAOD", "AMA AOD Test")
      find_or_create_judge("BVAGSPORE", "BVAGSporer")
      find_or_create_judge("READYCAVC", "READY CAVC")
      find_or_create_judge("READYCAVCWNH", "READY CAVC WNH")
      find_or_create_judge("READYCAVCAOD", "READY CAVC AOD")
      find_or_create_judge("READYCAVCWNHAOD", "READY CAVC WNH AOD")
    end

    def create_appeals
      create_ama_hearing_held_aod_appeals(10, find_judge("AMAAOD"), 7.days.ago, 18.years.ago)
      create_ama_hearing_held_aod_appeals(10, find_judge("AMAAOD"), 22.days.ago, 18.years.ago)
      create_ama_hearing_held_aod_appeals(10, find_judge("BVAGSporer"), 395.days.ago, 18.years.ago)

      create_ready_cavc_appeals(10, find_judge("READYCAVC"), 15.days.ago)
      create_ready_cavc_appeals(10, find_judge("READYCAVC"), 22.days.ago)

      create_ready_cavc_appeals_with_new_hearing(10, find_judge("READYCAVCWNH"), 10.days.ago, 10.days.ago)
      create_ready_cavc_appeals_with_new_hearing(10, find_judge("READYCAVCWNH"), 22.days.ago, 22.days.ago)

      create_ready_cavc_appeals(10, find_judge("READYCAVCAOD"), 10.days.ago, 10.days.ago, true)
      reate_ready_cavc_appeals(10, find_judge("READYCAVCAOD"), 22.days.ago, 22.days.ago, true)

      create_ready_cavc_appeals_with_new_hearing(1, find_judge("READYCAVCWNHAOD"), 10.days.ago, 10.days.ago, true)
      create_ready_cavc_appeals_with_new_hearing(10, find_judge("READYCAVCWNHAOD"), 22.days.ago, 22.days.ago, true)
    end

    def create_ama_hearing_held_aod_appeals(number_of_appeals_to_create, hearing_judge, appeal_affinity_start_date, receipt_date)
      number_of_appeals_to_create.times.each do
        create_ama_hearing_held_aod_appeal(hearing_judge, appeal_affinity_start_date, receipt_date)
      end
    end

    # AMA Hearing Held AOD appeal creation functions
    def create_ama_hearing_held_aod_appeal(hearing_judge, appeal_affinity_start_date, receipt_date)
      Timecop.travel(appeal_affinity_start_date)
      create(
        :appeal,
        :hearing_docket,
        :with_post_intake_tasks,
        :advanced_on_docket_due_to_age,
        :held_hearing_and_ready_to_distribute,
        :tied_to_judge,
        :with_appeal_affinity,
        veteran: create_veteran_for_ama_hearing_held_aod_judge,
        receipt_date: receipt_date,
        tied_judge: hearing_judge,
        adding_user: User.first
      )
      Timecop.return
    end

    def create_ready_cavc_appeals(number_of_appeals_to_create, tied_judge, created_date, affinity_start_date = nil, aod = false)
      number_of_appeals_to_create.times.each do
        create_ready_cavc_appeal(tied_judge: tied_judge, created_date: created_date, affinity_start_date: affinity_start_date, aod: aod)
      end
    end

    def create_ready_cavc_appeals_with_new_hearing(number_of_appeals_to_create, tied_judge, created_date, affinity_start_date = nil, aod = false)
      number_of_appeals_to_create.times.each do
        cavc_appeal = create_ready_cavc_appeal(tied_judge: tied_judge, created_date: created_date, affinity_start_date: affinity_start_date, aod: aod, with_new_hearing: true)
        create_most_recent_hearing(cavc_appeal, tied_judge)
      end
    end

    def create_ready_cavc_appeal(tied_judge: nil, created_date: 1.year.ago, aod: false, affinity_start_date: nil, with_new_hearing: false)
      Timecop.travel(created_date - 6.months)
      if tied_judge
        judge = tied_judge
        attorney = JudgeTeam.for_judge(judge)&.attorneys&.first || create(:user, :with_vacols_attorney_record)
      else
        judge = create(:user, :judge, :with_vacols_judge_record)
        attorney = create(:user, :with_vacols_attorney_record)
      end

      source_appeal = create(
        :appeal,
        :hearing_docket,
        :held_hearing,
        :tied_to_judge,
        :dispatched,
        # associated_judge and tied_judge are both required to satisfy different traits
        associated_judge: judge,
        associated_attorney: attorney,
        tied_judge: judge,
        veteran: with_new_hearing ? create_veteran_for_ready_cavc_appeal_with_new_hearing_held : create_veteran_for_ready_cavc_appeal
      )

      Timecop.travel(6.months.from_now)

      cavc_remand = create(
        :cavc_remand,
        source_appeal: source_appeal
      )
      remand_appeal = cavc_remand.remand_appeal
      distribution_tasks = remand_appeal.tasks.select { |task| task.is_a?(DistributionTask) }
      (distribution_tasks.flat_map(&:descendants) - distribution_tasks).each(&:completed!)
      create(:appeal_affinity, appeal: remand_appeal, affinity_start_date: affinity_start_date || Time.zone.now)
      Timecop.return

      create_aod_motion(remand_appeal, remand_appeal.claimant.person) if aod

      remand_appeal
    end

    def create_aod_motion(appeal, person)
      create(
        :advance_on_docket_motion,
        appeal: appeal,
        granted: true,
        person: person,
        reason: Constants.AOD_REASONS.financial_distress,
        user_id: User.system_user.id
      )
    end

    def create_most_recent_hearing(appeal, judge)
      most_recent = create(:hearing_day, scheduled_for: 1.day.ago)
      hearing = create(:hearing, judge: nil, disposition: "held", appeal: appeal, hearing_day: most_recent)
      hearing.update!(judge: judge)
    end

    def create_veteran_for_ama_hearing_held_aod_judge
      @ama_hearing_held_aod_file_number += 1
      @ama_hearing_held_aod_participant_id += 1
      create_veteran(
        file_number: @ama_hearing_held_aod_file_number,
        participant_id: @ama_hearing_held_aod_participant_id
      )
    end

    def create_veteran_for_ready_cavc_appeal
      @ready_cavc_file_number += 1
      @ready_cavc_participant_id += 1
      create_veteran(
        file_number: @ready_cavc_file_number,
        participant_id: @ready_cavc_participant_id
      )
    end

    def create_veteran_for_ready_cavc_appeal_with_new_hearing_held
      @ready_cavc_file_number += 1
      @ready_cavc_participant_id += 1
      create_veteran(
        file_number: @ready_cavc_file_number,
        participant_id: @ready_cavc_participant_id
      )
    end

    # Functions for Initialization
    def initialize_ama_hearing_held_aod_file_number_and_participant_id
      @ama_hearing_held_aod_file_number ||= 802_000_200
      @ama_hearing_held_aod_participant_id ||= 812_000_000

      while find_veteran(@ama_hearing_held_aod_file_number)
        @ama_hearing_held_aod_file_number += 2000
        @ama_hearing_held_aod_participant_id += 2000
      end
    end

    def initialize_ready_cavc_file_number_and_participant_id
      @ready_cavc_file_number ||= 803_000_200
      @ready_cavc_participant_id ||= 813_000_000

      while find_veteran(@ready_cavc_file_number)
        @ready_cavc_file_number += 2000
        @ready_cavc_participant_id += 2000
      end
    end

    def initialize_ready_cavc_with_new_hearing_held_file_number_and_participant_id
      @ready_cavc_with_new_hearing_held_file_number ||= 804_000_200
      @ready_cavc_with_new_hearing_held_participant_id ||= 814_000_000

      while find_veteran(@ready_cavc_with_new_hearing_held_file_number)
        @ready_cavc_with_new_hearing_held_file_number += 2000
        @ready_cavc_with_new_hearing_held_participant_id += 2000
      end
    end

    # Functions of Judge Creation
    def find_or_create_judge(css_id, full_name)
      User.find_by_css_id(css_id) ||
        create(:user, :judge, :with_vacols_judge_record, css_id: css_id, full_name: full_name)
    end

    def find_judge(css_id)
      User.find_by_css_id(css_id)
    end

    def find_veteran(file_number)
      Veteran.find_by(file_number: format("%<n>09d", n: file_number + 1))
    end

    def create_veteran(options = {})
      params = {
        file_number: format("%<n>09d", n: options[:file_number]),
        participant_id: format("%<n>09d", n: options[:participant_id])
      }
      Veteran.find_by_participant_id(params[:participant_id]) || create(:veteran, params.merge(options))
    end
  end
end
