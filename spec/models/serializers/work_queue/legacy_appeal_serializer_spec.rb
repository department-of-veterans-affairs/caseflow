# frozen_string_literal: true

describe WorkQueue::LegacyAppealSerializer do
  let(:user) { create(:user) }
  let(:legacy_appeal) { create(:legacy_appeal, vacols_case: create(:case)) }

  subject { described_class.new(legacy_appeal, params: { user: user }) }

  describe "#as_json" do
    it "renders the appellant address from BGS" do
      serialized_appellant_address = {
        address_line_1: Fakes::BGSService::DEFAULT_ADDRESS_LINE_1,
        address_line_2: Fakes::BGSService::DEFAULT_ADDRESS_LINE_2,
        address_line_3: Fakes::BGSService::DEFAULT_ADDRESS_LINE_3,
        city: Fakes::BGSService::DEFAULT_CITY,
        country: Fakes::BGSService::DEFAULT_COUNTRY,
        state: Fakes::BGSService::DEFAULT_STATE,
        zip: Fakes::BGSService::DEFAULT_ZIP
      }

      expect(subject.serializable_hash[:data][:attributes][:appellant_address]).to eq serialized_appellant_address
    end
  end
end
