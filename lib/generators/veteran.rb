class Generators::Veteran
  extend Generators::Base

  class << self
    # rubocop:disable Metrics/MethodLength
    def default_attrs
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
        first_name: generate_first_name,
        foreign_code: nil,
        last_name: generate_last_name,
        middle_name: "E",
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
        sex: "F",
        service: [{ branch_of_service: "Army",
                    entered_on_duty_date: "02132002",
                    released_active_duty_date: "12212003",
                    char_of_svc_code: "HON" },
                  { branch_of_service: "Navy",
                    entered_on_duty_date: "07022006",
                    released_active_duty_date: "06282008",
                    char_of_svc_code: "UHC" }]
      }
    end
    # rubocop:enable Metrics/MethodLength

    def build(attrs = {})
      Fakes::BGSService.veteran_records ||= {}
      Fakes::BGSService.veteran_records[attrs[:file_number]] = default_attrs.merge(attrs)
    end
  end
end
