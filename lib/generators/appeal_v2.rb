class Generators::AppealV2
  extend Generators::Base

  # Experimental class to replace existing generators with ones that
  # do not interact with fake repositories but that persist data to
  # mocked external sources such as FACOLS.
  #
  # All data for Fake VACOLS - aka FACOLS - is persisted to the Oracle
  # database and pulled into the app through the normal application code
  # rather than the fake repo.
  #
  # OAR - 04/12/2018

  class << self
    def default_attrs
      {
        vbms_id: generate_external_id,
        vacols_id: generate_external_id,
        manifest_vbms_fetched_at: Time.zone.now,
        manifest_vva_fetched_at: Time.zone.now
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

      # Setting up vacols data must come prior to creating appeal so
      # appeal code picks up the persisted data.
      vacols_case = setup_vacols_data(attrs)

      appeal = Appeal.find_or_initialize_by(vacols_id: vacols_case[:bfkey])

      inaccessible = attrs.delete(:inaccessible)
      veteran = attrs.delete(:veteran)

      setup_vbms_documents(attrs)

      add_inaccessible_appeal(appeal) if inaccessible
      veteran || Generators::Veteran.build(file_number: attrs[:vbms_id])

      appeal
    end

    private

    def setup_vacols_data(attrs)
      Generators::Vacols::Case.create(
        attrs.merge(
          case_attrs: {
            bfkey: attrs[:vacols_id], bfcorlid: attrs[:vbms_id]
          }
        )
      )
    end

    def setup_vbms_documents(attrs)
      documents = attrs.delete(:documents)
      Fakes::VBMSService.document_records ||= {}
      Fakes::VBMSService.document_records[attrs[:vbms_id]] = documents

      Fakes::VBMSService.manifest_vbms_fetched_at = attrs.delete(:manifest_vbms_fetched_at)
      Fakes::VBMSService.manifest_vva_fetched_at = attrs.delete(:manifest_vva_fetched_at)
    end

    def add_inaccessible_appeal(appeal)
      Fakes::BGSService.inaccessible_appeal_vbms_ids ||= []
      Fakes::BGSService.inaccessible_appeal_vbms_ids << appeal.sanitized_vbms_id
    end
  end
end
