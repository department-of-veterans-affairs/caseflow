describe AppealSeriesAlerts do
  before do
    Timecop.freeze(Time.utc(2015, 1, 1, 12, 0, 0))
  end

  let(:vacols_id) { "12345678" }
  let(:series) { AppealSeries.create(appeals: appeals) }
  let(:appeals) { [original, post_remand] }

  let(:original) do
    Generators::Appeal.build(
      vacols_id: vacols_id,
      decision_date: 6.months.ago,
      disposition: "Remanded",
      issues: original_issues
    )
  end

  let(:post_remand) do
    Generators::Appeal.build(
      type: "Post Remand",
      prior_decision_date: 6.months.ago,
      disposition: "Remanded",
      issues: post_remand_issues
    )
  end

  let(:original_issues) do
    [
      Generators::Issue.build(
        id: vacols_id,
        vacols_sequence_id: 1,
        disposition: :remanded,
        close_date: 6.months.ago
      ),
      Generators::Issue.build(
        id: vacols_id,
        vacols_sequence_id: 2,
        codes: %w[02 15 04 5301],
        labels: ["Compensation", "Service connection", "New and material", "Muscle injury, Group I"],
        disposition: :allowed,
        close_date: 6.months.ago
      )
    ]
  end

  let(:post_remand_issues) do
    [Generators::Issue.build(
      id: vacols_id,
      vacols_sequence_id: 1,
      disposition: nil,
      close_date: nil
    )]
  end

  let(:cavc_decision) do
    CAVCDecision.new(
      appeal_vacols_id: vacols_id,
      issue_vacols_sequence_id: 1,
      decision_date: 1.month.ago,
      disposition: "CAVC Vacated and Remanded"
    )
  end

  let(:combined_issues) { AppealSeriesIssues.new(appeal_series: series).all }

  context "#all" do
    subject { combined_issues }

    context "when an issue spans a remand" do
      it "combines issues together" do
        expect(subject.length).to eq(2)
        expect(subject.first[:description]).to eq(
          "Service connection, limitation of thigh motion"
        )
        expect(subject.first[:active]).to be_truthy
        expect(subject.first[:last_action]).to eq(:remand)
        expect(subject.first[:date]).to eq(6.months.ago.to_date)
        expect(subject.last[:description]).to eq(
          "New and material evidence for service connection, shoulder or arm muscle injury"
        )
        expect(subject.last[:active]).to be_falsey
        expect(subject.last[:last_action]).to eq(:allowed)
        expect(subject.last[:date]).to eq(6.months.ago.to_date)
      end
    end

    context "when a remand has not yet returned" do
      let(:appeals) { [original] }

      it "is marked as active" do
        expect(subject.first[:active]).to be_truthy
      end
    end

    context "when there are no issues on one appeal" do
      let(:original_issues) { [] }

      it "returns issues" do
        expect(subject.first[:description]).to eq("Service connection, limitation of thigh motion")
      end
    end

    context "when there are no issues on any appeal" do
      let(:original_issues) { [] }
      let(:post_remand_issues) { [] }

      it "returns an empty array" do
        expect(subject).to eq([])
      end
    end

    context "when an appeal was merged" do
      let(:appeals) { [original, merged_appeal] }
      let(:merged_appeal) do
        Generators::Appeal.build(
          type: "Post Remand",
          prior_decision_date: 6.months.ago,
          decision_date: 3.months.ago,
          disposition: "Merged",
          issues: [Generators::Issue.build(disposition: :merged, close_date: 3.months.ago)]
        )
      end

      it "does not show as a last_action" do
        expect(subject.first[:last_action]).to eq(:remand)
      end
    end

    context "when a cavc remand has occurred" do
      before do
        CAVCDecision.repository.cavc_decision_records = [cavc_decision]
      end

      it "appears as the last action" do
        expect(subject.first[:last_action]).to eq(:cavc_remand)
        expect(subject.first[:date]).to eq(1.month.ago.to_date)
      end
    end
  end
end
