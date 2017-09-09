class Generators::Appeal
  extend Generators::Base

  class << self
    def default_attrs
      {
        vbms_id: generate_external_id,
        vacols_id: generate_external_id,
        vacols_record: :ready_to_certify
      }
    end

    # rubocop:disable Metrics/MethodLength
    def vacols_record_default_attrs
      last_name = generate_last_name

      {
        type: "Original",
        file_type: "VBMS",
        representative: "Military Order of the Purple Heart",
        veteran_first_name: generate_first_name,
        veteran_middle_initial: "A",
        veteran_last_name: last_name,
        outcoder_first_name: generate_first_name,
        outcoder_middle_initial: "B",
        outcoder_last_name: generate_last_name,
        appellant_first_name: generate_first_name,
        appellant_middle_initial: "A",
        appellant_last_name: last_name,
        appellant_relationship: "Child",
        regional_office_key: "RO13",
        decision_date: 7.days.ago,
        form9_date: 11.days.ago,
        veteran_date_of_birth: 47.years.ago,
        appellant_city: "Huntingdon",
        appellant_state: "TN"
      }
    end
    # rubocop:enable Metrics/MethodLength

    # This is a method and not a constant because Datetime values need
    # to be evaluated lazily. Would be nice to have a better solution
    # rubocop:disable Metrics/MethodLength
    def vacols_record_templates
      {
        ready_to_certify: {
          status: "Advance",
          disposition: "Denied",
          # Check that this doesn't actually come through as a number type
          insurance_loan_number: "1234",
          notification_date: 1.day.ago,
          hearing_request_type: "Central office",
          regional_office_key: "DSUSER"
        },
        certified: {
          certification_date: 1.day.ago
        },
        form9_not_submitted: {
          decision_date: nil,
          form9_date: nil
        },
        pending_hearing: {
          status: "Active",
          decision_date: nil,
          nod_date: 1.month.ago,
          soc_date: 15.days.ago,
          ssoc_dates: [8.days.ago, 9.days.ago],
          issues: [
            { disposition: :nil, program: :compensation,
              vacols_sequence_id: 1,
              type: {
                name: :service_connection,
                label: "Service Connection"
              }, category: :knee }
          ]
        },
        remand_decided: {
          status: "Remand",
          disposition: "Remanded",
          decision_date: 7.days.ago,
          docket_number: "13 12-225",
          issues: [
            { disposition: :remanded, program: :compensation,
              type: {
                name: :service_connection,
                label: "Service Connection"
              }, category: :knee },
            { disposition: :denied, program: :compensation,
              type: {
                name: :service_connection,
                label: "Service Connection"
              }, category: :elbow }
          ]
        },
        partial_grant_decided: {
          status: "Remand",
          disposition: "Allowed",
          decision_date: 7.days.ago,
          docket_number: "13 11-263",
          issues: [
            { disposition: :remanded, program: :compensation,
              vacols_sequence_id: 1,
              type: {
                name: :service_connection,
                label: "Service Connection"
              }, category: :knee },
            { disposition: :allowed, program: :compensation,
              vacols_sequence_id: 2,
              type: {
                name: :service_connection,
                label: "Service Connection"
              }, category: :elbow },
            { disposition: :denied, program: :compensation,
              vacols_sequence_id: 3,
              type: {
                name: :service_connection,
                label: "Service Connection"
              }, category: :shoulder }
          ]
        },
        full_grant_decided: {
          type: "Post Remand",
          status: "Complete",
          disposition: "Allowed",
          outcoding_date: 2.days.ago,
          decision_date: 7.days.ago,
          docket_number: "13 11-265",
          issues: [
            { disposition: :allowed, program: :compensation,
              type: {
                name: :service_connection,
                label: "Service Connection"
              }, category: :elbow },
            { disposition: :denied, program: :compensation,
              type: {
                name: :service_connection,
                label: "Service Connection"
              }, category: :shoulder }
          ]
        }
      }
    end
    # rubocop:enable Metrics/MethodLength

    # Build an appeal and set up the correct faked data in AppealRepository
    # @attrs - the hash of arguments passed into `Appeal#new` with a few exceptions:
    #   - :vacols_record [Hash or Symbol] -
    #       Hash of the parsed values returned from AppealRepository from VACOLS or
    #       a symbol identifying the template used.
    #   - :documents [Array] - Array of `Document` objects returned from AppealsRepository from VBMS
    #   - :inaccessible [Boolean] - pass true and BGS will return that this appeal is
    #       not accessible by the current user
    #
    # Examples
    #
    # # Sets vacols_record to the :remand_decided template + defaults
    # Generators::Appeal.build(vacols_record: :remand_decided)
    #
    # # Sets vacols_record with a custom first name + the defaults
    # Generators::Appeal.build({veteran_first_name: "Marky"})
    #
    # # Sets vacols_record with a custom decision_date + :remand_decided template + defaults
    # Generators::Appeal.build(vacols_record: {template: :remand_decided, decision_date: 1.day.ago})
    #
    def build(attrs = {})
      attrs = default_attrs.merge(attrs)

      vacols_record = extract_vacols_record(attrs)
      documents = attrs.delete(:documents)
      issues = attrs.delete(:issues)
      cast_datetime_fields(attrs)
      inaccessible = attrs.delete(:inaccessible)

      appeal = Appeal.find_or_initialize_by(vacols_id: attrs[:vacols_id])

      vacols_record[:vbms_id] = attrs[:vbms_id]
      vacols_record = vacols_record.merge(attrs)

      issues_from_template = vacols_record.delete(:issues)
      set_vacols_issues(appeal: appeal,
                        issues: issues || issues_from_template)

      Fakes::AppealRepository.records ||= {}
      Fakes::AppealRepository.records[appeal.vacols_id] = vacols_record

      Fakes::VBMSService.document_records ||= {}
      Fakes::VBMSService.document_records[appeal.vbms_id] = documents

      add_inaccessible_appeal(appeal) if inaccessible

      appeal
    end

    private

    def set_vacols_issues(appeal:, issues:)
      appeal.issues = (issues || []).map do |issue|
        issue.is_a?(Hash) ? Generators::Issue.build(issue) : issue
      end

      Fakes::AppealRepository.issue_records ||= {}
      Fakes::AppealRepository.issue_records[appeal.vacols_id] = appeal.issues
    end

    def add_inaccessible_appeal(appeal)
      Fakes::BGSService.inaccessible_appeal_vbms_ids ||= []
      Fakes::BGSService.inaccessible_appeal_vbms_ids << appeal.sanitized_vbms_id
    end

    # Make sure Datetime fields are all casted correctly
    def cast_datetime_fields(attrs)
      [:nod_date, :soc_date, :form9_date].each do |date_field|
        attrs[date_field] = attrs[date_field].to_datetime if attrs[date_field]
      end
    end

    def extract_vacols_record(attrs)
      vacols_record = attrs.delete(:vacols_record)

      template_key, vacols_record = if vacols_record.is_a?(Hash)
                                      [vacols_record.delete(:template), vacols_record]
                                    else
                                      [vacols_record, {}]
                                    end

      template = vacols_record_templates[template_key] || {}
      vacols_record_default_attrs.merge(template).merge(vacols_record)
    end
  end
end
