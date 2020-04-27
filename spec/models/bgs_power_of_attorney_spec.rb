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
      let!(:poa) { create(:bgs_power_of_attorney, representative_name: nil, file_number: file_number) }

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
    subject { described_class.fetch_bgs_poa_by_participant_id(claimant_participant_id) }

    context "POA exists in BGS" do
      it "returns parsed response" do
        expect(subject).to_not be_nil
        expect(subject[:file_number]).to eq "00001234" # default fakes
      end
    end

    context "POA does not exist in BGS" do
      let(:claimant_participant_id) { "no-such-pid" }

      it "returns nil" do
        expect(subject).to be_nil
      end
    end
  end

  describe "#new" do
    subject { described_class.new(params) }

    context "file_number matches known BGS POA" do
      let(:params) { { file_number: Fakes::BGSService::DEFAULT_VSO_POA_FILE_NUMBER } }

      it "fetches BGS record transparently" do
        expect(subject).to be_a described_class
        expect(subject.claimant_participant_id).to_not be_nil
        expect(subject.representative_name).to_not be_nil
      end
    end

    context "claimant_participant_id matches known BGS POA" do
      let(:params) { { claimant_participant_id: "CLAIMANT_WITH_PVA_AS_VSO" } }

      it "fetches BGS record transparently" do
        expect(subject).to be_a described_class
        expect(subject.file_number).to_not be_nil
        expect(subject.representative_name).to eq "PARALYZED VETERANS OF AMERICA, INC."
      end
    end

    context "no known match in BGS" do
      let(:params) { { claimant_participant_id: "no-such-pid" } }

      context "params are incomplete" do
        it "is not AR valid" do
          expect(subject).to_not be_valid
        end
      end

      context "params are complete" do
        let(:params) do
          {
            claimant_participant_id: "no-such-pid",
            poa_participant_id: "the-vso-pid",
            file_number: "something",
            representative_name: "some",
            representative_type: "vso"
          }
        end

        it "behaves like normal AR record" do
          expect(subject).to be_valid
        end
      end
    end
  end

  describe "#save" do
    subject { build(:bgs_power_of_attorney, claimant_participant_id: claimant_participant_id) }

    let(:claimant_participant_id) { "CLAIMANT_WITH_PVA_AS_VSO" }

    it "automatically writes all BGS attributes" do
      subject.save!
      expect(subject.legacy_poa_cd).to eq("071")
    end
  end

  describe "#save_with_updated_bgs_record!" do
    let!(:poa) { create(:bgs_power_of_attorney, claimant_participant_id: claimant_participant_id) }

    let(:claimant_participant_id) { "CLAIMANT_WITH_PVA_AS_VSO" }

    before do
      allow_any_instance_of(Fakes::BGSService).to receive(:fetch_poas_by_participant_ids)
        .with([claimant_participant_id]).and_return(Fakes::BGSServicePOA.default_vsos_mapped.last)
    end

    it "forces update from BGS" do
      before_poa_pid = poa.poa_participant_id
      expect(before_poa_pid).to_not be_nil

      poa.save_with_updated_bgs_record!

      expect(poa.poa_participant_id).to_not eq before_poa_pid
    end
  end
end
