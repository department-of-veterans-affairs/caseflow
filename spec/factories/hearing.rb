# frozen_string_literal: true

FactoryBot.define do
  factory :hearing do
    transient do
      regional_office { nil }
      adding_user { association(:user) }
    end
    appeal { association(:appeal, :hearing_docket) }
    judge { association(:user, roles: ["Hearing Prep"]) }
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

    trait :held do
      disposition { Constants.HEARING_DISPOSITION_TYPES.held }
      # TODO: add child tasks from assign_hearing_disposition_task here
      after(:create) do |hearing, _evaluator|
        appeal = hearing.appeal
        hearing_task = appeal.tasks.find_by(type: :HearingTask)
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
      # TODO: check if child tasks for these are being created
    end

    trait :no_show do
      disposition { Constants.HEARING_DISPOSITION_TYPES.no_show }
      # TODO: check if child tasks for these are being created
    end

    trait :scheduled_in_error do
      disposition { Constants.HEARING_DISPOSITION_TYPES.scheduled_in_error }
    end

    trait :cancelled do
      disposition { Constants.HEARING_DISPOSITION_TYPES.cancelled }
      # TODO: check if child tasks for these are being created
      # TODO: check if vacols needs to be updated here
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
        # TODO: add child tasks of assign_hearing_disposition_task here
      end
    end
  end
end
