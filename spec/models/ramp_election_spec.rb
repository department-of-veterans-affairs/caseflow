# frozen_string_literal: true

describe RampElection, :postgres do
  before do
    Timecop.freeze(Time.utc(2018, 1, 1, 12, 0, 0))
  end

  let(:veteran_file_number) { "64205555" }
  let(:veteran_participant_id) { "5550246" }
  let!(:veteran) { Generators::Veteran.build(file_number: veteran_file_number, participant_id: veteran_participant_id) }
  let(:notice_date) { Time.zone.today - 2 }
  let(:receipt_date) { Time.zone.today - 1 }
  let(:option_selected) { nil }
  let(:end_product_reference_id) { nil }
  let(:established_at) { nil }

  let(:ramp_election) do
    build(:ramp_election,
          veteran_file_number: veteran_file_number,
          notice_date: notice_date,
          option_selected: option_selected,
          receipt_date: receipt_date,
          established_at: established_at)
  end

  context "#on_sync" do
    before { ramp_election.save! }
    subject { ramp_election.on_sync(end_product_establishment) }

    let!(:end_product_establishment) do
      create(
        :end_product_establishment,
        veteran_file_number: veteran_file_number,
        source: ramp_election,
        modifier: "683",
        synced_status: synced_status
      )
    end

    let(:synced_status) { "CAN" }

    it "calls recreate_issues_from_contentions!" do
      expect(ramp_election).to receive(:recreate_issues_from_contentions!)
      subject
    end

    context "when automatic ramp rollback is enabled" do
      before do
        FeatureToggle.enable!(:automatic_ramp_rollback)
        RequestStore[:current_user] = User.system_user
      end

      after { FeatureToggle.disable!(:automatic_ramp_rollback) }

      context "when status is canceled" do
        it "rolls back the ramp election" do
          subject
          expect(RampElectionRollback.find_by(
                   ramp_election: ramp_election,
                   user: User.system_user,
                   reason: "Automatic roll back due to EP 683 cancelation"
                 )).to_not be_nil
        end
      end

      context "when status is not canceled" do
        let(:synced_status) { "CLR" }

        it "rolls back the ramp election" do
          subject

          expect(RampElectionRollback.find_by(ramp_election: ramp_election)).to be_nil
        end
      end
    end

    context "when automatic ramp rollback is disabled" do
      it "doesn't roll back the ramp election" do
        subject

        expect(RampElectionRollback.find_by(ramp_election: ramp_election)).to be_nil
      end
    end
  end

  context "#create_or_connect_end_product!" do
    subject { ramp_election.create_or_connect_end_product! }

    # Stub the id of the end product being created
    before do
      Fakes::VBMSService.end_product_claim_id = "454545"
    end

    context "when option_selected is nil" do
      it "raises error" do
        expect { subject }.to raise_error(EndProductEstablishment::InvalidEndProductError)
      end
    end

    context "when option_selected is set" do
      let(:veteran) { create(:veteran, file_number: veteran_file_number) }
      let(:option_selected) { "supplemental_claim" }
      let(:modifier) { RampReview::END_PRODUCT_DATA_BY_OPTION[option_selected][:modifier] }

      context "when option receipt_date is nil" do
        let(:receipt_date) { nil }

        it "raises error" do
          expect { subject }.to raise_error(EndProductEstablishment::InvalidEndProductError)
        end
      end

      it "creates end product and saves end_product_reference_id" do
        allow(Fakes::VBMSService).to receive(:establish_claim!).and_call_original

        expect(subject).to eq(:created)

        expect(Fakes::VBMSService).to have_received(:establish_claim!).with(
          claim_hash: {
            benefit_type_code: "1",
            payee_code: "00",
            predischarge: false,
            claim_type: "Claim",
            station_of_jurisdiction: "397",
            date: receipt_date.to_date,
            end_product_modifier: modifier,
            end_product_label: "Supplemental Claim Review Rating",
            end_product_code: "683SCRRRAMP",
            gulf_war_registry: false,
            suppress_acknowledgement_letter: false,
            claimant_participant_id: veteran.participant_id,
            limited_poa_code: nil,
            limited_poa_access: nil,
            status_type_code: "PEND"
          },
          veteran_hash: veteran.reload.to_vbms_hash,
          user: nil
        )

        expect(EndProductEstablishment.find_by(source: ramp_election.reload)).to have_attributes(
          reference_id: "454545",
          committed_at: Time.zone.now
        )
      end

      context "with a higher level review" do
        let(:option_selected) { "higher_level_review" }

        it "should use the modifier 682" do
          allow(Fakes::VBMSService).to receive(:establish_claim!).and_call_original

          expect(subject).to eq(:created)

          expect(Fakes::VBMSService).to have_received(:establish_claim!).with(
            hash_including(claim_hash: hash_including(end_product_modifier: modifier))
          )
        end
      end

      context "if matching RAMP ep already exists" do
        let!(:matching_ep) do
          Generators::EndProduct.build(
            veteran_file_number: "64205555",
            bgs_attrs: {
              claim_type_code: "683SCRRRAMP",
              claim_receive_date: receipt_date.to_formatted_s(:short_date),
              end_product_type_code: "683"
            }
          )
        end

        it "connects that EP to the ramp election and does not establish a claim" do
          expect(Fakes::VBMSService).to_not receive(:establish_claim!)

          expect(subject).to eq(:connected)

          expect(ramp_election.reload.established_at).to eq(Time.zone.now)
          expect(ramp_election.end_product_establishment.reference_id).to eq(matching_ep.claim_id)
        end
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

        context "when the error is caught by VBMSError wrapper" do
          let(:vbms_error) do
            VBMS::DuplicateEP.new(500, "A duplicate claim for this EP code already exists in CorpDB.")
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
  end

  context "#recreate_issues_from_contentions!" do
    before do
      ramp_election.save!
      ramp_election.issues.create!(contention_reference_id: "123", description: "old")
    end

    let(:end_product_reference_id) { "8765445" }

    subject { ramp_election.recreate_issues_from_contentions! }

    context "when election has an issue attached to a ramp refiling" do
      let!(:ramp_refiling) do
        RampRefiling.create(
          veteran_file_number: veteran_file_number,
          receipt_date: receipt_date,
          option_selected: option_selected,
          appeal_docket: Constants.AMA_DOCKETS.hearing
        ).tap do |refiling|
          RampIssue.create(review: refiling, source_issue_id: ramp_election.issues.first.id)
        end
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
      let!(:end_product_establishment) do
        create(
          :end_product_establishment,
          veteran_file_number: veteran_file_number,
          source: ramp_election,
          reference_id: end_product_reference_id
        )
      end

      it "destroys previous issues and creates issues from contentions" do
        expect(subject).to be_truthy

        expect(ramp_election.issues.length).to eq(2)
        expect(ramp_election.issues.first.description).to eq("Migraines")
        expect(ramp_election.issues.last.description).to eq("Tinnitus")
      end
    end
  end

  context "#established?" do
    subject { ramp_election.established? }

    context "when there is an established at date" do
      let(:established_at) { Time.zone.now }

      it { is_expected.to eq(true) }
    end

    context "when there is not an established at date" do
      let(:established_at) { nil }

      it { is_expected.to eq(false) }
    end
  end

  context "#control_time" do
    subject { ramp_election.control_time }

    context "when established_at and receipt_date are set" do
      let(:established_at) { 1.day.ago }
      let(:receipt_date) { 2.days.ago }

      it { is_expected.to eq 1.day }
    end

    context "when established_at is nil" do
      let(:established_at) { nil }
      let(:receipt_date) { 2.days.ago }

      it { is_expected.to be nil }
    end

    context "when receipt date is nil" do
      let(:established_at) { 1.day.ago }
      let(:receipt_date) { nil }

      it { is_expected.to be nil }
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
          it "adds error to option_selected" do
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

      context "when it is after today and there is no notice_date" do
        let(:receipt_date) { 1.day.from_now }
        let(:notice_date) { nil }

        it "adds an error to receipt_date" do
          is_expected.to be false
          expect(ramp_election.errors[:receipt_date]).to include("in_future")
        end
      end

      context "when it is before RAMP begin date" do
        let(:receipt_date) { 2.years.ago }

        it "adds an error to receipt_date" do
          is_expected.to be false
          expect(ramp_election.errors[:receipt_date]).to include("before_ramp")
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

  context "#successful_intake" do
    subject { ramp_election.successful_intake }

    let(:user) { create(:user) }

    let!(:last_successful_intake) do
      RampElectionIntake.create!(
        user: user,
        completion_status: "success",
        completed_at: 2.days.ago,
        detail: ramp_election
      )
    end

    let!(:penultimate_successful_intake) do
      RampElectionIntake.create!(
        user: user,
        completion_status: "success",
        completed_at: 3.days.ago,
        detail: ramp_election
      )
    end

    let!(:unsuccessful_intake) do
      RampElectionIntake.create!(
        user: user,
        completion_status: "error",
        completed_at: 1.day.ago,
        detail: ramp_election
      )
    end

    it "returns the last successful intake" do
      expect(ramp_election.successful_intake).to eq(last_successful_intake)
    end
  end

  context "#rollback!" do
    subject { ramp_election.rollback! }

    let!(:ramp_election) do
      create(:ramp_election,
             veteran_file_number: veteran_file_number,
             notice_date: 31.days.ago,
             option_selected: "higher_level_review",
             receipt_date: 5.days.ago,
             established_at: 3.days.ago)
    end

    let!(:ramp_closed_appeals) do
      %w[12345 23456].map do |vacols_id|
        ramp_election.ramp_closed_appeals.create!(vacols_id: vacols_id)
      end
    end

    it "clears out all fields associated with establishment and deletes closed appeals" do
      subject

      expect(ramp_election.reload).to have_attributes(
        veteran_file_number: veteran_file_number,
        notice_date: 31.days.ago.to_date,
        option_selected: nil,
        receipt_date: nil,
        established_at: nil
      )

      expect(ramp_closed_appeals.first).to_not be_persisted
      expect(ramp_closed_appeals.last).to_not be_persisted
    end
  end
end
