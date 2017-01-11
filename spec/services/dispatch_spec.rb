describe Dispatch do
  context "#filter_dispatch_end_products" do
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
end
