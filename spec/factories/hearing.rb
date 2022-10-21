# frozen_string_literal: true

FactoryBot.define do
  factory :hearing do
    transient do
      regional_office { nil }
      adding_user { create(:user) }
    end
    appeal { association(:appeal, :hearing_docket) }
    judge { create(:user, roles: ["Hearing Prep"]) }
    uuid { SecureRandom.uuid }
    hearing_day do
      association(
        :hearing_day,
        regional_office: regional_office,
        scheduled_for: Time.zone.today,
        judge: judge,
        request_type: regional_office.nil? ? "C" : "V",
        created_by: adding_user,
        updated_by: adding_user
      )
    end
    hearing_location do
      if regional_office.present?
        association(:hearing_location, regional_office: regional_office)
      end
    end
    scheduled_time { "8:30AM" }
    created_by { adding_user }
    updated_by { adding_user }
    virtual_hearing { nil }

    # this trait creates a realistic hearing task tree from a completed hearing, but if it needs to
    # be ready for distribution then the referring class must mark the transcription/evidence
    # tasks complete and set the distribution task to assigned
    trait :held do
      disposition { Constants.HEARING_DISPOSITION_TYPES.held }
      after(:create) do |hearing, _evaluator|
        appeal = hearing.appeal
        hearing_task = appeal.tasks.find_by(type: :HearingTask)
        if hearing_task.nil?
          appeal.create_tasks_on_intake_success!
          hearing_task = appeal.tasks.find_by(type: :HearingTask)
        end
        # if a specific date was passed to the created appeal, this will match task dates to that date
        appeal.tasks.each { |task| task.update!(created_at: appeal.created_at, assigned_at: appeal.created_at) }
        create(:hearing_task_association,
               hearing: hearing,
               hearing_task: hearing_task)
        appeal.tasks.find_by(type: :ScheduleHearingTask).completed!
        assign_hearing_disposition_task = create(:assign_hearing_disposition_task,
                                                 :completed,
                                                 parent: hearing_task,
                                                 appeal: appeal)
        appeal.tasks.find_by(type: :DistributionTask).update!(status: :on_hold)
        assign_hearing_disposition_task.hold!
      end
    end

    trait :postponed do
      disposition { Constants.HEARING_DISPOSITION_TYPES.postponed }
    end

    trait :no_show do
      disposition { Constants.HEARING_DISPOSITION_TYPES.no_show }
    end

    trait :scheduled_in_error do
      disposition { Constants.HEARING_DISPOSITION_TYPES.scheduled_in_error }
    end

    trait :cancelled do
      disposition { Constants.HEARING_DISPOSITION_TYPES.cancelled }
    end

    trait :with_tasks do
      after(:create) do |hearing, _evaluator|
        create(:hearing_task_association,
               hearing: hearing,
               hearing_task: create(:hearing_task, appeal: hearing.appeal))
        create(:assign_hearing_disposition_task,
               parent: hearing.hearing_task_association.hearing_task,
               appeal: hearing.appeal)
      end
    end

    # Create a video hearing, AKA a hearing on a video hearing_day, that's not virtual
    trait :video do
      after(:create) do |hearing, _evaluator|
        hearing.hearing_day.request_type = "V"
      end
    end

    # Create a virtual hearing on a video hearing_day
    trait :virtual do
      after(:create) do |hearing, _evaluator|
        hearing.hearing_day.request_type = "V"
        hearing.virtual_hearing = create(:virtual_hearing)
      end
    end

    # A better representation of a hearing subtree:
    # RootTask, on_hold
    #   DistributionTask, on_hold
    #     HearingTask, assigned
    #       ScheduleHearingTask, completed
    #       AssignHeringDispositionTask, completed
    trait :with_completed_tasks do
      after(:create) do |hearing, _evaluator|
        dist_task = DistributionTask.create!(appeal: hearing.appeal, parent: hearing.appeal.root_task)
        create(:hearing_task_association,
               hearing: hearing,
               hearing_task: create(:hearing_task, appeal: hearing.appeal, parent: dist_task))
        create(:schedule_hearing_task,
               :completed,
               parent: hearing.hearing_task_association.hearing_task,
               appeal: hearing.appeal)
        create(:assign_hearing_disposition_task,
               :completed,
               parent: hearing.hearing_task_association.hearing_task,
               appeal: hearing.appeal)
      end
    end
  end
end
