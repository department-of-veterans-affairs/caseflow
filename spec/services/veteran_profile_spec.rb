# frozen_string_literal: true

describe VeteranProfile, :postgres do
  before do
    Fakes::BGSService.store_veteran_record(file_number, veteran_record)
    RequestStore[:current_user] = create(:user)
  end

  let(:file_number) { "44556677" }
  let(:ssn) { "123456789" }

  let(:veteran_record) do
    {
      file_number: file_number,
      ptcpnt_id: "123123",
      sex: "M",
      first_name: "June",
      middle_name: "Janice",
      last_name: "Juniper",
      name_suffix: "II",
      ssn: ssn
    }
  end

  let!(:appeal) { create(:appeal, veteran_file_number: file_number) }
  let!(:hlr) { create(:higher_level_review, veteran_file_number: file_number) }

  describe "#call" do
    subject { described_class.new(veteran_file_number: file_number).call }

    it "returns hash of artifact counts" do
      expect(subject["Appeal"]).to eq(1)
      expect(subject["HigherLevelReview"]).to eq(1)
      expect(subject["SupplementalClaim"]).to eq(0)
    end
  end
end
