class Fakes::BGSService
  include PowerOfAttorneyMapper
  include AddressMapper

  cattr_accessor :end_product_records
  cattr_accessor :inaccessible_appeal_vbms_ids
  cattr_accessor :veteran_records
  cattr_accessor :power_of_attorney_records
  cattr_accessor :address_records
  cattr_accessor :ssn_not_found
  attr_accessor :client

  ID_TO_RAISE_ERROR = "ERROR-ID".freeze

  # rubocop:disable Metrics/MethodLength
  def self.all_grants
    default_date = 10.days.ago.to_formatted_s(:short_date)
    [
      {
        benefit_claim_id: "1",
        claim_receive_date: 20.days.ago.to_formatted_s(:short_date),
        claim_type_code: "070BVAGR",
        end_product_type_code: "070",
        status_type_code: "PEND"
      },
      {
        benefit_claim_id: "2",
        claim_receive_date: default_date,
        claim_type_code: "070RMND",
        end_product_type_code: "070",
        status_type_code: "CLR"
      },
      {
        benefit_claim_id: "3",
        claim_receive_date: Time.zone.now.to_formatted_s(:short_date),
        claim_type_code: "070BVAGR",
        end_product_type_code: "071",
        status_type_code: "CAN"
      },
      {
        benefit_claim_id: "4",
        claim_receive_date: 200.days.ago.to_formatted_s(:short_date),
        claim_type_code: "070BVAGR",
        end_product_type_code: "072",
        status_type_code: "CLR"
      },
      {
        benefit_claim_id: "5",
        claim_receive_date: default_date,
        claim_type_code: "170APPACT",
        end_product_type_code: "170",
        status_type_code: "PEND"
      },
      {
        benefit_claim_id: "6",
        claim_receive_date: default_date,
        claim_type_code: "170APPACTPMC",
        end_product_type_code: "171",
        status_type_code: "PEND"
      },
      {
        benefit_claim_id: "7",
        claim_receive_date: default_date,
        claim_type_code: "170PGAMC",
        end_product_type_code: "170",
        status_type_code: "PEND"
      },
      {
        benefit_claim_id: "8",
        claim_receive_date: default_date,
        claim_type_code: "170RMD",
        end_product_type_code: "170",
        status_type_code: "PEND"
      },
      {
        benefit_claim_id: "9",
        claim_receive_date: default_date,
        claim_type_code: "170RMDAMC",
        end_product_type_code: "170",
        status_type_code: "PEND"
      },
      {
        benefit_claim_id: "10",
        claim_receive_date: default_date,
        claim_type_code: "170RMDPMC",
        end_product_type_code: "170",
        status_type_code: "PEND"
      },
      {
        benefit_claim_id: "11",
        claim_receive_date: default_date,
        claim_type_code: "070BVAGRARC",
        end_product_type_code: "170",
        status_type_code: "PEND"
      },
      {
        benefit_claim_id: "12",
        claim_receive_date: default_date,
        claim_type_code: "172BVAG",
        end_product_type_code: "170",
        status_type_code: "PEND"
      },
      {
        benefit_claim_id: "13",
        claim_receive_date: default_date,
        claim_type_code: "172BVAGPMC",
        end_product_type_code: "170",
        status_type_code: "PEND"
      },
      {
        benefit_claim_id: "14",
        claim_receive_date: default_date,
        claim_type_code: "400CORRC",
        end_product_type_code: "170",
        status_type_code: "PEND"
      },
      {
        benefit_claim_id: "15",
        claim_receive_date: default_date,
        claim_type_code: "400CORRCPMC",
        end_product_type_code: "170",
        status_type_code: "PEND"
      },
      {
        benefit_claim_id: "16",
        claim_receive_date: default_date,
        claim_type_code: "930RC",
        end_product_type_code: "170",
        status_type_code: "PEND"
      },
      {
        benefit_claim_id: "17",
        claim_receive_date: default_date,
        claim_type_code: "930RCPMC",
        end_product_type_code: "170",
        status_type_code: "PEND"
      }
    ]
  end
  # rubocop:enable Metrics/MethodLength

  def self.existing_full_grants
    [
      {
        benefit_claim_id: "1",
        claim_receive_date: 20.days.ago.to_formatted_s(:short_date),
        claim_type_code: "070BVAGR",
        end_product_type_code: "070",
        status_type_code: "PEND"
      }
    ]
  end

  # rubocop:disable Metrics/MethodLength
  def self.existing_partial_grants
    [
      {
        benefit_claim_id: "1",
        claim_receive_date: 10.days.ago.to_formatted_s(:short_date),
        claim_type_code: "070RMBVAGARC",
        end_product_type_code: "070",
        status_type_code: "PEND"
      },
      {
        benefit_claim_id: "2",
        claim_receive_date: 10.days.ago.to_formatted_s(:short_date),
        claim_type_code: "070RMBVAGARC",
        end_product_type_code: "071",
        status_type_code: "CLR"
      },
      {
        benefit_claim_id: "3",
        claim_receive_date: 200.days.ago.to_formatted_s(:short_date),
        claim_type_code: "070RMBVAGARC",
        end_product_type_code: "072",
        status_type_code: "PEND"
      }
    ]
  end
  # rubocop:enable Metrics/MethodLength

  def self.no_grants
    []
  end

  def self.power_of_attorney_records
    {
      "111225555" =>
        {
          file_number: "111225555",
          power_of_attorney:
            {
              legacy_poa_cd: "3QQ",
              nm: "Clarence Darrow",
              org_type_nm: "POA Attorney",
              ptcpnt_id: "ERROR-ID"
            },
          ptcpnt_id: "600085545"
        }
    }
  end

  def self.clean!
    self.ssn_not_found = false
    self.inaccessible_appeal_vbms_ids = []
    self.end_product_records = {}
  end

  def get_end_products(veteran_id)
    records = self.class.end_product_records || {}

    records[veteran_id] || records[:default] || []
  end

  def fetch_veteran_info(vbms_id)
    (self.class.veteran_records || {})[vbms_id]
  end

  def can_access?(vbms_id)
    !(self.class.inaccessible_appeal_vbms_ids || []).include?(vbms_id)
  end

  # TODO: add more test cases
  def fetch_poa_by_file_number(file_number)
    record = (self.class.power_of_attorney_records || {})[file_number]
    record ||= default_power_of_attorney_record

    get_poa_from_bgs_poa(record)
  end

  # TODO: add more test cases
  def find_address_by_participant_id(participant_id)
    fail Savon::Error if participant_id == ID_TO_RAISE_ERROR

    address = (self.class.address_records || {})[participant_id]
    address ||= default_address

    get_address_from_bgs_address(address)
  end

  def fetch_file_number_by_ssn(ssn)
    ssn_not_found ? nil : ssn
  end

  private

  def default_power_of_attorney_record
    {
      file_number: "633792224",
      power_of_attorney:
        {
          legacy_poa_cd: "3QQ",
          nm: "Clarence Darrow",
          org_type_nm: "POA Attorney",
          ptcpnt_id: "600153863"
        },
      ptcpnt_id: "600085544"
    }
  end

  # rubocop:disable Metrics/MethodLength
  def default_address
    {
      addrs_one_txt: "9999 MISSION ST",
      addrs_three_txt: "APT 2",
      addrs_two_txt: "UBER",
      city_nm: "SAN FRANCISCO",
      cntry_nm: "USA",
      efctv_dt: 15.days.ago.to_formatted_s(:short_date),
      jrn_dt: 15.days.ago.to_formatted_s(:short_date),
      jrn_lctn_id: "283",
      jrn_obj_id: "SHARE  - PCAN",
      jrn_status_type_cd: "U",
      jrn_user_id: "CASEFLOW1",
      postal_cd: "CA",
      ptcpnt_addrs_id: "15069061",
      ptcpnt_addrs_type_nm: "Mailing",
      ptcpnt_id: "600085544",
      shared_addrs_ind: "N",
      trsury_addrs_four_txt: "SAN FRANCISCO CA",
      trsury_addrs_one_txt: "Jamie Fakerton",
      trsury_addrs_three_txt: "APT 2",
      trsury_addrs_two_txt: "9999 MISSION ST",
      trsury_seq_nbr: "5",
      zip_prefix_nbr: "94103"
    }
  end
  # rubocop:enable Metrics/MethodLength
end
