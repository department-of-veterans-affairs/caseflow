# frozen_string_literal: true

describe WorkQueue::LegacyAppealSerializer, :all_dbs do
  let(:user) { create(:user) }
  let(:legacy_appeal) do
    create(
      :legacy_appeal,
      vacols_case: create(:case),
      veteran_address: {
        addrs_one_txt: FakeConstants.BGS_SERVICE.DEFAULT_ADDRESS_LINE_1,
        addrs_two_txt: FakeConstants.BGS_SERVICE.DEFAULT_ADDRESS_LINE_2,
        addrs_three_txt: FakeConstants.BGS_SERVICE.DEFAULT_ADDRESS_LINE_3,
        city_nm: FakeConstants.BGS_SERVICE.DEFAULT_CITY,
        cntry_nm: FakeConstants.BGS_SERVICE.DEFAULT_COUNTRY,
        postal_cd: FakeConstants.BGS_SERVICE.DEFAULT_STATE,
        zip_prefix_nbr: FakeConstants.BGS_SERVICE.DEFAULT_ZIP
      }
    )
  end

  subject { described_class.new(legacy_appeal, params: { user: user }) }

  describe "#as_json" do
    it "renders the appellant address from BGS" do
      serialized_appellant_address = {
        address_line_1: FakeConstants.BGS_SERVICE.DEFAULT_ADDRESS_LINE_1,
        address_line_2: FakeConstants.BGS_SERVICE.DEFAULT_ADDRESS_LINE_2,
        address_line_3: FakeConstants.BGS_SERVICE.DEFAULT_ADDRESS_LINE_3,
        city: FakeConstants.BGS_SERVICE.DEFAULT_CITY,
        country: FakeConstants.BGS_SERVICE.DEFAULT_COUNTRY,
        state: FakeConstants.BGS_SERVICE.DEFAULT_STATE,
        zip: FakeConstants.BGS_SERVICE.DEFAULT_ZIP
      }

      expect(subject.serializable_hash[:data][:attributes][:appellant_address]).to eq serialized_appellant_address
    end
  end
end
