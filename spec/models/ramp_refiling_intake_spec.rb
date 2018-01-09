describe RampRefilingIntake do
  before do
    Timecop.freeze(Time.utc(2015, 1, 1, 12, 0, 0))
  end

  let(:user) { Generators::User.build }
  let(:veteran_file_number) { "64205555" }
  let!(:veteran) { Generators::Veteran.build(file_number: veteran_file_number) }
  let(:detail) { nil }

  let(:intake) do
    RampRefilingIntake.new(
      user: user,
      veteran_file_number: veteran_file_number,
      detail: detail
    )
  end

  let(:completed_ramp_election) do
    RampElection.create!(
      veteran_file_number: veteran_file_number,
      notice_date: 4.days.ago,
      receipt_date: 3.days.ago,
      end_product_reference_id: Generators::EndProduct.build(
        veteran_file_number: veteran_file_number,
        bgs_attrs: { status_type_code: "CLR" }
      ).claim_id
    )
  end

  let(:claim_id) { completed_ramp_election.end_product_reference_id }

  let(:ramp_election_contentions) do
    [Generators::Contention.build(claim_id: claim_id, text: "Left knee")]
  end

  context "#start!" do
    subject { intake.start! }

    context "valid to start" do
      let!(:ramp_election) { completed_ramp_election }
      let!(:contentions) { ramp_election_contentions }

      it "saves intake and sets detail to ramp election and loads issues" do
        expect(subject).to be_truthy

        expect(intake.started_at).to eq(Time.zone.now)
        expect(intake.detail).to have_attributes(
          veteran_file_number: "64205555",
          ramp_election_id: completed_ramp_election.id
        )

        expect(completed_ramp_election.issues.count).to eq(1)
        expect(completed_ramp_election.issues.first.description).to eq("Left knee")
      end
    end
  end

  context "#validate_start" do
    subject { intake.validate_start }

    let!(:end_product) do
      Generators::EndProduct.build(
        veteran_file_number: "64205555",
        bgs_attrs: {
          status_type_code: end_product_status
        }
      )
    end

    let(:end_product_status) { "CLR" }

    context "there is not a completed ramp election for veteran" do
      let!(:not_complete_ramp_election) do
        RampElection.create!(
          veteran_file_number: "64205555",
          notice_date: 3.days.ago
        )
      end

      it "adds did_not_receive_ramp_election and returns false" do
        expect(subject).to eq(false)
        expect(intake.error_code).to eq("no_complete_ramp_election")
      end
    end

    context "there is a completed ramp election for veteran" do
      let!(:ramp_election) do
        RampElection.create!(
          veteran_file_number: "64205555",
          notice_date: 3.days.ago,
          end_product_reference_id: end_product.claim_id
        )
      end

      let(:claim_id) { ramp_election.end_product_reference_id }

      context "the EP associated with original RampElection is still pending" do
        let(:end_product_status) { "PEND" }

        it "adds ramp_election_is_active and returns false" do
          expect(subject).to eq(false)
          expect(intake.error_code).to eq("ramp_election_is_active")
        end
      end

      context "the EP associated with original RampElection is closed" do
        context "there are no contentions on the EP" do
          it "adds ramp_election_no_issues and returns false" do
            expect(subject).to eq(false)
            expect(intake.error_code).to eq("ramp_election_no_issues")
          end
        end

        context "there are contentions on the EP" do
          let!(:contentions) { ramp_election_contentions }
          before { ramp_election.recreate_issues_from_contentions! }

          it { is_expected.to eq(true) }
        end
      end
    end
  end

  context "#complete!" do
    subject { intake.complete!(params) }

    let(:params) do
      {
        issue_ids: source_issues && source_issues.map(&:id),
        has_ineligible_issue: true
      }
    end

    let(:detail) do
      RampRefiling.create!(
        ramp_election: completed_ramp_election,
        veteran_file_number: veteran_file_number,
        receipt_date: 2.days.ago,
        option_selected: option_selected
      )
    end

    let(:source_issues) do
      [
        completed_ramp_election.issues.create!(description: "Firsties"),
        completed_ramp_election.issues.create!(description: "Secondsies")
      ]
    end

    context "when end product is needed" do
      let(:option_selected) { "supplemental_claim" }

      it "saves issues and creates an end product" do
        expect(Fakes::VBMSService).to receive(:establish_claim!).and_call_original

        subject

        expect(intake.reload).to be_success
        expect(intake.detail.issues.count).to eq(2)
        expect(intake.detail.has_ineligible_issue).to eq(true)
      end

      context "when source_issues is nil" do
        let(:source_issues) { nil }

        it "works, but does not create an EP" do
          expect(Fakes::VBMSService).to_not receive(:establish_claim!)

          subject

          expect(intake.reload).to be_success
          expect(intake.detail.issues.count).to eq(0)
          expect(intake.detail.has_ineligible_issue).to eq(true)
        end
      end
    end

    context "when no end product is needed" do
      let(:option_selected) { "appeal" }

      it "saves issues and does NOT create an end product" do
        expect(Fakes::VBMSService).to_not receive(:establish_claim!)

        subject

        expect(intake.reload).to be_success
        expect(intake.detail.issues.count).to eq(2)
        expect(intake.detail.has_ineligible_issue).to eq(true)
      end
    end
  end

  context "#cancel!" do
    subject { intake.cancel! }

    let(:detail) do
      RampRefiling.create!(
        ramp_election: completed_ramp_election,
        veteran_file_number: veteran_file_number
      )
    end

    it "cancels and deletes the refiling record created" do
      subject

      expect(intake.reload).to be_canceled
      expect { detail.reload }.to raise_error ActiveRecord::RecordNotFound
    end
  end
end
