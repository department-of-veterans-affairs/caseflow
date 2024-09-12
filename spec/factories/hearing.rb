# frozen_string_literal: true

FactoryBot.define do
  factory :hearing do
    transient do
      regional_office { nil }
      adding_user do
        User.find_by(css_id: "HR_FCT_USER") ||
          create(:user, css_id: "HR_FCT_USER", full_name: "Hearing Factory AddingUser")
      end
    end
    appeal { association(:appeal, :hearing_docket) }
    judge do
      User.find_by(css_id: "HR_FCT_JUDGE") ||
        create(:user, css_id: "HR_FCT_JUDGE", full_name: "Hearing Factory JudgeUser", roles: ["Hearing Prep"])
    end
    uuid { SecureRandom.uuid }
    hearing_day do
      association(
        :hearing_day,
        regional_office: regional_office,
        scheduled_for: Time.zone.today,
        judge: judge,
        request_type: regional_office.nil? ? "C" : "V",
        created_by: adding_user || User.system_user,
        updated_by: adding_user || User.system_user
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

    scheduled_in_timezone { nil }

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
               hearing_task: hearing_task,
               hearing_task_id: hearing_task.id)

        assign_hearing_disposition_task = create(:assign_hearing_disposition_task,
                                                 parent: hearing_task,
                                                 appeal: appeal)
        appeal.tasks.find_by(type: :ScheduleHearingTask).completed!
        appeal.tasks.open.where(type: :DistributionTask).last.update!(status: :on_hold)
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

    trait :with_transcription_files do
      after(:create) do |hearing, _evaluator|
        hearing.meeting_type.update(service_name: "webex")
        s3_dirs = { ta: "transcript_audio", tr: "transcript_raw", tt: "transcript_text" }

        2.times do |count|
          { mp4: s3_dirs[:ta], mp3: s3_dirs[:ta], vtt: s3_dirs[:tr], rtf: s3_dirs[:tt] }.each do |file_type, dir|
            file_name = "#{hearing.docket_number}_#{hearing.id}_Hearing#{count == 1 ? '-2' : ''}.#{file_type}"
            TranscriptionFile.create!(
              hearing_id: hearing.id,
              hearing_type: "Hearing",
              file_name: file_name,
              file_type: file_type.to_s,
              docket_number: hearing.docket_number,
              file_status: "Successful upload (AWS)",
              date_upload_aws: Time.zone.today,
              aws_link: "vaec-appeals-caseflow-test/#{dir}/#{file_name}"
            )
          end
        end
      end
    end

    trait :with_webex_non_virtual_conference_link do
      after(:create) do |hearing, _evaluator|
        create(:webex_conference_link, hearing_id: hearing.id, hearing_type: "Hearing")
      end
    end
  end
end
