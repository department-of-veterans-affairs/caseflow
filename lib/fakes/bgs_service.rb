class Fakes::BGSService
  cattr_accessor :end_product_data
  attr_accessor :client

  def self.all_grants
    [
      {
        benefit_claim_id: "1",
        claim_receive_date: Time.zone.now - 20.days,
        claim_type_code: "172GRANT",
        end_product_type_code: "172",
        status_type_code: "PEND"
      },
      {
        benefit_claim_id: "2",
        claim_receive_date: Time.zone.now + 10.days,
        claim_type_code: "170RMD",
        end_product_type_code: "170",
        status_type_code: "CLR"
      },
      {
        benefit_claim_id: "3",
        claim_receive_date: Time.zone.now,
        claim_type_code: "172BVAG",
        end_product_type_code: "172",
        status_type_code: "CAN"
      },
      {
        benefit_claim_id: "4",
        claim_receive_date: Time.zone.now - 200.days,
        claim_type_code: "172BVAG",
        end_product_type_code: "172",
        status_type_code: "CLR"
      },
      {
        benefit_claim_id: "5",
        claim_receive_date: Time.zone.now - 10.days,
        claim_type_code: "170APPACT",
        end_product_type_code: "170",
        status_type_code: "PEND"
      },
      {
        benefit_claim_id: "6",
        claim_receive_date: Time.zone.now - 200.days,
        claim_type_code: "170APPACTPMC",
        end_product_type_code: "171",
        status_type_code: "PEND"
      },
      {
        benefit_claim_id: "7",
        claim_receive_date: Time.zone.now - 10.days,
        claim_type_code: "170PGAMC",
        end_product_type_code: "170",
        status_type_code: "PEND"
      },
      {
        benefit_claim_id: "8",
        claim_receive_date: Time.zone.now - 10.days,
        claim_type_code: "170RMD",
        end_product_type_code: "170",
        status_type_code: "PEND"
      },
      {
        benefit_claim_id: "9",
        claim_receive_date: Time.zone.now - 10.days,
        claim_type_code: "170RMDAMC",
        end_product_type_code: "170",
        status_type_code: "PEND"
      },
      {
        benefit_claim_id: "10",
        claim_receive_date: Time.zone.now - 10.days,
        claim_type_code: "170RMDPMC",
        end_product_type_code: "170",
        status_type_code: "PEND"
      },
      {
        benefit_claim_id: "11",
        claim_receive_date: Time.zone.now - 10.days,
        claim_type_code: "172GRANT",
        end_product_type_code: "170",
        status_type_code: "PEND"
      },
      {
        benefit_claim_id: "12",
        claim_receive_date: Time.zone.now - 10.days,
        claim_type_code: "172BVAG",
        end_product_type_code: "170",
        status_type_code: "PEND"
      },
      {
        benefit_claim_id: "13",
        claim_receive_date: Time.zone.now - 10.days,
        claim_type_code: "172BVAGPMC",
        end_product_type_code: "170",
        status_type_code: "PEND"
      },
      {
        benefit_claim_id: "14",
        claim_receive_date: Time.zone.now - 10.days,
        claim_type_code: "400CORRC",
        end_product_type_code: "170",
        status_type_code: "PEND"
      },
      {
        benefit_claim_id: "15",
        claim_receive_date: Time.zone.now - 10.days,
        claim_type_code: "400CORRCPMC",
        end_product_type_code: "170",
        status_type_code: "PEND"
      },
      {
        benefit_claim_id: "16",
        claim_receive_date: Time.zone.now - 10.days,
        claim_type_code: "930RC",
        end_product_type_code: "170",
        status_type_code: "PEND"
      },
      {
        benefit_claim_id: "17",
        claim_receive_date: Time.zone.now - 10.days,
        claim_type_code: "930RCPMC",
        end_product_type_code: "170",
        status_type_code: "PEND"
      }
    ]
  end

  def self.existing_full_grants
    [
      {
        benefit_claim_id: "1",
        claim_receive_date: Time.zone.now - 20.days,
        claim_type_code: "172GRANT",
        end_product_type_code: "172",
        status_type_code: "PEND"
      }
    ]
  end

  def self.existing_partial_grants
    [
      {
        benefit_claim_id: "1",
        claim_receive_date: Time.zone.now + 10.days,
        claim_type_code: "170RMD",
        end_product_type_code: "170",
        status_type_code: "PEND"
      },
      {
        benefit_claim_id: "2",
        claim_receive_date: Time.zone.now + 10.days,
        claim_type_code: "170RMD",
        end_product_type_code: "171",
        status_type_code: "CLR"
      },
      {
        benefit_claim_id: "3",
        claim_receive_date: Time.zone.now - 200.days,
        claim_type_code: "170RMD",
        end_product_type_code: "175",
        status_type_code: "PEND"
      }
    ]
  end

  def self.no_grants
    []
  end

  def get_end_products(_veteran_id)
    end_product_data || no_grants
  end

  # rubocop:disable Metrics/MethodLength
  def fetch_veteran_info(_)
    {
      address_line1: "1234 FAKE ST",
      address_line2: nil,
      address_line3: nil,
      area_number_one: nil,
      area_number_two: nil,
      city: "BRISTOW",
      competency_decision_type_code: nil,
      country: "USA",
      cp_payment_address_line1: "219 WASHINGTON ST",
      cp_payment_address_line2: nil,
      cp_payment_address_line3: nil,
      cp_payment_city: "INDIANA",
      cp_payment_country: "USA",
      cp_payment_foreign_zip: nil,
      cp_payment_post_office_type_code: nil,
      cp_payment_postal_type_code: nil,
      cp_payment_state: "PA",
      cp_payment_zip_code: "15701",
      date_of_birth: "05/04/1955",
      debit_card_ind: "N",
      eft_account_number: nil,
      eft_account_type: nil,
      eft_routing_number: nil,
      email_address: nil,
      fiduciary_decision_category_type_code: nil,
      fiduciary_folder_location: nil,
      file_number: "111223334",
      first_name: "Kat",
      foreign_code: nil,
      last_name: "Stevens",
      middle_name: nil,
      military_post_office_type_code: nil,
      military_postal_type_code: nil,
      org_name: nil,
      org_title: nil,
      org_type: nil,
      phone_number_one: nil,
      phone_number_two: nil,
      phone_type_name_one: nil,
      phone_type_name_two: nil,
      prep_phrase_type: nil,
      province_name: nil,
      ptcpnt_id: "124443",
      ptcpnt_relationship: nil,
      return_code: "SHAR 9999",
      return_message: "Records found.",
      salutation_name: nil,
      sensitive_level_of_record: "0",
      ssn: "111223334",
      state: "VA",
      suffix_name: nil,
      temporary_custodian_indicator: nil,
      territory_name: nil,
      treasury_mailing_address_line1: "Kat Stevens",
      treasury_mailing_address_line2: "1234 FAKE ST",
      treasury_mailing_address_line3: "BRISTOW VA",
      treasury_mailing_address_line4: nil,
      treasury_mailing_address_line5: nil,
      treasury_mailing_address_line6: nil,
      treasury_payment_address_line1: nil,
      treasury_payment_address_line2: nil,
      treasury_payment_address_line3: nil,
      treasury_payment_address_line4: nil,
      treasury_payment_address_line5: nil,
      treasury_payment_address_line6: nil,
      zip_code: "20136",
      power_of_atty_code1: "0",
      power_of_atty_code2: "00",
      sex: "F"
    }
  end
end
