# frozen_string_literal: true

class Fakes::BGSServiceGrants
  # rubocop:disable Metrics/MethodLength
  class << self
    def existing_full_grants
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

    def existing_partial_grants
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

    def all
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
  end
  # rubocop:enable Metrics/MethodLength
end
