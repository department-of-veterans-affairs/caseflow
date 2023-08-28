# frozen_string_literal: true

class Generators::LegacyAppealV2
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

    # Build an appeal with the corresponding data in VACOLS
    # @attrs - Different attributes to pass to the various data generators associated with an appeal.
    #   - :vacols_id [String] - Value to assign to the bfkey column. Defaults to a random id.
    #   - :vbms_id [String] - Value to assign to the bfcorlid column. Also used to associate
    #       VBMS test data with the VACOLS record. Defaults to a random id.
    #   - :documents [Array] - Array of `Document` objects returned from AppealsRepository from VBMS
    #   - :inaccessible [Boolean] - pass true and BGS will return that this appeal is
    #       not accessible by the current user
    #   - :case_attrs [Hash] - The hash of arguments passed into the VACOLS/case generator.
    #       Look at the generator for options.
    #   - :folder_attrs [Hash] - The hash of arguments passed into the VACOLS/folder generator.
    #       Look at the generator for options.
    #   - :representative_attrs [Hash] - The hash of arguments passed into the VACOLS/representative generator.
    #       Look at the generator for options.
    #   - :correspondent_attrs [Hash] - The hash of arguments passed into the VACOLS/correspondent generator.
    #       Look at the generator for options.
    #   - :note_attrs [Hash] - The hash of arguments passed into the VACOLS/note generator.
    #       Look at the generator for options.
    #   - :decass_attrs [Hash] - The hash of arguments passed into the VACOLS/decass generator.
    #       Look at the generator for options.
    #   - :case_issue_attrs [Array of Hashes] - The hash of arguments passed into the VACOLS/case_issue generator.
    #       Look at the generator for options.
    #   - :case_hearing_attrs [Array of Hashes] - The hash of arguments passed into the VACOLS/case_hearing generator.
    #       Look at the generator for options.
    #   - :staff_attrs [Hash] - The hash of arguments passed into the VACOLS/staff generator.
    #       Look at the generator for options.
    def build(attrs = {})
      attrs = default_attrs.merge(attrs)

      # Setting up vacols data must come prior to creating appeal so
      # appeal code picks up the persisted data.
      vacols_case = setup_vacols_data(attrs)

      setup_vbms_documents(attrs)
      setup_bgs_data(attrs)

      LegacyAppeal.find_or_initialize_by(vacols_id: vacols_case[:bfkey])
    end

    private

    def setup_bgs_data(attrs)
      attrs.delete(:veteran) || Generators::Veteran.build(file_number: attrs[:vbms_id])

      add_inaccessible_appeal(attrs[:vbms_id]) if attrs.delete(:inaccessible)
    end

    def add_inaccessible_appeal(vbms_id)
      Fakes::BGSService.inaccessible_appeal_vbms_ids ||= []
      Fakes::BGSService.inaccessible_appeal_vbms_ids << vbms_id
    end

    def setup_vacols_data(attrs)
      Generators::Vacols::Case.create(
        attrs.merge(
          decass_creation: true,
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
  end
end
