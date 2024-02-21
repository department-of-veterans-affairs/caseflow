# frozen_string_literal: true

describe ExternalApi::VADotGovService do
  before(:each) do
    stub_const("VADotGovService", Fakes::VADotGovService)
  end

  let(:address) do
    Address.new(
      address_line_1: "fake address",
      address_line_2: "fake address",
      address_line_3: "fake address",
      city: "City",
      state: "State",
      zip: "11111",
      country: "USA"
    )
  end

  describe "#validate_address" do
    it "returns validated address" do
      result = VADotGovService.validate_address(address)

      body = JSON.parse(result.response.body)
      message_keys = body["messages"].pluck("key")

      expect(result.error).to be_nil
      expect(result.data).to_not be_nil
      expect(message_keys).to_not include("AddressCouldNotBeFound")
    end
  end

  describe "#validate_zip_code" do
    it "returns invalid full address with valid geographic coordinates" do
      result = VADotGovService.validate_zip_code(address)

      body = JSON.parse(result.response.body)
      message_keys = body["messages"].pluck("key")

      expect(result.error).to be_nil
      expect(result.data).to_not be_nil
      expect(message_keys).to include("AddressCouldNotBeFound")
      expect(body["geocode"]["latitude"]).to_not eq(0.0)
      expect(body["geocode"]["longitude"]).to_not eq(0.0)
    end
  end

  describe "#get_distance" do
    it "returns distance to facilities" do
      result = VADotGovService.get_distance(
        ids: %w[vha_757 vha_539],
        lat: 0.0,
        long: 0.0
      )

      expect(result.data.pluck(:facility_id)).to match_array(%w[vha_757 vha_539])
      expect(result.body[:meta][:distances].pluck(:id)).to match_array(%w[vha_757 vha_539])
      expect(result.body[:meta][:distances].pluck(:distance)).to all(be_an(Integer))

      expect(result.error).to be_nil
    end
  end

  describe "#get_facility_data" do
    it "returns facility data" do
      result = VADotGovService.get_facility_data(ids: %w[vha_757 vha_539])

      expect(result.data.pluck(:facility_id)).to match_array(%w[vha_757 vha_539])
      expect(result.body[:meta][:distances].pluck(:id, :distance)).to be_empty
      expect(result.error).to be_nil
    end
  end

  describe "#check_facility_ids" do
    it "returns missing facility ids" do
      result = VADotGovService.check_facility_ids(ids: %w[vba_317 vba_318 vba_319 vba_99999])

      expect(result.error).to be_nil
      expect(result.all_ids_present?).to be_falsey
      expect(result.missing_facility_ids).to eq(%w[vba_99999])
    end

    it "returns empty array when no missing facility ids" do
      result = VADotGovService.check_facility_ids(ids: %w[vba_317 vba_318 vba_319])

      expect(result.error).to be_nil
      expect(result.all_ids_present?).to be_truthy
      expect(result.missing_facility_ids).to eq(%w[])
    end

    it "returns empty array when no ids passed" do
      result = VADotGovService.check_facility_ids

      expect(result.error).to be_nil
      expect(result.all_ids_present?).to be_truthy
      expect(result.missing_facility_ids).to eq(%w[])
    end
  end

  describe "response failure" do
    let!(:error_code) { nil }

    before(:each) do
      allow(VADotGovService).to receive(:send_va_dot_gov_request)
        .and_return(HTTPI::Response.new(error_code, {}, {}.to_json))
    end

    context "429" do
      let!(:error_code) { 429 }

      it "throws Caseflow::Error::VaDotGovLimitError" do
        expect(VADotGovService.get_facility_data(ids: ["vba_372"]).error)
          .to be_an_instance_of(Caseflow::Error::VaDotGovLimitError)
      end
    end

    context "400" do
      let!(:error_code) { 400 }

      it "throws Caseflow::Error::VaDotGovRequestError" do
        expect(VADotGovService.get_facility_data(ids: ["vba_372"]).error)
          .to be_an_instance_of(Caseflow::Error::VaDotGovRequestError)
      end
    end

    context "500" do
      let!(:error_code) { 500 }

      it "throws Caseflow::Error::VaDotGovServerError" do
        expect(VADotGovService.get_facility_data(ids: ["vba_372"]).error)
          .to be_an_instance_of(Caseflow::Error::VaDotGovRequestError)
      end
    end
  end
end
