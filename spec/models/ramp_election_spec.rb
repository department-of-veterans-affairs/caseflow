describe RampElection do
  before do
    FeatureToggle.enable!(:test_facols)
    Timecop.freeze(Time.utc(2018, 1, 1, 12, 0, 0))
  end

  after do
    FeatureToggle.disable!(:test_facols)
  end

  let(:veteran_file_number) { "64205555" }
  let!(:veteran) { Generators::Veteran.build(file_number: "64205555") }
  let(:notice_date) { Time.zone.today - 2 }
  let(:receipt_date) { Time.zone.today - 1 }
  let(:option_selected) { nil }
  let(:end_product_reference_id) { nil }
  let(:established_at) { nil }
  let(:end_product_status) { nil }

  let(:ramp_election) do
    build(:ramp_election,
          veteran_file_number: veteran_file_number,
          notice_date: notice_date,
          option_selected: option_selected,
          receipt_date: receipt_date,
          established_at: established_at,
          end_product_status: end_product_status)
  end

  context ".active scope" do
    it "includes any RampElection where end_product_status is nil or not inactive" do
      ep1 = create(:ramp_election,
                   veteran_file_number: "1",
                   notice_date: 1.day.ago,
                   receipt_date: 1.day.ago)
      EndProductEstablishment.create(
        source: ep1,
        veteran_file_number: "1",
        synced_status: "ACTIVE"
      )
      ep11 = create(:ramp_election,
                    veteran_file_number: "11",
                    notice_date: 1.day.ago,
                    receipt_date: 1.day.ago,
                    established_at: Time.zone.now)
      EndProductEstablishment.create(
        source: ep11,
        veteran_file_number: "11",
        synced_status: "ACTIVE"
      )
      ep2 = create(:ramp_election,
                   veteran_file_number: "2",
                   notice_date: 1.day.ago,
                   receipt_date: 1.day.ago)
      EndProductEstablishment.create(
        source: ep2,
        veteran_file_number: "2",
        synced_status: EndProduct::INACTIVE_STATUSES.first
      )
      create(:ramp_election,
             veteran_file_number: "3",
             notice_date: 1.day.ago,
             receipt_date: 1.day.ago,
             established_at: Time.zone.now)
      expect(RampElection.active.count).to eq(2)
    end
  end

  context "#sync!" do
    before { ramp_election.save! }

    subject { ramp_election.sync! }

    let!(:ep) do
      Generators::EndProduct.build(veteran_file_number: veteran_file_number).tap do |end_product|
        EndProductEstablishment.create(
          veteran_file_number: veteran_file_number,
          source: ramp_election,
          reference_id: end_product.claim_id
        )
      end
    end

    it "calls recreate_issues_from_contentions! and sync_ep_status!" do
      expect(ramp_election).to receive(:recreate_issues_from_contentions!)
      expect(ramp_election).to receive(:sync_ep_status!)

      subject
    end

    context "when error is raised" do
      before do
        expect(ramp_election).to receive(:sync_ep_status!).and_raise(ActiveRecord::RecordInvalid)
      end

      it "sends error to sentry but does not re-raise" do
        expect(ramp_election).to receive(:recreate_issues_from_contentions!)
        expect(Raven).to receive(:capture_exception)

        subject
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
      let(:veteran) { Veteran.create(file_number: veteran_file_number) }
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
            suppress_acknowledgement_letter: false
          },
          veteran_hash: veteran.to_vbms_hash
        )

        expect(EndProductEstablishment.find_by(source: ramp_election.reload).reference_id).to eq("454545")
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
          expect(ramp_election.end_product_reference_id).to eq(matching_ep.claim_id)
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
          appeal_docket: "hearing"
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
        EndProductEstablishment.create(
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

  context "#end_product_active?" do
    subject { ramp_election.end_product_active? }

    let(:end_product_reference_id) { "9" }
    let!(:established_end_product) do
      Generators::EndProduct.build(
        veteran_file_number: ramp_election.veteran_file_number,
        bgs_attrs: {
          benefit_claim_id: end_product_reference_id,
          status_type_code: status_type_code
        }
      )
      EndProductEstablishment.create(
        veteran_file_number: ramp_election.veteran_file_number,
        source: ramp_election,
        synced_status: status_type_code,
        reference_id: end_product_reference_id
      )
    end

    context "when the EP is cleared" do
      let(:status_type_code) { "CLR" }

      it { is_expected.to eq(false) }
    end

    context "when the EP is pending" do
      let(:status_type_code) { "PEND" }

      it { is_expected.to eq(true) }
    end
  end

  context "#sync_ep_status!" do
    subject { ramp_election.sync_ep_status! }

    let(:end_product_reference_id) { "9" }

    context "cached end product status is active" do
      let(:end_product_status) { "PEND" }
      let!(:established_end_product) do
        EndProductEstablishment.create(
          veteran_file_number: ramp_election.veteran_file_number,
          source: ramp_election,
          reference_id: end_product_reference_id,
          synced_status: end_product_status,
          last_synced_at: 3.days.ago
        )
        Generators::EndProduct.build(
          veteran_file_number: ramp_election.veteran_file_number,
          bgs_attrs: {
            benefit_claim_id: end_product_reference_id,
            status_type_code: "WAZZAP"
          }
        )
      end

      it "updates values properly and returns true" do
        expect(subject).to be_truthy
        establishment = EndProductEstablishment.find_by(source: ramp_election.reload)
        expect(establishment.synced_status).to eq("WAZZAP")
        expect(establishment.last_synced_at).to eq(Time.zone.now)
      end
    end

    context "updates to canceled" do
      let(:option_selected) { "supplemental_claim" }
      let(:end_product_status) { "PEND" }
      let!(:established_end_product) do
        EndProductEstablishment.create(
          veteran_file_number: ramp_election.veteran_file_number,
          source: ramp_election,
          reference_id: end_product_reference_id,
          synced_status: end_product_status,
          last_synced_at: 3.days.ago,
          modifier: "683"
        )
        Generators::EndProduct.build(
          veteran_file_number: ramp_election.veteran_file_number,
          bgs_attrs: {
            benefit_claim_id: end_product_reference_id,
            status_type_code: "CAN"
          }
        )
      end
      let!(:appeals_to_reopen) do
        %w[12345 23456].map do |vacols_id|
          ramp_election.ramp_closed_appeals.create!(vacols_id: vacols_id)
          create(:legacy_appeal,
                 vacols_case: create(
                   :case_with_decision,
                   :type_original,
                   :status_complete,
                   :disposition_ramp,
                   :reopenable,
                   bfboard: "00",
                   bfkey: vacols_id,
                   bfcorlid: veteran_file_number + "C"
                 ))
        end
      end

      it "updates the value" do
        expect(subject).to be_truthy
        establishment = EndProductEstablishment.find_by(source: ramp_election.reload)
        expect(establishment.synced_status).to eq("CAN")
        expect(establishment.last_synced_at).to eq(Time.zone.now)
      end

      context "if automatic ramp rollback is enabled" do
        before do
          FeatureToggle.enable!(:automatic_ramp_rollback)
          RequestStore[:current_user] = User.system_user
        end

        after { FeatureToggle.disable!(:automatic_ramp_rollback) }

        it "rolls back the ramp election" do
          expect(subject).to be_truthy
          expect(RampElectionRollback.last).to have_attributes(
            ramp_election: ramp_election,
            user: User.system_user,
            reason: "Automatic roll back due to EP 683 cancelation"
          )
        end
      end

      context "if automatic ramp rollback is disabled" do
        it "doesn't roll back the ramp election" do
          expect(subject).to be_truthy
          expect(RampElectionRollback.find_by(ramp_election: ramp_election)).to be_nil
        end
      end
    end

    context "cached end product status not active" do
      let(:end_product_status) { "CAN" }
      let!(:established_end_product) do
        EndProductEstablishment.create(
          veteran_file_number: ramp_election.veteran_file_number,
          source: ramp_election,
          reference_id: end_product_reference_id,
          synced_status: end_product_status,
          last_synced_at: 3.days.ago
        )
        Generators::EndProduct.build(
          veteran_file_number: ramp_election.veteran_file_number,
          bgs_attrs: {
            benefit_claim_id: end_product_reference_id,
            status_type_code: "WAZZAP"
          }
        )
      end

      it "does not update any values and returns true" do
        expect(subject).to be_truthy
        establishment = EndProductEstablishment.find_by(source: ramp_election.reload)
        expect(establishment.synced_status).to eq("CAN")
        expect(establishment.last_synced_at).to eq(3.days.ago)
      end
    end
  end

  context "#end_product_canceled?" do
    subject { ramp_election.end_product_canceled? }

    let(:end_product_reference_id) { "9" }
    let!(:established_end_product) do
      EndProductEstablishment.create(
        veteran_file_number: ramp_election.veteran_file_number,
        source: ramp_election,
        reference_id: end_product_reference_id,
        synced_status: ep_status
      )
      Generators::EndProduct.build(
        veteran_file_number: ramp_election.veteran_file_number,
        bgs_attrs: {
          benefit_claim_id: end_product_reference_id,
          status_type_code: ep_status
        }
      )
    end

    context "when end product is canceled" do
      let(:ep_status) { "CAN" }

      it { is_expected.to be true }
    end

    context "when end product is not canceled" do
      let(:ep_status) { "PEND" }

      it { is_expected.to be false }
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

    let!(:last_successful_intake) do
      RampElectionIntake.create!(
        user_id: "123",
        completion_status: "success",
        completed_at: 2.days.ago,
        detail: ramp_election
      )
    end

    let!(:penultimate_successful_intake) do
      RampElectionIntake.create!(
        user_id: "123",
        completion_status: "success",
        completed_at: 3.days.ago,
        detail: ramp_election
      )
    end

    let!(:unsuccessful_intake) do
      RampElectionIntake.create!(
        user_id: "123",
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
             veteran_file_number: "44444444",
             notice_date: 31.days.ago,
             option_selected: "higher_level_review",
             receipt_date: 5.days.ago,
             end_product_reference_id: "1234",
             established_at: 3.days.ago,
             end_product_status: "CAN",
             end_product_status_last_synced_at: Time.zone.now)
    end

    let!(:ramp_closed_appeals) do
      %w[12345 23456].map do |vacols_id|
        ramp_election.ramp_closed_appeals.create!(vacols_id: vacols_id)
      end
    end

    it "clears out all fields associated with establishment and deletes closed appeals" do
      subject

      expect(ramp_election.reload).to have_attributes(
        veteran_file_number: "44444444",
        notice_date: 31.days.ago.to_date,
        option_selected: nil,
        receipt_date: nil,
        end_product_reference_id: nil,
        established_at: nil,
        end_product_status: nil,
        end_product_status_last_synced_at: nil
      )

      expect(ramp_closed_appeals.first).to_not be_persisted
      expect(ramp_closed_appeals.last).to_not be_persisted
    end
  end
end
