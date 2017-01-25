describe Dispatch do
  let(:twenty_days_ago) { 20.days.ago.to_formatted_s(:short_date) }
  let(:last_year) { 365.days.ago.to_formatted_s(:short_date) }

  context ".filter_dispatch_end_products" do
    let(:end_products) do
      [{ claim_type_code: "170APPACT" },
       { claim_type_code: "170APPACTPMC" },
       { claim_type_code: "170PGAMC" },
       { claim_type_code: "170RMD" },
       { claim_type_code: "170RMDAMC" },
       { claim_type_code: "170RMDPMC" },
       { claim_type_code: "172GRANT" },
       { claim_type_code: "172BVAG" },
       { claim_type_code: "172BVAGPMC" },
       { claim_type_code: "400CORRC" },
       { claim_type_code: "400CORRCPMC" },
       { claim_type_code: "930RC" },
       { claim_type_code: "930RCPMC" }]
    end

    let(:extra_end_products) do
      end_products.clone.push(claim_type_code: "Test")
    end

    subject { Dispatch.filter_dispatch_end_products(extra_end_products) }

    it "filters out non-dispatch end products" do
      is_expected.to eq(end_products)
    end
  end

  context ".map_ep_values" do
    let(:end_products_output) do
      [
        {
          claim_receive_date: twenty_days_ago,
          claim_type_code: "PMC-BVA Grant",
          status_type_code: "Pending"
        },
        {
          claim_receive_date: last_year,
          claim_type_code: "Rating Control",
          status_type_code: "Canceled"
        }
      ]
    end
    subject { Dispatch.map_ep_values(end_products_input) }

    let(:end_products_input) do
      [
        {
          claim_receive_date: twenty_days_ago,
          claim_type_code: "172BVAGPMC",
          status_type_code: "PEND"
        },
        {
          claim_receive_date: last_year,
          claim_type_code: "930RC",
          status_type_code: "CAN"
        }
      ]
    end

    it "correctly maps abbreviations to strings" do
      is_expected.to eq(end_products_output)
    end
  end
end
