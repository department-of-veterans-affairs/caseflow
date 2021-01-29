class AddCommentsToHearingsTable < ActiveRecord::Migration[5.2]
  def change
  	# hearings
  	change_column_comment :hearings, :appeal_id, "Appeal ID; use as FK to appeals"
  	change_column_comment :hearings, :bva_poc, "Hearing coordinator full name"
  	change_column_comment :hearings, :disposition, "Hearing disposition; can be one of: 'held', 'postponed', 'no_show', or 'cancelled'"
  	change_column_comment :hearings, :evidence_window_waived, "Determines whether the veteran/appelant has wavied the 90 day evidence hold"
  	change_column_comment :hearings, :hearing_day_id, "HearingDay ID; use as FK to HearingDays"
  	change_column_comment :hearings, :judge_id, "User ID of judge who will hold the hearing"
  	change_column_comment :hearings, :military_service, "Periods and circumstances of military service"
  	change_column_comment :hearings, :notes, "Any notes taken prior or post hearing"
  	change_column_comment :hearings, :prepped, "Determines whether the judge has checked the hearing as prepped"
  	change_column_comment :hearings, :representative_name, "Name of Appellant's representative if applicable"
  	change_column_comment :hearings, :room, "The room at BVA where the hearing will take place; ported from associated HearingDay"
  	change_column_comment :hearings, :scheduled_time, "Date and Time when hearing will take place"
  	change_column_comment :hearings, :summary, "Summary of hearing"
  	change_column_comment :hearings, :transcript_requested, "Determines whether the veteran/appellant has requested the hearing transcription"
  	change_column_comment :hearings, :transcript_sent_date, "Date of when the hearing transcription was sent to the Veteran/Appellant"
  	change_column_comment :hearings, :witness, "Witness/Observer present during hearing"

  	# legacy_hearings
  	change_column_comment :legacy_hearings, :appeal_id, "LegacyAppeal ID; use as FK to legacy_appeals"
  	change_column_comment :legacy_hearings, :military_service, "Periods and circumstances of military service"
  	change_column_comment :legacy_hearings, :prepped, "Determines whether the judge has checked the hearing as prepped"
  	change_column_comment :legacy_hearings, :summary, "Summary of hearing"
  	change_column_comment :legacy_hearings, :user_id, "User ID of judge who will hold the hearing"
  	change_column_comment :legacy_hearings, :witness, "Witness/Observer present during hearing"

  	# hearing_days
  	change_column_comment :hearing_days, :bva_poc, "Hearing coordinator full name"
  	change_column_comment :hearing_days, :created_at, "Automatic timestamp of when hearing day was created"
  	change_column_comment :hearing_days, :deleted_at, "Automatic timestamp of when hearing day was deleted"
  	change_column_comment :hearing_days, :judge_id, "User ID of judge who is assigned to the hearing day"
  	change_column_comment :hearing_days, :lock, "Determines if the hearing day is locked and can't be edited"
  	change_column_comment :hearing_days, :notes, "Any notes about hearing day"
  	change_column_comment :hearing_days, :regional_office, "Regional office key associated with hearing day"
  	change_column_comment :hearing_days, :request_type, "Hearing request types for all associated hearings; can be one of: 'T', 'C' or 'V'"
  	change_column_comment :hearing_days, :scheduled_for, "The date when all associated hearings will take place"
  	change_column_comment :hearing_days, :updated_at, "Automatic timestamp of when hearing day was updated"

  	# hearing_locations
  	change_column_comment :hearing_locations, :address, "Full address of the location"
  	change_column_comment :hearing_locations, :city, "i.e 'New York', 'Houston', etc"
  	change_column_comment :hearing_locations, :classification, "The classification for location; i.e 'Regional Benefit Office', 'VA Medical Center (VAMC)', etc"
  	change_column_comment :hearing_locations, :created_at, "Automatic timestamp of when hearing location was created"
  	change_column_comment :hearing_locations, :distance, "Distance between appellant's location and the hearing location"
  	change_column_comment :hearing_locations, :facility_id, "Id associated with the facility; i.e 'vba_313', 'vba_354a', 'vba_317', etc"
  	change_column_comment :hearing_locations, :facility_type, "The type of facility; i.e, 'va_benefits_facility', 'va_health_facility', 'vet_center', etc"
  	change_column_comment :hearing_locations, :hearing_id, "Hearing/LegacyHearing ID; use as FK to hearings/legacy_hearings"
  	change_column_comment :hearing_locations, :hearing_type, "'Hearing' or 'LegacyHearing'"
  	change_column_comment :hearing_locations, :name, "Name of location; i.e 'Chicago Regional Benefit Office', 'Jennings VA Clinic', etc"
  	change_column_comment :hearing_locations, :state, "State in abbreviated form; i.e 'NY', 'CA', etc"
  	change_column_comment :hearing_locations, :updated_at, "Automatic timestamp of when hearing location was updated"

  	# available_hearing_locations
  	change_column_comment :available_hearing_locations, :address, "Full address of the location"
  	change_column_comment :available_hearing_locations, :appeal_id, "Appeal/LegacyAppeal ID; use as FK to appeals/legacy_appeals"
  	change_column_comment :available_hearing_locations, :appeal_type, "'Appeal' or 'LegacyAppeal'"
  	change_column_comment :available_hearing_locations, :city, "i.e 'New York', 'Houston', etc"
  	change_column_comment :available_hearing_locations, :classification, "The classification for location; i.e 'Regional Benefit Office', 'VA Medical Center (VAMC)', etc"
  	change_column_comment :available_hearing_locations, :created_at, "Automatic timestamp of when hearing location was created"
  	change_column_comment :available_hearing_locations, :distance, "Distance between appellant's location and the hearing location"
  	change_column_comment :available_hearing_locations, :facility_id, "Id associated with the facility; i.e 'vba_313', 'vba_354a', 'vba_317', etc"
  	change_column_comment :available_hearing_locations, :facility_type, "The type of facility; i.e, 'va_benefits_facility', 'va_health_facility', 'vet_center', etc"
  	change_column_comment :available_hearing_locations, :name, "Name of location; i.e 'Chicago Regional Benefit Office', 'Jennings VA Clinic', etc"
  	change_column_comment :available_hearing_locations, :state, "State in abbreviated form; i.e 'NY', 'CA', etc"
  	change_column_comment :available_hearing_locations, :updated_at, "Automatic timestamp of when hearing location was updated"
  	change_column_comment :available_hearing_locations, :veteran_file_number, "The VBA corporate file number of the Veteran for the appeal"

  	# transcriptions 
  	change_column_comment :transcriptions, :created_at, "Automatic timestamp of when transcription was created"
  	change_column_comment :transcriptions, :expected_return_date, "Expected date when transcription would be returned by the transcriber"
  	change_column_comment :transcriptions, :hearing_id, "Hearing ID; use as FK to hearings"
  	change_column_comment :transcriptions, :problem_notice_sent_date, "Date when notice of problem with recording was sent to appellant"
  	change_column_comment :transcriptions, :problem_type, "Any problem with hearing recording; could be one of: 'No audio', 'Poor Audio Quality', 'Incomplete Hearing' or 'Other (see notes)'"
  	change_column_comment :transcriptions, :requested_remedy, "Any remedy requested by the apellant for the recording problem; could be one of: 'Proceed without transcript', 'Proceed with partial transcript' or 'New hearing'"
  	change_column_comment :transcriptions, :sent_to_transcriber_date, "Date when the recording was sent to transcriber"
  	change_column_comment :transcriptions, :task_number, "Number associated with transcription"
  	change_column_comment :transcriptions, :transcriber, "Contractor who will transcribe the recording; i.e, 'Genesis Government Solutions, Inc.', 'Jamison Professional Services', etc"
  	change_column_comment :transcriptions, :updated_at, "Automatic timestamp of when transcription was updated"
  	change_column_comment :transcriptions, :uploaded_to_vbms_date, "Date when the hearing transcription was uploaded to VBMS"

  	# virtual_hearings
  	change_column_comment :virtual_hearings, :hearing_type, "'Hearing' or 'LegacyHearing'"
  	change_column_comment :virtual_hearings, :created_at, "Automatic timestamp of when virtual hearing was created"
  	change_column_comment :virtual_hearings, :updated_at, "Automatic timestamp of when virtual hearing was updated"

  	# sent_hearing_email_events
  	change_column_comment :sent_hearing_email_events, :hearing_type, "'Hearing' or 'LegacyHearing'"

  	# hearing_views
  	change_column_comment :hearing_views, :created_at, "Automatic timestamp of when hearing view was created"
  	change_column_comment :hearing_views, :hearing_id, "Hearing/LegacyHearing ID; use as FK to hearings/legacy_hearings"
  	change_column_comment :hearing_views, :hearing_type, "'Hearing' or 'LegacyHearing'"
  	change_column_comment :hearing_views, :updated_at, "Automatic timestamp of when hearing view was updated"
  	change_column_comment :hearing_views, :user_id, "User ID; use as FK to users"

  	# hearing_task_associations
  	change_column_comment :hearing_task_associations, :created_at, "Automatic timestamp of when association was created"
  	change_column_comment :hearing_task_associations, :hearing_id, "Hearing/LegacyHearing ID; use as FK to hearings/legacy_hearings"
  	change_column_comment :hearing_task_associations, :hearing_task_id, "associated HearingTask ID; use as fk to tasks"
  	change_column_comment :hearing_task_associations, :hearing_type, "'Hearing' or 'LegacyHearing'"
  	change_column_comment :hearing_task_associations, :updated_at, "Automatic timestamp of when association was updated"

  	# hearing_appeal_stream_snapshots
  	change_column_comment :hearing_appeal_stream_snapshots, :appeal_id, "LegacyAppeal ID; use as FK to legacy_appeals"
  	change_column_comment :hearing_appeal_stream_snapshots, :created_at, "Automatic timestamp of when snapshot was created"
  	change_column_comment :hearing_appeal_stream_snapshots, :hearing_id, "LegacyHearing ID; use as FK to legacy_hearings"
  	change_column_comment :hearing_appeal_stream_snapshots, :updated_at, "Automatic timestamp of when snapshot was updated"
  end
end
