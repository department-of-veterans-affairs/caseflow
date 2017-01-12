class Fakes::BGSService
  cattr_accessor :end_product_data

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
        status_type_code: "CLR"
      },
      {
        benefit_claim_id: "3",
        claim_receive_date: Time.zone.now,
        claim_type_code: "172BVAG",
        status_type_code: "CAN"
      },
      {
        benefit_claim_id: "4",
        claim_receive_date: Time.zone.now - 200.days,
        claim_type_code: "172BVAG",
        status_type_code: "CLR"
      }
    ].freeze

  def get_end_products(_veteran_id)
    end_product_data || END_PRODUCTS
  end
end
