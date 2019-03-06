# frozen_string_literal: true

class Generators::LegacyAppeal
  extend Generators::Base

  class << self
    def default_attrs
      {
        vbms_id: generate_external_id,
        vacols_id: generate_external_id,
        vacols_record: :ready_to_certify,
        manifest_vbms_fetched_at: Time.zone.now,
        manifest_vva_fetched_at: Time.zone.now
      }
    end

    # rubocop:disable Metrics/MethodLength
    def vacols_record_default_attrs
      last_name = generate_last_name

      {
        type: "Original",
        file_type: "VBMS",
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
        appellant_city: "Huntingdon",
        appellant_state: "TN",
        docket_number: 4198,
        case_record: OpenStruct.new(representatives: [OpenStruct.new(reptype: "C")])
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
          status: "Advance",
          certification_date: 1.day.ago
        },
        activated: {
          status: "Active",
          certification_date: 4.days.ago,
          case_review_date: 1.day.ago
        },
        form9_not_submitted: {
          status: "Advance",
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
            { disposition: :nil,
              vacols_sequence_id: 1 }
          ]
        },
        remand_decided: {
          status: "Remand",
          disposition: "Remanded",
          decision_date: 7.days.ago,
          docket_number: "13 12-225",
          issues: [
            { disposition: :remanded,
              readable_disposition: "Remanded",
              close_date: 7.days.ago,
              vacols_sequence_id: 1 },
            { disposition: :denied,
              readable_disposition: "Denied",
              close_date: 7.days.ago,
              vacols_sequence_id: 2 }
          ]
        },
        partial_grant_decided: {
          status: "Remand",
          disposition: "Allowed",
          decision_date: 7.days.ago,
          docket_number: "13 11-263",
          issues: [
            { disposition: :remanded,
              vacols_sequence_id: 1 },
            { disposition: :allowed,
              vacols_sequence_id: 2 },
            { disposition: :denied,
              vacols_sequence_id: 3 }
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
            { disposition: :allowed },
            { disposition: :denied }
          ]
        },
        remand_completed: {
          status: "Complete",
          disposition: "Allowed"
        },
        ramp_closed: {
          type: "Original",
          status: "Complete",
          disposition: "RAMP Opt-in",
          decision_date: 7.days.ago
        },

        veteran_is_appellant: {
          # A quirk in our model: These fields are
          # only set when the appellant is not the veteran.
          appellant_first_name: nil,
          appellant_last_name: nil,
          appellant_middle_initial: nil,
          appellant_relationship: nil
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
    # Generators::LegacyAppeal.build(vacols_record: :remand_decided)
    #
    # # Sets vacols_record with a custom first name + the defaults
    # Generators::LegacyAppeal.build({veteran_first_name: "Marky"})
    #
    # # Sets vacols_record with a custom decision_date + :remand_decided template + defaults
    # Generators::LegacyAppeal.build(vacols_record: {template: :remand_decided, decision_date: 1.day.ago})
    #
    def build(attrs = {})
      attrs = default_attrs.merge(attrs)
      vacols_record = extract_vacols_record(attrs)
      appeal = LegacyAppeal.find_or_initialize_by(vacols_id: attrs[:vacols_id])
      inaccessible = attrs.delete(:inaccessible)
      veteran = attrs.delete(:veteran)

      cast_datetime_fields(attrs)
      setup_vbms_documents(attrs)
      set_vacols_issues(appeal: appeal, vacols_record: vacols_record, attrs: attrs)

      non_vacols_attrs = attrs.reject { |attr| LegacyAppeal.vacols_field?(attr) }
      appeal.attributes = non_vacols_attrs

      add_inaccessible_appeal(appeal) if inaccessible
      veteran || Generators::Veteran.build(file_number: appeal.sanitized_vbms_id)

      appeal
    end

    private

    def setup_vbms_documents(attrs)
      documents = attrs.delete(:documents)
      Fakes::VBMSService.document_records ||= {}
      Fakes::VBMSService.document_records[attrs[:vbms_id]] = documents

      Fakes::VBMSService.manifest_vbms_fetched_at = attrs.delete(:manifest_vbms_fetched_at)
      Fakes::VBMSService.manifest_vva_fetched_at = attrs.delete(:manifest_vva_fetched_at)
    end

    def set_vacols_issues(appeal:, vacols_record:, attrs:)
      issues = attrs.delete(:issues)
      issues_from_template = vacols_record.delete(:issues)
      issues ||= issues_from_template

      appeal.issues = (issues || []).map do |issue|
        issue.is_a?(Hash) ? Generators::Issue.build(issue) : issue
      end
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
