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

    # rubocop:enable Metrics/MethodLength

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
      attrs = convert_old_generator_keys(attrs)
      attrs = default_attrs.merge(attrs)

      # Setting up vacols data must come prior to creating appeal so
      # appeal code picks up the persisted data.
      vacols_case = setup_vacols_data(attrs)

      setup_vbms_documents(attrs)
      setup_bgs_data(attrs)

      LegacyAppeal.find_or_initialize_by(vacols_id: vacols_case[:bfkey])
    end

    private

    def convert_old_generator_keys(attrs)
      case_record = {}
      correspondent_record = {}

      case_record[:bfac] = VACOLS::Case::TYPES.invert[attrs.delete(:type)]
      case_record[:bfpdnum] = attrs.delete(:insurance_loan_number)
      case_record[:bfdrodec] = attrs.delete(:notification_date)
      case_record[:bfdnod] = attrs.delete(:nod_date)
      case_record[:bfdsoc] = attrs.delete(:soc_date)
      case_record[:bfd19] = attrs.delete(:form9_date)

      case_record[:bfhr] = VACOLS::Case::HEARING_REQUEST_TYPES.invert[attrs.delete(:hearing_request_type)]
      case_record[:bfdocind] = "V" if attrs.delete(:video_hearing_requested)
      case_record[:bfhr] = "1" if attrs.delete(:hearing_requested)
      case_record[:bfha] = "Y" if attrs.delete(:hearing_held)
      case_record[:bfregoff] = attrs.delete(:regional_office_key)
      case_record[:bf41stat] = attrs.delete(:certification_date)

      case_record[:bfdc] = Constants::VACOLS_DISPOSITIONS_BY_ID.invert[attrs.delete(:disposition)]
      case_record[:bfcurloc] = attrs.delete(:location_code)
      case_record[:bfddec] = attrs.delete(:decision_date)
      case_record[:bfdpdcn] = attrs.delete(:prior_decision_date)
      case_record[:bfmpro] = VACOLS::Case::STATUS.invert[attrs.delete(:status)]
      case_record[:bfdloout] = attrs.delete(:last_location_change_date)
      case_record[:bfso] = "T" if attrs.delete(:private_attorney_or_agent)
      case_record[:reptype] = "C" if attrs.delete(:contested_claim)

      case_record[:reptype] = "C" if attrs.delete(:contested_claim)

      attrs.delete(:ssoc_dates).each_with_index do |date, i|
        case_record["bfssoc#{i+1}".to_sym] = date
      end

      correspondent_record[:snamef] = attrs.delete(:veteran_first_name)
      correspondent_record[:snamel] = attrs.delete(:veteran_last_name)
      correspondent_record[:snamemi] = attrs.delete(:veteran_middle_initial)
      correspondent_record[:sdob] = attrs.delete(:veteran_date_of_birth)
      correspondent_record[:sgender] = attrs.delete(:veteran_gender)

      correspondent_record[:sspare1] = attrs.delete(:appellant_first_name)
      correspondent_record[:sspare2] = attrs.delete(:appellant_middle_initial)
      correspondent_record[:sspare3] = attrs.delete(:appellant_last_name)
      correspondent_record[:susrtyp] = attrs.delete(:appellant_relationship)

      correspondent_record[:ssn] = attrs.delete(:appellant_ssn)
      correspondent_record[:saddrst1] = attrs.delete(:appellant_address_line_1)
      correspondent_record[:saddrst2] = attrs.delete(:appellant_address_line_2)
      correspondent_record[:saddrcty] = attrs.delete(:appellant_city)
      correspondent_record[:saddrstt] = attrs.delete(:appellant_state)
      correspondent_record[:saddrcnty] = attrs.delete(:appellant_country)
      correspondent_record[:saddrzip] = attrs.delete(:appellant_zip)

      return attrs.merge({
        case_attrs: case_record,
        correspondent_attrs: correspondent_record
      })
      # file_type: folder_type_from(folder_record),
      # representative: VACOLS::Case::REPRESENTATIVES[case_record.bfso][:full_name],

      # outcoder_first_name: outcoder_record.try(:snamef),
      # outcoder_last_name: outcoder_record.try(:snamel),
      # outcoder_middle_initial: outcoder_record.try(:snamemi),
      # case_review_date: folder_record.tidktime,
      # outcoding_date: normalize_vacols_date(folder_record.tioctime),
      
      # docket_number: folder_record.tinum
    end

    def setup_bgs_data(attrs)
      attrs.delete(:veteran) || Generators::Veteran.build(file_number: attrs[:vbms_id])

      add_inaccessible_appeal(attrs[:vbms_id]) if attrs.delete(:inaccessible)
    end

    def add_inaccessible_appeal(vbms_id)
      Fakes::BGSService.inaccessible_appeal_vbms_ids ||= []
      Fakes::BGSService.inaccessible_appeal_vbms_ids << vbms_id
    end

    def setup_vacols_data(attrs)
      default_case_attrs = { 
        case_attrs: {
          bfkey: attrs[:vacols_id], bfcorlid: attrs[:vbms_id]
        }
      }

      Generators::Vacols::Case.create(
        default_case_attrs.merge(
          attrs
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
