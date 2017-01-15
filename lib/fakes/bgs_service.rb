class Fakes::BGSService
  cattr_accessor :end_product_data
  attr_accessor :client

  END_PRODUCTS =
    [
      {
        benefit_claim_id: "1",
        claim_receive_date: Time.zone.now - 20.days,
        claim_type_code: "172GRANT",
        status_type_code: "PEND"
      },
      {
        benefit_claim_id: "2",
        claim_receive_date: Time.zone.now + 10.days,
        claim_type_code: "170RMD",
        status_type_code: Dispatch::END_PRODUCT_STATUS.keys.sample
      },
      {
        benefit_claim_id: "3",
        claim_receive_date: Time.zone.now,
        claim_type_code: "172BVAG",
        status_type_code: Dispatch::END_PRODUCT_STATUS.keys.sample
      }
    ].freeze

  def get_end_products(_veteran_id)
    ep_data = [END_PRODUCTS[0], END_PRODUCTS[1], END_PRODUCTS[2]]
    10.times.each do |num|
      rand_ep = {
        benefit_claim_id: num.to_s,
        claim_receive_date: Time.zone.now - rand(0..10).days,
        claim_type_code: Dispatch::END_PRODUCT_CODES.keys.sample,
        status_type_code: Dispatch::END_PRODUCT_STATUS.keys.sample
      }
      ep_data.push(rand_ep)
    end
    end_product_data || ep_data
  end

  # def get_eps(veteran_id)
  #   # What is the endpoint?
  # end

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
