# frozen_string_literal: true

FactoryBot.define do
  factory :legacy_hearing do
    transient do
      regional_office { nil }
      disposition { nil }
      notes { nil }
      hearing_day do
        create(:hearing_day,
               regional_office: regional_office,
               request_type: regional_office.nil? ? "C" : "V")
      end
      adding_user { nil }
    end

    hearing_location do
      if regional_office.present?
        create(:hearing_location, regional_office: regional_office)
      end
    end

    scheduled_for { hearing_day&.scheduled_for }

    transient do
      case_hearing do
        create(
          :case_hearing,
          user: user,
          hearing_type: hearing_day.request_type,
          hearing_date: VacolsHelper.format_datetime_with_utc_timezone(scheduled_for),
          vdkey: hearing_day.id,
          hearing_disp: disposition
        )
      end
    end

    appeal do
      create(
        :legacy_appeal,
        :with_veteran,
        closest_regional_office: regional_office,
        vacols_case: create(
          :case_with_form_9,
          case_issues: [create(:case_issue), create(:case_issue)],
          bfregoff: regional_office,
          case_hearings: [case_hearing]
        )
      )
    end

    hearing_day_id { case_hearing.vdkey }
    vacols_id { case_hearing.hearing_pkseq }
    created_by do
      adding_user ||
        User.find_by_css_id("ID_FACT_LEGACYHEARING") ||
        create(:user, css_id: "ID_FACT_LEGACYHEARING", full_name: "Joe LegacyHearingFactory User")
    end
    updated_by do
      User.find_by_css_id("ID_FACT_LEGACYHEARING") ||
        create(:user, css_id: "ID_FACT_LEGACYHEARING", full_name: "Joe LegacyHearingFactory User")
    end
    virtual_hearing { nil }

    trait :with_tasks do
      after(:create) do |hearing, _evaluator|
        create(
          :hearing_task_association,
          hearing: hearing,
          hearing_task: create(:hearing_task, appeal: hearing.appeal)
        )
        create(
          :assign_hearing_disposition_task,
          parent: hearing.hearing_task_association.hearing_task,
          appeal: hearing.appeal
        )
      end
    end

    trait :for_vacols_case do
      case_hearing do
        create(
          :case_hearing,
          user: user,
          hearing_type: hearing_day.request_type,
          hearing_date: VacolsHelper.format_datetime_with_utc_timezone(scheduled_for),
          vdkey: hearing_day.id,
          hearing_disp: disposition,
          notes1: HearingMapper.notes_to_vacols_format(notes),
          folder_nr: appeal&.vacols_id
        )
      end
    end

    trait :with_transcription_files do
      after(:create) do |hearing, _evaluator|
        hearing.meeting_type.update(service_name: "webex")

        2.times do |count|
          %w[mp4 mp3 vtt rtf].each do |file_type|
            TranscriptionFile.create!(
              hearing_id: hearing.id,
              hearing_type: "LegacyHearing",
              file_name: "#{hearing.docket_number}_#{hearing.id}_LegacyHearing#{count == 1 ? '-2' : ''}.#{file_type}",
              file_type: file_type,
              docket_number: hearing.docket_number,
              file_status: "Successful upload (AWS)",
              date_upload_aws: Time.zone.today,
              aws_link: "www.test.com"
            )
          end
        end
      end
    end
  end
end
