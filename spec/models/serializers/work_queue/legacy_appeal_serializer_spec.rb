# frozen_string_literal: true

describe WorkQueue::LegacyAppealSerializer, :all_dbs do
  let(:user) { create(:user) }
  let(:legacy_appeal) { create(:legacy_appeal, :with_veteran_address, vacols_case: create(:case)) }

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

    context "When all properties of the appellant_address are nil" do
      let(:address) do
        {
          addrs_one_txt: nil,
          addrs_two_txt: nil,
          addrs_three_txt: nil,
          city_nm: nil,
          cntry_nm: nil,
          postal_cd: nil,
          zip_prefix_nbr: nil,
          ptcpnt_addrs_type_nm: nil
        }
      end
      let(:legacy_appeal) { create(:legacy_appeal, vacols_case: create(:case), veteran_address: address) }

      it "Time zone is nil" do
        expect(subject.serializable_hash[:data][:attributes][:appellant_address][:country]).to eq(nil)
        expect(subject.serializable_hash[:data][:attributes][:appellant_tz]).to eq(nil)
      end
    end

    context "When appellant_address country is nil" do
      let(:address) do
        {
          addrs_one_txt: [nil, FakeConstants.BGS_SERVICE.DEFAULT_ADDRESS_LINE_1].sample,
          addrs_two_txt: [nil, FakeConstants.BGS_SERVICE.DEFAULT_ADDRESS_LINE_2].sample,
          addrs_three_txt: [nil, FakeConstants.BGS_SERVICE.DEFAULT_ADDRESS_LINE_3].sample,
          city_nm: [nil, FakeConstants.BGS_SERVICE.DEFAULT_CITY].sample,
          cntry_nm: nil,
          postal_cd: FakeConstants.BGS_SERVICE.DEFAULT_STATE,
          zip_prefix_nbr: FakeConstants.BGS_SERVICE.DEFAULT_ZIP,
          ptcpnt_addrs_type_nm: "Mailing"
        }
      end
      let(:legacy_appeal) { create(:legacy_appeal, vacols_case: create(:case), veteran_address: address) }

      it "Time zone is determined from zip code" do
        expect(subject.serializable_hash[:data][:attributes][:appellant_address][:country]).to eq(nil)
        expect(subject.serializable_hash[:data][:attributes][:appellant_tz]).to eq("America/Los_Angeles")
      end
    end
  end
end
