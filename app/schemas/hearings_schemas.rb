# frozen_string_literal: true

class HearingsSchemas
  class << self
    def update
      ControllerSchema.json do |s|
        s.nested :hearing,
                 optional: false,
                 nullable: false,
                 doc: "Hearing attributes to update" do |h| 
                   common_hearing_fields(h)

                   h.date :transcript_sent_date,
                          optional: true,
                          nullable: false,
                          doc: "The date the transcription was sent"
                   h.bool :evidence_window_waived,
                          optional: true,
                          nullable: true,
                          doc: "Whether or not the evidence submission window was waived for the hearing"
                   h.nested :hearing_issue_notes_attributes,
                            optional: true,
                            nullable: true,
                            doc: "Notes for a hearing issue",
                            &hearing_issue_notes
                   h.nested :transcription_attributes,
                            optional: true,
                            nullable: true,
                            doc: "Details about hearing transcription",
                            &transcription
                 end
        s.nested :advance_on_docket_motion,
                 optional: true,
                 nullable: false,
                 doc: "AOD associated with the case",
                 &advance_on_docket_motion
      end
    end

    def update_legacy
      ControllerSchema.json do |s|
        s.nested :hearing,
                 optional: false,
                 nullable: false,
                 doc: "Hearing attributes to update" do |h| 
                   common_hearing_fields(h)

                   h.date :scheduled_for,
                          optional: true,
                          nullable: false,
                          doc: "The datetime the hearing was scheduled for"
                   h.string :aod,
                            optional: true,
                            nullable: false,
                            doc: "The AOD status"
                 end
      end
    end

    private

    def common_hearing_fields(s)
      s.string :representative_name,
               optional: true,
               nullable: true,
               doc: "The name of the veteran's POA"
      s.string :witness,
               optional: true,
               nullable: true,
               doc: "The name of the witness of the hearing"
      s.string :military_service,
               optional: true,
               nullable: true,
               doc: "Notes regarding military service"
      s.string :summary,
               optional: true,
               nullable: true,
               doc: "Summary of hearing"
      s.string :notes,
               optional: true,
               nullable: true,
               doc: "Notes about hearing"
      s.string :disposition,
               optional: true,
               nullable: false,
               doc: "Disposition of hearing"
      s.integer :hold_open,
                optional: true,
                nullable: false,
                doc: "Number of days to hold case open for"
      s.bool :transcript_requested,
             optional: true,
             nullable: true,
             doc: "Whether or not a transcript was requested"
      s.bool :prepped,
             optional: true,
             nullable: true,
             doc: "Whether or not the case has been prepped by the judge"
      s.string :scheduled_time_string,
               optional: true,
               nullable: false,
               doc: "The time the hearing was scheduled"
      s.string :judge_id,
               optional: true,
               nullable: true,
               doc: "The judge associated with the hearing"
      s.string :room,
               optional: true,
               nullable: true,
               doc: "The room the hearing will take place in"
      s.string :bva_poc,
               optional: true,
               nullable: true,
               doc: "The point-of-contact at the BVA for this hearing"
      s.nested :hearing_location_attributes,
               optional: true,
               nullable: true,
               doc: "The hearing location of the hearing",
               &hearing_location
      s.nested :virtual_hearing_attributes,
               optional: true,
               nullable: true,
               doc: "Associated data for a virtual hearing",
               &virtual_hearing
    end

    def hearing_issue_notes
      proc do |s|
        s.integer :id,
                  optional: true,
                  nullable: false,
                  doc: "The ID of the issue note"
        s.bool :allow,
               optional: true,
               nullable: false,
               doc: "Whether or not the issue was allowed"
        s.bool :deny,
               optional: true,
               nullable: false,
               doc: "Whether or not the issue was denied"
        s.bool :remand,
               optional: true,
               nullable: false,
               doc: "Whether or not the issue was remanded"
        s.bool :dismiss,
               optional: true,
               nullable: false,
               doc: "Whether or not the issue was dismissed"
        s.bool :reopen,
               optional: true,
               nullable: false,
               doc: "Whether or not the issue was reopened"
        s.string :worksheet_notes,
                 optional: true,
                 nullable: true,
                 doc: "Notes from the hearings worksheet"
      end
    end

    def hearing_location
      proc do |s|
        s.string :city,
                 optional: true,
                 nullable: true,
                 doc: "The city of the hearing location"
        s.string :state,
                 optional: true,
                 nullable: true,
                 doc: "The state of the hearing location"
        s.string :address,
                 optional: true,
                 nullable: true,
                 doc: "The state of the hearing location"
        # facility_id is required, but enforced on the model level. Because we send empty
        # object to the API, this needs to be marked as optional.
        s.string :facility_id,
                 optional: true,
                 nullable: false,
                 doc: "The facility ID of the hearing location (defined externally by VA.gov)"
        s.string :facility_type,
                 optional: true,
                 nullable: true,
                 doc: "The facility type of the hearing location"
        s.string :classification,
                 optional: true,
                 nullable: true,
                 doc: "The classification of the facility"
        s.string :name,
                 optional: true,
                 nullable: false,
                 doc: "The name of the facility"
        s.float :distance,
                optional: true,
                nullable: false,
                doc: "The distance of the hearing location from the veteran"
        s.string :zip_code,
                 optional: true,
                 nullable: true,
                 doc: "The zip code of the hearing location"
      end
    end

    def transcription
      proc do |s|
        s.date :expected_return_date,
               optional: true,
               nullable: false
        s.date :problem_notice_sent_date,
               optional: true,
               nullable: false        
        s.string :problem_type,
                 optional: true,
                 nullable: false
        s.string :requested_remedy,
                 optional: true,
                 nullable: false
        s.date :sent_to_transcriber_date,
               optional: true,
               nullable: false
        s.string :task_number,
                 optional: true,
                 nullable: false
        s.string :transcriber,
                 optional: true,
                 nullable: false
        s.date :uploaded_to_vbms_date,
               optional: true,
               nullable: false
      end
    end

    def virtual_hearing
      proc do |s|
        s.string :appellant_email,
                 optional: true,
                 nullable: false,
                 doc: "The email address of the appellant/veteran"
        s.string :judge_email,
                 optional: true,
                 nullable: false,
                 doc: "The email address of the judge"
        s.string :representative_email,
                 optional: true,
                 nullable: false,
                 doc: "The email address of the representative"
        s.bool :request_cancelled,
               optional: true,
               nullable: false,
               doc: "If the request for a virtual hearing was cancelled"
        s.string :appellant_tz,
                 optional: true,
                 nullable: false,
                 doc: "The timezone of the appellant/veteran"
        s.string :representative_tz,
                 optional: true,
                 nullable: true,
                 doc: "The timezone of the representative"
      end
    end

    def advance_on_docket_motion
      proc do |s|
        s.integer :person_id,
                  optional: true,
                  nullable: false,
                  doc: "The person the AOD is being granted for"
        s.string :reason,
                 optional: true,
                 nullable: false,
                 doc: "The reason the AOD is being granted"
        s.bool :granted,
               optional: true,
               nullable: true,
               doc: "Whether or not the AOD was granted"
      end
    end
  end
end
