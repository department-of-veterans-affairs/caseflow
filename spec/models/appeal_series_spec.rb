describe AppealSeries do
  let(:series) { AppealSeries.create(appeals: appeals) }
  let(:appeals) { [latest_appeal] }
  let(:latest_appeal) do
    Generators::Appeal.build(
      nod_date: nod_date,
      soc_date: soc_date,
      form9_date: form9_date,
      certification_date: certification_date,
      decision_date: decision_date,
      disposition: disposition,
      location_code: location_code,
      status: status
    )
  end

  let(:nod_date) { 3.days.ago }
  let(:soc_date) { 1.day.ago }
  let(:form9_date) { 1.day.ago }
  let(:certification_date) { nil }
  let(:decision_date) { nil }
  let(:disposition) { nil }
  let(:location_code) { "77" }
  let(:status) { "Advance" }

  context "#latest_appeal" do
    subject { series.latest_appeal.vacols_id }

    context "when there are multiple active appeals" do
      let(:appeals) do
        [
          Generators::Appeal.build(
            vacols_id: "1234567",
            status: "Active",
            last_location_change_date: 1.day.ago
          ),
          Generators::Appeal.build(
            vacols_id: "7654321",
            status: "Active",
            last_location_change_date: 2.days.ago
          )
        ]
      end

      it { is_expected.to eq "1234567" }
    end

    context "when there are no active appeals" do
      let(:appeals) do
        [
          Generators::Appeal.build(
            vacols_id: "1234567",
            status: "Complete",
            decision_date: 1.day.ago
          ),
          Generators::Appeal.build(
            vacols_id: "7654321",
            status: "Complete",
            decision_date: 2.days.ago
          )
        ]
      end

      it { is_expected.to eq "1234567" }
    end
  end

  context "#location" do
    subject { series.location }

    context "when it is in advance status" do
      it { is_expected.to eq(:aoj) }
    end

    context "when it is in remand status" do
      let(:status) { "Remand" }
      it { is_expected.to eq(:aoj) }
    end

    context "when it is in any other status" do
      let(:status) { "History" }
      it { is_expected.to eq(:bva) }
    end
  end

  context "#status" do
    subject { series.status }

    context "when it is in advance status" do
      it { is_expected.to eq(:pending_certification) }

      context "and it has been certified" do
        let(:certification_date) { 1.day.ago }
        it { is_expected.to eq(:on_docket) }
      end

      context "and it has no form 9" do
        let(:form9_date) { nil }
        it { is_expected.to eq(:pending_form9) }

        context "and it has no soc" do
          let(:soc_date) { nil }
          it { is_expected.to eq(:pending_soc) }
        end
      end
    end

    context "when it is in active status" do
      let(:status) { "Active" }
      it { is_expected.to eq(:decision_in_progress) }

      context "and it is in location 49" do
        let(:location_code) { "49" }
        it { is_expected.to eq(:stayed) }
      end

      context "and it is in location 55" do
        let(:location_code) { "55" }
        it { is_expected.to eq(:at_vso) }
      end

      context "and it is in location 20" do
        let(:location_code) { "20" }
        it { is_expected.to eq(:opinion_request) }
      end

      context "and it is in location 18" do
        let(:location_code) { "18" }
        it { is_expected.to eq(:abeyance) }
      end
    end

    context "when it is in history status" do
      let(:status) { "Complete" }

      context "when decided by the board" do
        let(:disposition) { "Allowed" }
        it { is_expected.to eq(:bva_decision) }
      end

      context "when granted by the aoj" do
        let(:disposition) { "Advance Allowed in Field" }
        it { is_expected.to eq(:field_grant) }
      end

      context "when withdrawn" do
        let(:disposition) { "Withdrawn" }
        it { is_expected.to eq(:withdrawn) }
      end

      context "when ftr" do
        let(:disposition) { "Advance Failure to Respond" }
        it { is_expected.to eq(:ftr) }
      end

      context "when ramp" do
        let(:disposition) { "RAMP Opt-in" }
        it { is_expected.to eq(:ramp) }
      end

      context "when death" do
        let(:disposition) { "Dismissed, Death" }
        it { is_expected.to eq(:death) }
      end

      context "when reconsideration by letter" do
        let(:disposition) { "Reconsideration by Letter" }
        it { is_expected.to eq(:reconsideration) }
      end

      context "when any other disposition" do
        let(:disposition) { "Not a real disposition" }
        it { is_expected.to eq(:other_close) }
      end
    end

    context "when it is in remand status" do
      let(:status) { "Remand" }
      it { is_expected.to eq(:remand) }
    end

    context "when it is in motion status" do
      let(:status) { "Motion" }
      it { is_expected.to eq(:motion) }
    end

    context "when it is in cavc status" do
      let(:status) { "CAVC" }
      it { is_expected.to eq(:cavc) }
    end
  end

  context "#status_hash" do
    subject { series.status_hash }

    context "when there is a valid status" do
      it "returns a hash with a type and details" do
        expect(subject[:type]).to eq(:pending_certification)
        expect(subject[:details].is_a?(Hash)).to be_truthy
      end
    end

    context "when there is no known status" do
      let(:status) { "Not a real status" }

      it "returns an empty details hash" do
        expect(subject[:details]).to eq({})
      end
    end
  end

  context "#alerts" do
    subject { series.alerts }
    let(:form9_date) { nil }

    it "returns list of alerts" do
      expect(subject.length > 0).to be_truthy
      expect(subject.first[:type]).to eq(:form9_needed)
    end
  end
end
