class Generators::Appeal
  extend Generators::Base

  VACOLS_RECORD_TEMPLATES = {
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
    remand_decided: {
      status: "Remand",
      disposition: "Remanded",
      decision_date: 7.days.ago
    },
    partial_grant_decided: {
      status: "Remand",
      disposition: "Allowed",
      decision_date: 7.days.ago
    },
    full_grant_decided: {
      type: "Post Remand",
      status: "Complete",
      disposition: "Allowed",
      outcoding_date: 2.days.ago,
      decision_date: 7.days.ago
    }
  }.freeze

  class << self
    def default_attrs
      {
        vbms_id: generate_external_id,
        vacols_id: generate_external_id
      }
    end

    def vacols_record_default_attrs
      last_name = generate_last_name

      {
        type: "Original",
        file_type: "VBMS",
        representative: "Military Order of the Purple Heart",
        veteran_first_name: generate_first_name,
        veteran_middle_initial: "A",
        veteran_last_name: last_name,
        appellant_first_name: generate_first_name,
        appellant_middle_initial: "A",
        appellant_last_name: last_name,
        appellant_relationship: "Child",
        regional_office_key: "RO13",
        decision_date: 7.days.ago
      }
    end

    # Build an appeal and set up the correct faked data in AppealRepository
    # @attrs - the hash of arguments passed into `Appeal#new` with a few exceptions:
    #   - :vacols_record [Hash or Symbol] -
    #       Hash of the parsed values returned from AppealRepository from VACOLS or
    #       a symbol identifying the template used.
    #   - :documents [Array] - Array of `Document` objects returned from AppealsRepository from VBMS
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
      vacols_record = extract_vacols_record(attrs)

      attrs = default_attrs.merge(attrs)
      documents = attrs.delete(:documents)

      cast_datetime_fields(attrs)
      appeal = Appeal.new(attrs)

      vacols_record[:vbms_id] = appeal.vbms_id

      Fakes::AppealRepository.records ||= {}
      Fakes::AppealRepository.records[appeal.vacols_id] = vacols_record

      Fakes::AppealRepository.document_records ||= {}
      Fakes::AppealRepository.document_records[appeal.vbms_id] = documents

      appeal
    end

    private

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

      template = VACOLS_RECORD_TEMPLATES[template_key] || {}

      vacols_record_default_attrs.merge(template).merge(vacols_record)
    end
  end
end
