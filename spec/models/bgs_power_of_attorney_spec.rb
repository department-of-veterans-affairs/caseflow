# frozen_string_literal: true

describe BgsPowerOfAttorney do
  let(:claimant_participant_id) { "1129318238" }
  let(:file_number) { "66660000" }

  describe "record expirations" do
    before { FeatureToggle.enable!(:poa_auto_refresh) }
    after { FeatureToggle.disable!(:poa_auto_refresh) }

    context "by_claimant_participant_id" do
      let!(:poa) { create(:bgs_power_of_attorney, claimant_participant_id: claimant_participant_id) }

      it "record is expired NEW" do
        BgsPowerOfAttorney.set_callback(:save, :before, :update_cached_attributes!)
        BgsPowerOfAttorney.skip_callback(:save, :before, :update_cached_attributes!)
        poa.last_synced_at = 1.day.ago
        poa.save!
        BgsPowerOfAttorney.set_callback(:save, :before, :update_cached_attributes!)

        expect(poa.expired?).to eq(true)
        new_poa = BgsPowerOfAttorney.find_or_fetch_by(participant_id: poa.claimant_participant_id)
        expect(poa.last_synced_at).to_not eq(new_poa.last_synced_at)
      end

      it "record is not expired" do
        BgsPowerOfAttorney.set_callback(:save, :before, :update_cached_attributes!)
        BgsPowerOfAttorney.skip_callback(:save, :before, :update_cached_attributes!)
        poa.last_synced_at = Time.zone.now
        poa.save!
        BgsPowerOfAttorney.set_callback(:save, :before, :update_cached_attributes!)

        expect(poa.expired?).to eq(false)
        new_poa = BgsPowerOfAttorney.find_or_fetch_by(participant_id: poa.claimant_participant_id)
        expect(poa.last_synced_at.to_i).to eq(new_poa.last_synced_at.to_i)
      end
    end

    context "by_file_number" do
      let!(:poa) { create(:bgs_power_of_attorney, file_number: file_number) }

      it "record is expired" do
        BgsPowerOfAttorney.set_callback(:save, :before, :update_cached_attributes!)
        BgsPowerOfAttorney.skip_callback(:save, :before, :update_cached_attributes!)
        poa.last_synced_at = 1.day.ago
        poa.save!
        BgsPowerOfAttorney.set_callback(:save, :before, :update_cached_attributes!)

        expect(poa.expired?).to eq(true)
        new_poa = BgsPowerOfAttorney.find_or_fetch_by(veteran_file_number: poa.file_number)
        expect(poa.last_synced_at).to_not eq(new_poa.last_synced_at)
      end

      it "record is not expired" do
        BgsPowerOfAttorney.set_callback(:save, :before, :update_cached_attributes!)
        BgsPowerOfAttorney.skip_callback(:save, :before, :update_cached_attributes!)
        poa.last_synced_at = Time.zone.now
        poa.save!
        BgsPowerOfAttorney.set_callback(:save, :before, :update_cached_attributes!)

        expect(poa.expired?).to eq(false)
        new_poa = BgsPowerOfAttorney.find_or_fetch_by(veteran_file_number: poa.file_number)
        expect(poa.last_synced_at.to_i).to eq(new_poa.last_synced_at.to_i)
      end
    end
  end

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

    context "BGS has no record" do
      let(:claimant_participant_id) { "no-such-pid" }
      let(:file_number) { "no-such-file-number" }

      it "does not write db record, creates cache flag for 404" do
        expect { subject }.to raise_error(ActiveRecord::RecordInvalid)
        expect(Rails.cache.fetch("bgs-participant-poa-not-found-no-such-pid")).to eq(true)
      end
    end

    context "when concurrent calls cause a race condition" do
      let(:concurrency) { 4 }
      let(:pid) { "7108346" }
      let(:file_number) { "fn" }
      let(:bgs_record) do
        {
          claimant_participant_id: claimant_participant_id,
          participant_id: pid,
          file_number: file_number,
          representative_name: "some",
          representative_type: "vso"
        }
      end

      before do
        allow(BgsPowerOfAttorney).to receive(:fetch_bgs_poa_by_participant_id) do
          sleep 1
          bgs_record
        end
      end

      it "does not raise an error on unique constraint violation" do
        threads = []
        concurrency.times do
          threads << Thread.new do
            BgsPowerOfAttorney.find_or_create_by_claimant_participant_id(claimant_participant_id).poa_participant_id
          end
        end
        expect(threads.map(&:value)).to eq([pid] * concurrency)
      end
    end
  end

  describe ".find_or_create_by_file_number" do
    subject { described_class.find_or_create_by_file_number(file_number) }

    context "db record does not exist" do
      it "creates new db record" do
        expect { subject }.to change { described_class.count }.by(1)
        expect(subject).to be_a(described_class)
      end
    end

    context "db record exists" do
      let!(:poa) { create(:bgs_power_of_attorney, file_number: file_number) }

      it "fetches existing record" do
        expect { subject }.to change { described_class.count }.by(0)
        expect(subject).to eq(poa)
      end
    end

    context "BGS has no record" do
      let(:claimant_participant_id) { "no-such-pid" }
      let(:file_number) { "no-such-file-number" }

      it "does not write db record, creates cache flag for 404" do
        expect { subject }.to raise_error(ActiveRecord::RecordInvalid)
        expect(Rails.cache.fetch("bgs-participant-poa-not-found-no-such-file-number")).to eq(true)
      end
    end

    context "when concurrent calls cause a race condition" do
      let(:concurrency) { 4 }
      let(:pid) { "7108346" }
      let(:file_number) { "fn" }
      let(:bgs_record) do
        {
          claimant_participant_id: "1738055",
          participant_id: pid,
          file_number: file_number,
          representative_name: "some",
          representative_type: "vso"
        }
      end

      before do
        allow_any_instance_of(BGSService).to receive(:fetch_poa_by_file_number) do
          sleep 1
          bgs_record
        end
      end

      it "does not raise an error on unique constraint violation" do
        threads = []
        concurrency.times do
          threads << Thread.new do
            BgsPowerOfAttorney.find_or_create_by_file_number(file_number).poa_participant_id
          end
        end
        expect(threads.map(&:value)).to eq([pid] * concurrency)
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
        expect(subject.representative_name).to eq FakeConstants.BGS_SERVICE.DEFAULT_POA_NAME
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
    context "single POA record for PID" do
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

    context "2 records exist with same PID but different FNs" do
      before do
        allow(bgs).to receive(:fetch_poa_by_file_number)
          .with(poa_2_fn).and_return(poa_2_bgs_response)
        allow(bgs).to receive(:fetch_poa_by_file_number)
          .with(poa_1_fn).and_return(poa_1_bgs_response)
        allow(bgs).to receive(:fetch_poas_by_participant_ids)
          .with([claimant_participant_id]).and_return(claimant_participant_id => poa_2_bgs_response)
        allow(BGSService).to receive(:new) { bgs }
      end

      let(:claimant_participant_id) { "0000" }
      let(:poa_1_fn) { "1234" }
      let(:poa_2_fn) { "5678" }
      let!(:poa_1) do
        create(:bgs_power_of_attorney, claimant_participant_id: claimant_participant_id, file_number: poa_1_fn)
      end
      let!(:poa_2) do
        create(:bgs_power_of_attorney, claimant_participant_id: claimant_participant_id, file_number: poa_2_fn)
      end

      let(:poa_bgs_response) do
        {
          representative_type: "Attorney",
          representative_name: "Clarence Darrow",
          participant_id: 9999,
          authzn_change_clmant_addrs_ind: nil,
          authzn_poa_access_ind: nil,
          legacy_poa_cd: "3QQ",
          claimant_participant_id: claimant_participant_id
        }
      end

      let(:poa_1_bgs_response) { poa_bgs_response.merge(file_number: poa_1_fn) }
      let(:poa_2_bgs_response) { poa_bgs_response.merge(file_number: poa_2_fn) }

      let(:bgs) { double("bgs") }

      it "prefers fetch by filenumber over fetch by PID" do
        expect { described_class.find(poa_1.id).save_with_updated_bgs_record! }.to_not raise_error
        expect(bgs).to have_received(:fetch_poa_by_file_number).with(poa_1_fn).twice
        expect(bgs).to have_received(:fetch_poa_by_file_number).with(poa_2_fn).once
        expect(bgs).to_not have_received(:fetch_poas_by_participant_ids)
      end
    end
  end
end
