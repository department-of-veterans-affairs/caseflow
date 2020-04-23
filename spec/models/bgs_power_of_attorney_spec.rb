# frozen_string_literal: true

describe BgsPowerOfAttorney do
  let(:claimant_participant_id) { "1129318238" }
  let(:file_number) { "66660000" }

  describe ".find_or_create_by_claimant_participant_id" do
    subject { described_class.find_or_create_by_claimant_participant_id(claimant_participant_id) }

    context "db record does not exist" do
      it "creates new db record" do
        expect(subject).to be_a(described_class)
        expect(described_class.count).to eq(1)
      end
    end

    context "db record exists" do
      let!(:poa) { create(:bgs_power_of_attorney, claimant_participant_id: claimant_participant_id) }

      it "fetches existing record" do
        expect(subject).to eq(poa)
        expect(described_class.count).to eq(1)
      end
    end
  end

  describe ".find_or_create_by_file_number" do
    subject { described_class.find_or_create_by_file_number(file_number) }

    context "db record does not exist" do
      it "creates new db record" do
        expect(subject).to be_a(described_class)
        expect(described_class.count).to eq(1)
      end
    end

    context "db record exists" do
      let!(:poa) { create(:bgs_power_of_attorney, file_number: file_number) }

      it "fetches existing record" do
        expect(subject).to eq(poa)
        expect(described_class.count).to eq(1)
      end
    end
  end

  describe ".find_or_load_by_file_number" do
    subject { described_class.find_or_load_by_file_number(file_number) }

    context "db record does not exist" do
      it "returns un-persisted object" do
        expect(subject).to_not be_persisted
        expect(subject).to be_a(described_class)
        # fetched from bgs by fetch_poa_by_file_number (default_power_of_attorney_record)
        expect(subject.representative_name).to eq FakeConstants.BGS_SERVICE.DEFAULT_POA_NAME
      end
    end

    context "db record exists" do
      let!(:poa) { create(:bgs_power_of_attorney, file_number: file_number) }

      it "fetches db record" do
        expect(subject).to be_persisted
        expect(subject).to eq(poa)
        # fetched from bgs by fetch_poas_by_participant_ids with default fake
        # because claimant_participant_id is populated by factory create() above.
        expect(subject.representative_name).to eq "Attorney McAttorneyFace"
      end
    end
  end

  describe ".fetch_bgs_poa_by_participant_id" do
  end

  describe "#new" do
  end

  describe "#save" do
    let(:claimant_participant_id) { "CLAIMANT_WITH_PVA_AS_VSO" }

  end

  describe "attributes" do
  end
end
