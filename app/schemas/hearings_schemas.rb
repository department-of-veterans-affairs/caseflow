# frozen_string_literal: true

class HearingsSchemas
  class << self
    def update
      ControllerSchema.json do |schema|
        schema.nested :hearing,
                      optional: false,
                      nullable: false,
                      doc: "Hearing attributes to update",
                      &ama_hearing_schema
        schema.nested :advance_on_docket_motion,
                      optional: true,
                      nullable: false,
                      doc: "AOD associated with the case",
                      &advance_on_docket_motion
      end
    end

    def update_legacy
      ControllerSchema.json do |schema|
        schema.nested :hearing,
                      optional: false,
                      nullable: false,
                      doc: "Hearing attributes to update",
                      &legacy_hearing_schema
      end
    end

    private

    def ama_hearing_schema
      proc do |schema|
        common_hearing_fields(schema)

        schema.date :transcript_sent_date,
                    optional: true,
                    nullable: false,
                    doc: "The date the transcription was sent"
        schema.bool :evidence_window_waived,
                    optional: true,
                    nullable: true,
                    doc: "Whether or not the evidence submission window was waived for the hearing"
        schema.nested :hearing_issue_notes_attributes,
                      array: true,
                      optional: true,
                      nullable: true,
                      doc: "Notes for a hearing issue",
                      &hearing_issue_notes
        schema.nested :transcription_attributes,
                      optional: true,
                      nullable: true,
                      doc: "Details about hearing transcription",
                      &transcription
      end
    end

    def legacy_hearing_schema
      proc do |schema|
        common_hearing_fields(schema)

        schema.date :scheduled_for,
                    optional: true,
                    nullable: false,
                    doc: "The datetime the hearing was scheduled for"
        schema.string :aod,
                      optional: true,
                      nullable: false,
                      doc: "The AOD status"
      end
    end

    def common_hearing_fields(schema)
      schema.string :representative_name,
                    optional: true,
                    nullable: true,
                    doc: "The name of the veteran's POA"
      schema.string :witness,
                    optional: true,
                    nullable: true,
                    doc: "The name of the witness of the hearing"
      schema.string :military_service,
                    optional: true,
                    nullable: true,
                    doc: "Notes regarding military service"
      schema.string :summary,
                    optional: true,
                    nullable: true,
                    doc: "Summary of hearing"
      schema.string :notes,
                    optional: true,
                    nullable: true,
                    doc: "Notes about hearing"
      schema.string :disposition,
                    optional: true,
                    nullable: false,
                    doc: "Disposition of hearing"
      schema.integer :hold_open,
                     optional: true,
                     nullable: false,
                     doc: "Number of days to hold case open for"
      schema.bool :transcript_requested,
                  optional: true,
                  nullable: true,
                  doc: "Whether or not a transcript was requested"
      schema.bool :prepped,
                  optional: true,
                  nullable: true,
                  doc: "Whether or not the case has been prepped by the judge"
      schema.string :scheduled_time_string,
                    optional: true,
                    nullable: false,
                    doc: "The time the hearing was scheduled"
      schema.string :judge_id,
                    optional: true,
                    nullable: true,
                    doc: "The judge associated with the hearing"
      schema.string :room,
                    optional: true,
                    nullable: true,
                    doc: "The room the hearing will take place in"
      schema.string :bva_poc,
                    optional: true,
                    nullable: true,
                    doc: "The point-of-contact at the BVA for this hearing"
      schema.nested :hearing_location_attributes,
                    optional: true,
                    nullable: true,
                    doc: "The hearing location of the hearing",
                    &hearing_location
      schema.nested :virtual_hearing_attributes,
                    optional: true,
                    nullable: true,
                    doc: "Associated data for a virtual hearing",
                    &virtual_hearing
    end

    def hearing_issue_notes
      proc do |schema|
        schema.integer :id,
                       optional: true,
                       nullable: false,
                       doc: "The ID of the issue note"
        schema.bool :allow,
                    optional: true,
                    nullable: false,
                    doc: "Whether or not the issue was allowed"
        schema.bool :deny,
                    optional: true,
                    nullable: false,
                    doc: "Whether or not the issue was denied"
        schema.bool :remand,
                    optional: true,
                    nullable: false,
                    doc: "Whether or not the issue was remanded"
        schema.bool :dismiss,
                    optional: true,
                    nullable: false,
                    doc: "Whether or not the issue was dismissed"
        schema.bool :reopen,
                    optional: true,
                    nullable: false,
                    doc: "Whether or not the issue was reopened"
        schema.string :worksheet_notes,
                      optional: true,
                      nullable: true,
                      doc: "Notes from the hearings worksheet"
      end
    end

    def hearing_location
      proc do |schema|
        schema.string :city,
                      optional: true,
                      nullable: true,
                      doc: "The city of the hearing location"
        schema.string :state,
                      optional: true,
                      nullable: true,
                      doc: "The state of the hearing location"
        schema.string :address,
                      optional: true,
                      nullable: true,
                      doc: "The state of the hearing location"
        # facility_id is required, but enforced on the model level. Because we send empty
        # object to the API, this needs to be marked as optional.
        schema.string :facility_id,
                      optional: true,
                      nullable: false,
                      doc: "The facility ID of the hearing location (defined externally by VA.gov)"
        schema.string :facility_type,
                      optional: true,
                      nullable: true,
                      doc: "The facility type of the hearing location"
        schema.string :classification,
                      optional: true,
                      nullable: true,
                      doc: "The classification of the facility"
        schema.string :name,
                      optional: true,
                      nullable: false,
                      doc: "The name of the facility"
        schema.float :distance,
                     optional: true,
                     nullable: false,
                     doc: "The distance of the hearing location from the veteran"
        schema.string :zip_code,
                      optional: true,
                      nullable: true,
                      doc: "The zip code of the hearing location"
      end
    end

    def transcription
      proc do |schema|
        schema.date :expected_return_date,
                    optional: true,
                    nullable: true
        schema.date :problem_notice_sent_date,
                    optional: true,
                    nullable: true
        schema.string :problem_type,
                      optional: true,
                      nullable: true
        schema.string :requested_remedy,
                      optional: true,
                      nullable: true
        schema.date :sent_to_transcriber_date,
                    optional: true,
                    nullable: true
        schema.string :task_number,
                      optional: true,
                      nullable: true
        schema.string :transcriber,
                      optional: true,
                      nullable: true
        schema.date :uploaded_to_vbms_date,
                    optional: true,
                    nullable: true
      end
    end

    def virtual_hearing
      proc do |schema|
        schema.string :appellant_email,
                      optional: true,
                      nullable: false,
                      doc: "The email address of the appellant/veteran"
        schema.string :judge_email,
                      optional: true,
                      nullable: true,
                      doc: "The email address of the judge"
        schema.string :representative_email,
                      optional: true,
                      nullable: true,
                      doc: "The email address of the representative"
        schema.bool :request_cancelled,
                    optional: true,
                    nullable: false,
                    doc: "If the request for a virtual hearing was cancelled"
        schema.string :appellant_tz,
                      optional: true,
                      nullable: false,
                      doc: "The timezone of the appellant/veteran"
        schema.string :representative_tz,
                      optional: true,
                      nullable: true,
                      doc: "The timezone of the representative"
      end
    end

    def advance_on_docket_motion
      proc do |schema|
        schema.integer :person_id,
                       optional: true,
                       nullable: false,
                       doc: "The person the AOD is being granted for"
        schema.string :reason,
                      optional: true,
                      nullable: false,
                      doc: "The reason the AOD is being granted"
        schema.bool :granted,
                    optional: true,
                    nullable: true,
                    doc: "Whether or not the AOD was granted"
      end
    end
  end
end
