describe AppealSeries do
  context "#latest_appeal" do
    let(:series) { AppealSeries.create(appeals: appeals) }
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
end
