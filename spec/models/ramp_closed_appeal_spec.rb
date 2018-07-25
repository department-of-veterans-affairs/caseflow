describe RampClosedAppeal do
  before do
    FeatureToggle.enable!(:test_facols)
    Timecop.freeze(Time.utc(2019, 1, 1, 12, 0, 0))
    RequestStore[:current_user] = user
  end

  after do
    FeatureToggle.disable!(:test_facols)
  end

  let(:vacols_case) { create(:case, :status_advance) }
  let(:appeal) { create(:legacy_appeal, vacols_case: vacols_case) }
  let(:ep_status) { "PEND" }
  let(:partial_closure_issue_sequence_ids) { nil }
  let(:user) { Generators::User.build }

  let(:end_product) do
    Generators::EndProduct.build(
      veteran_file_number: appeal.veteran_file_number,
      bgs_attrs: { status_type_code: ep_status }
    )
  end

  let(:ramp_election) do
    build(:ramp_election,
          veteran_file_number: appeal.veteran_file_number,
          option_selected: :higher_level_review,
          receipt_date: 6.days.ago,
          established_at: 2.days.ago)
  end

  let(:ramp_closed_appeal) do
    RampClosedAppeal.create!(
      vacols_id: appeal.vacols_id,
      nod_date: 2.years.ago,
      ramp_election: ramp_election,
      partial_closure_issue_sequence_ids: partial_closure_issue_sequence_ids
    )
  end

  context "#partial?" do
    subject { ramp_closed_appeal.partial? }

    context "when partial_closure_issue_sequence_ids are nil" do
      it { is_expected.to be_falsey }
    end

    context "when partial_closure_issue_sequence_ids are set" do
      let(:partial_closure_issue_sequence_ids) { [1, 2, 3] }
      it { is_expected.to be_truthy }
    end
  end

  context "#reclose!" do
    subject { ramp_closed_appeal.reclose! }

    context "when end product was canceled" do
      let!(:current_end_product) do
        end_product.tap do |_ep|
          EndProductEstablishment.create(
            source: ramp_election,
            veteran_file_number: ramp_election.veteran_file_number,
            last_synced_at: Time.zone.now,
            synced_status: "CAN"
          )
        end
      end
      let(:ep_status) { "CAN" }

      it "rolls back the Caseflow ramp election" do
        expect(LegacyAppeal).to_not receive(:reopen)
        expect(LegacyAppeal).to_not receive(:close)

        subject

        expect { ramp_closed_appeal.reload }.to raise_error ActiveRecord::RecordNotFound
        expect(ramp_election).to_not be_established
      end
    end

    context "when appeal is in history status" do
      let(:vacols_case) { create(:case, :reopenable, bfdc: "B") }

      it "reopens the election and closes it with as a RAMP Opt-in" do
        subject

        expect(vacols_case.reload.bfdc).to eq("P")
      end

      context "when appeal was decided by BVA" do
        let(:vacols_case) { create(:case, :status_complete, :disposition_allowed) }

        it "raises error" do
          expect { subject }.to raise_error(RampClosedAppeal::NoReclosingBvaDecidedAppeals)
        end
      end
    end

    context "when appeal is not in history status" do
      it "closes the appeal without reopening it" do
        expect(LegacyAppeal).to_not receive(:reopen)
        expect(LegacyAppeal).to receive(:close)

        subject
      end

      context "when it was a partial closure" do
        let(:issue) { create(:case_issue) }
        let(:vacols_case) { create(:case, case_issues: [issue]) }
        let(:partial_closure_issue_sequence_ids) { [issue.issseq] }

        it "only recloses the issues with a P" do
          subject

          expect(vacols_case.reload.bfdc).to_not eq("P")
          expect(issue.reload.issdc).to eq("P")
        end
      end
    end
  end

  context ".reclose_all!" do
    subject { RampClosedAppeal.reclose_all! }

    let!(:other_ramp_closed_appeals) do
      [
        RampClosedAppeal.create!(vacols_id: "SHANE1"),
        RampClosedAppeal.create!(vacols_id: "SHANE2")
      ]
    end

    let(:veteran) { Generators::Veteran.build(file_number: "23232323") }

    let(:ramp_election_canceled_ep) do
      create(:ramp_election,
             veteran_file_number: veteran.file_number,
             option_selected: :higher_level_review,
             receipt_date: 6.days.ago,
             established_at: 2.days.ago)
    end

    let!(:ramp_closed_appeals_canceled_ep) do
      [
        RampClosedAppeal.create!(
          vacols_id: "CANCELED1",
          nod_date: 2.years.ago,
          ramp_election: ramp_election_canceled_ep
        ),
        RampClosedAppeal.create!(
          vacols_id: "CANCELED2",
          nod_date: 1.year.ago,
          ramp_election: ramp_election_canceled_ep
        )
      ]
    end

    before do
      expect(AppealRepository).to receive(:find_ramp_reopened_appeals)
        .with(%w[SHANE1 SHANE2 CANCELED1 CANCELED2] + [appeal.vacols_id])
        .and_return([
                      ramp_closed_appeal.appeal,
                      OpenStruct.new(vacols_id: "CANCELED1"),
                      OpenStruct.new(vacols_id: "CANCELED2")
                    ])
      EndProductEstablishment.create(
        source: ramp_election_canceled_ep,
        veteran_file_number: veteran.file_number,
        last_synced_at: 2.days.ago,
        synced_status: "CAN"
      )
    end

    it "finds reopened appeals based off of ramp closed appeals and recloses them" do
      subject

      # Test it recloses appeal with no canceled EP
      expect(vacols_case.reload.bfdc).to eq("P")

      # Test it rolls back Ramp Election if canceled EP
      expect(ramp_election_canceled_ep.reload.established_at).to be_nil
      expect { ramp_closed_appeals_canceled_ep.first.reload }.to raise_error ActiveRecord::RecordNotFound
      expect { ramp_closed_appeals_canceled_ep.last.reload }.to raise_error ActiveRecord::RecordNotFound
    end
  end
end
