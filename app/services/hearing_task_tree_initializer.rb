# frozen_string_literal: true

class HearingTaskTreeInitializer
  class << self
    # Initializes a task tree for an appeal with a pending travel board hearing.
    #
    # @note The tree is expected to look like:
    #                                        ┌────────────────────┐
    #   LegacyAppeal (legacy) ────────────── │ STATUS   │ ASGN_TO │
    #   └─RootTask                           │ on_hold  │ Bva     │
    #     └─HearingTask                      │ on_hold  │ Bva     │
    #       └─ScheduleHearingTask            │ on_hold  │ Bva     │
    #         └─ChangeHearingRequestTypeTask │ assigned │ Bva     │
    #                                        └────────────────────┘
    # @note This is in response to an initiative to reschedule travel board hearings due to
    #   COVID-19.
    # @note Travel board hearings are only available for legacy appeals.
    #
    # @param appeal [LegacyAppeal] the appeal to modify the task tree of
    #
    # @return       [LegacyAppeal]
    #   The legacy appeal with the new task tree
    def for_appeal_with_pending_travel_board_hearing(appeal)
      fail TypeError, "expected a legacy appeal" unless appeal.is_a?(LegacyAppeal)

      ActiveRecord::Base.multi_transaction do
        create_args = { appeal: appeal, assigned_to: Bva.singleton }

        root_task = RootTask.find_or_create_by!(**create_args)
        hearing_task = HearingTask.create!(**create_args, parent: root_task)
        schedule_hearing_task = ScheduleHearingTask.create!(**create_args, parent: hearing_task)
        ChangeHearingRequestTypeTask.create!(**create_args, parent: schedule_hearing_task)
      end

      appeal.reload
    end

    # Initializes schedule hearing tasks for all applicable legacy appeals.
    #
    # @note Moved from AppealRepository#create_schedule_hearing_tasks
    def create_schedule_hearing_tasks
      # Create legacy appeals where needed
      ids = cases_that_need_hearings.pluck(:bfkey, :bfcorlid)

      missing_ids = ids - LegacyAppeal.where(vacols_id: ids.map(&:first)).pluck(:vacols_id, :vbms_id)
      missing_ids.each do |id|
        LegacyAppeal.find_or_create_by!(vacols_id: id.first) do |appeal|
          appeal.vbms_id = id.second
        end
      end

      # Create the schedule hearing tasks
      LegacyAppeal.where(vacols_id: ids.map(&:first) - vacols_ids_with_schedule_tasks).each do |appeal|
        root_task = RootTask.find_or_create_by!(appeal: appeal, assigned_to: Bva.singleton)
        ScheduleHearingTask.create!(appeal: appeal, parent: root_task)

        AppealRepository.update_location!(appeal, LegacyAppeal::LOCATION_CODES[:caseflow])
      end
    end

    # Finds all cases in VACOLS that need a hearing scheduled.
    #
    # @note Moved from AppealRepository#cases_that_need_hearings
    #
    # @return       [Array<VACOLS::Case>]
    #   An array of VACOLS cases that need to have a hearing scheduled.
    def cases_that_need_hearings
      VACOLS::Case.where(bfhr: "1", bfcurloc: "57").or(VACOLS::Case.where(bfhr: "2", bfdocind: "V", bfcurloc: "57"))
        .joins(:folder).order("folder.tinum")
        .includes(:correspondent, :case_issues, :case_hearings, folder: [:outcoder]).reject do |case_record|
          case_record.case_hearings.any? do |hearing|
            # VACOLS contains non-BVA hearings information, we want to confirm the appeal has no scheduled BVA hearings
            hearing.hearing_disp.nil? && VACOLS::CaseHearing::HEARING_TYPES.include?(hearing.hearing_type)
          end
        end
    end

    private

    # Gets VACOLS ids for all appeals with schedule hearing tasks.
    #
    # @note Moved from AppealRepository#vacols_ids_with_schedule_tasks
    def vacols_ids_with_schedule_tasks
      ScheduleHearingTask.open.where(appeal_type: LegacyAppeal.name)
        .joins("LEFT JOIN legacy_appeals ON appeal_id = legacy_appeals.id")
        .select("legacy_appeals.vacols_id").pluck(:vacols_id).uniq
    end
  end
end
