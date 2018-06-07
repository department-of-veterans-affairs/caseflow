describe RampClosedAppeal do
  before do
    Timecop.freeze(Time.utc(2019, 1, 1, 12, 0, 0))
    FeatureToggle.enable!(:test_facols)
  end

  after do
    FeatureToggle.disable!(:test_facols)
  end

  let(:vacols_case) { create(:case) }
  let(:appeal) { create(:legacy_appeal, vacols_case: vacols_case) }
  let(:ep_status) { "PEND" }

  let(:end_product) do
    Generators::EndProduct.build(
      veteran_file_number: appeal.veteran_file_number,
      bgs_attrs: { status_type_code: ep_status }
    )
  end

  let(:ramp_election) do
    RampElection.new(
      veteran_file_number: appeal.veteran_file_number,
      option_selected: :higher_level_review,
      receipt_date: 6.days.ago,
      end_product_reference_id: end_product.claim_id,
      established_at: 2.days.ago
    )
  end

  let(:ramp_closed_appeal) do
    RampClosedAppeal.create!(
      vacols_id: appeal.vacols_id,
      nod_date: 2.years.ago,
      ramp_election: ramp_election
    )
  end

  context "#reclose!" do
    subject { ramp_closed_appeal.reclose! }

    context "when end product was canceled" do
      let!(:current_end_product) { end_product }
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
      let(:vacols_case) { create(:case, :status_complete) }

      it "reopens the election and closes it with as a RAMP Opt-in" do
        expect(LegacyAppeal).to receive(:reopen)
        expect(LegacyAppeal).to receive(:close)

        subject
      end
    end

    context "when appeal is not in history status" do
      it "closes the appeal without reopening it" do
        expect(LegacyAppeal).to_not receive(:reopen)
        expect(LegacyAppeal).to receive(:close)

        subject
      end
    end
  end

  context ".reclose_all!", focus: true do
    subject { RampClosedAppeal.reclose_all! }

    let!(:other_ramp_closed_appeals) do
      [
        RampClosedAppeal.create!(vacols_id: "SHANE1"),
        RampClosedAppeal.create!(vacols_id: "SHANE2")
      ]
    end

    let(:veteran) { Generators::Veteran.build(file_number: "23232323") }

    let(:canceled_end_product) do
      Generators::EndProduct.build(
        veteran_file_number: veteran.file_number,
        bgs_attrs: { status_type_code: "CAN" }
      )
    end

    let(:ramp_election_canceled_ep) do
      RampElection.create(
        veteran_file_number: veteran.file_number,
        option_selected: :higher_level_review,
        receipt_date: 6.days.ago,
        end_product_reference_id: canceled_end_product.claim_id,
        established_at: 2.days.ago
      )
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

    let(:user) { Generators::User.build }

    before do
      expect(AppealRepository).to receive(:find_ramp_reopened_appeals)
        .with(%w[SHANE1 SHANE2 CANCELED1 CANCELED2] + [appeal.vacols_id])
        .and_return([
                      ramp_closed_appeal.appeal,
                      OpenStruct.new(vacols_id: "CANCELED1"),
                      OpenStruct.new(vacols_id: "CANCELED2")
                    ])

      RequestStore[:current_user] = user
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
