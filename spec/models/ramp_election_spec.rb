describe RampElection do
  before do
    Timecop.freeze(Time.utc(2015, 1, 1, 12, 0, 0))
  end

  let(:veteran_file_number) { "64205555" }
  let!(:veteran) { Generators::Veteran.build(file_number: "64205555") }
  let(:notice_date) { 1.day.ago }
  let(:receipt_date) { 1.day.ago }
  let(:option_selected) { nil }
  let(:end_product_reference_id) { nil }

  let(:ramp_election) do
    RampElection.new(
      veteran_file_number: veteran_file_number,
      notice_date: notice_date,
      option_selected: option_selected,
      receipt_date: receipt_date,
      end_product_reference_id: end_product_reference_id
    )
  end

  context "#create_end_product!" do
    subject { ramp_election.create_end_product! }
    # Stub the id of the end product being created
    before do
      Fakes::VBMSService.end_product_claim_id = "454545"
    end

    context "when option_selected is nil" do
      it "raises error" do
        expect { subject }.to raise_error(RampElection::InvalidEndProductError)
      end
    end

    context "when option_selected is set" do
      let(:veteran) { Veteran.new(file_number: veteran_file_number).load_bgs_record! }
      let(:option_selected) { "supplemental_claim" }

      context "when option receipt_date is nil" do
        let(:receipt_date) { nil }

        it "raises error" do
          expect { subject }.to raise_error(RampElection::InvalidEndProductError)
        end
      end

      it "creates end product and saves end_product_reference_id" do
        allow(Fakes::VBMSService).to receive(:establish_claim!).and_call_original

        subject

        expect(Fakes::VBMSService).to have_received(:establish_claim!).with(
          claim_hash: {
            benefit_type_code: "1",
            payee_code: "00",
            predischarge: false,
            claim_type: "Claim",
            station_of_jurisdiction: "397",
            date: receipt_date.to_date,
            end_product_modifier: "683",
            end_product_label: "Supplemental Claim Review Rating",
            end_product_code: "683SCRRRAMP",
            gulf_war_registry: false,
            suppress_acknowledgement_letter: false
          },
          veteran_hash: veteran.to_vbms_hash
        )

        expect(ramp_election.reload.end_product_reference_id).to eq("454545")
      end

      context "when VBMS throws an error" do
        before do
          allow(VBMSService).to receive(:establish_claim!).and_raise(vbms_error)
        end

        let(:vbms_error) do
          VBMS::HTTPError.new("500", "<faultstring>Claim not established. " \
            "A duplicate claim for this EP code already exists in CorpDB. Please " \
            "use a different EP code modifier. GUID: 13fcd</faultstring>")
        end

        it "raises a parsed EstablishClaimFailedInVBMS error" do
          expect { subject }.to raise_error do |error|
            expect(error).to be_a(Caseflow::Error::EstablishClaimFailedInVBMS)
            expect(error.error_code).to eq("duplicate_ep")
          end
        end
      end
    end
  end

  context "#recreate_issues_from_contentions!" do
    before do
      ramp_election.save!
      ramp_election.issues.create!(contention_reference_id: "123", description: "old")
    end

    let(:end_product_reference_id) { "8765445" }

    subject { ramp_election.recreate_issues_from_contentions! }

    context "when election has a saved refiling associated to it" do
      let!(:ramp_refiling) do
        ramp_election.ramp_refilings.create!(
          veteran_file_number: ramp_election.veteran_file_number
        )
      end

      it "returns false and deletes/creates no issues" do
        expect(subject).to be_falsey

        expect(ramp_election.issues.length).to eq(1)
        expect(ramp_election.issues.first.description).to eq("old")
      end
    end

    context "when election has no refiling" do
      let!(:contentions) do
        [
          Generators::Contention.build(claim_id: end_product_reference_id, text: "Migraines"),
          Generators::Contention.build(claim_id: end_product_reference_id, text: "Tinnitus"),
          Generators::Contention.build(claim_id: "123", text: "Not related")
        ]
      end

      it "destroys previous issues and creates issues from contentions" do
        expect(subject).to be_truthy

        expect(ramp_election.issues.length).to eq(2)
        expect(ramp_election.issues.first.description).to eq("Migraines")
        expect(ramp_election.issues.last.description).to eq("Tinnitus")
      end
    end
  end

  context "#successfully_received?" do
    subject { ramp_election.successfully_received? }

    context "when there is a successful intake referencing the election" do
      let!(:intake) do
        RampElectionIntake.create!(
          user: Generators::User.build,
          detail: ramp_election,
          completed_at: Time.zone.now,
          completion_status: :success
        )
      end

      it { is_expected.to eq(true) }
    end

    context "when there is a canceled intake referencing the election" do
      let!(:intake) do
        RampElectionIntake.create!(
          user: Generators::User.build,
          detail: ramp_election,
          completed_at: Time.zone.now,
          completion_status: :canceled
        )
      end

      it { is_expected.to eq(false) }
    end

    context "when there is no intake referencing the election" do
      it { is_expected.to eq(false) }
    end
  end

  context "#established_end_product" do
    subject { ramp_election.established_end_product }

    let!(:other_ep) { Generators::EndProduct.build(veteran_file_number: veteran_file_number) }
    let!(:matching_ep) { Generators::EndProduct.build(veteran_file_number: veteran_file_number) }

    context "when matching end product has not yet been established" do
      context "when end_product_reference_id is nil" do
        it { is_expected.to be_nil }
      end

      context "when end_product_reference_id is set" do
        let(:end_product_reference_id) { "not matching" }

        it "raises EstablishedEndProductNotFound error" do
          expect { subject }.to raise_error(RampElection::EstablishedEndProductNotFound)
        end
      end
    end

    context "when a matching end product has been established" do
      let(:end_product_reference_id) { matching_ep.claim_id }

      it { is_expected.to have_attributes(claim_id: matching_ep.claim_id) }
    end
  end

  context "#valid?" do
    subject { ramp_election.valid? }

    context "option_selected" do
      context "when saving receipt" do
        before { ramp_election.start_review! }

        context "when it is set" do
          context "when it is a valid option" do
            let(:option_selected) { "higher_level_review_with_hearing" }
            it { is_expected.to be true }
          end
        end

        context "when it is nil" do
          it "adds error to receipt_date" do
            is_expected.to be false
            expect(ramp_election.errors[:option_selected]).to include("blank")
          end
        end
      end
    end

    context "receipt_date" do
      context "when it is nil" do
        it { is_expected.to be true }
      end

      context "when it is after today" do
        let(:receipt_date) { 1.day.from_now }

        it "adds an error to receipt_date" do
          is_expected.to be false
          expect(ramp_election.errors[:receipt_date]).to include("in_future")
        end
      end

      context "when it is before notice_date" do
        let(:receipt_date) { 2.days.ago }

        it "adds an error to receipt_date" do
          is_expected.to be false
          expect(ramp_election.errors[:receipt_date]).to include("before_notice_date")
        end
      end

      context "when it is on or after notice date and on or before today" do
        let(:receipt_date) { 1.day.ago }
        it { is_expected.to be true }
      end

      context "when saving receipt" do
        before { ramp_election.start_review! }

        context "when it is nil" do
          let(:receipt_date) { nil }

          it "adds error to receipt_date" do
            is_expected.to be false
            expect(ramp_election.errors[:receipt_date]).to include("blank")
          end
        end
      end
    end
  end
end
