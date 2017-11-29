describe AppealSeries do
  let(:series) { AppealSeries.create(appeals: appeals) }
  let(:appeals) { [latest_appeal] }
  let(:latest_appeal) do
    Generators::Appeal.build(
      nod_date: nod_date,
      soc_date: soc_date,
      form9_date: form9_date,
      decision_date: decision_date,
      location_code: location_code,
      status: status
    )
  end

  let(:nod_date) { 3.days.ago }
  let(:soc_date) { 1.day.ago }
  let(:form9_date) { 1.day.ago }
  let(:decision_date) { nil }
  let(:location_code) { '77' }
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
end
