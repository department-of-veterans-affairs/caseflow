describe IssueRepository do

  context ".perform_actions_if_disposition_changes" do

    subject { IssueRepository.perform_actions_if_disposition_changes(record, issue_attrs) }
    let(:record) do
      OpenStruct.new(
        attributes_for_readjudication: {
          program: "02",
          issue: "01",
          level_1: "03",
          level_2: nil,
          level_3: nil,
          vacols_id: "123456",
          note: "note"
        },
        issdc: initial_disposition)
    end

    let(:issue_attrs) do
      {
        disposition: disposition,
        vacols_user_id: "TEST1",
        readjudication: readjudication
      }
    end
    context "when disposition is changed to vacated and readjudication is selected" do
      let(:initial_disposition) { nil }
      let(:disposition) { "Vacated" }
      let(:readjudication) { true }
      let(:result_params) do
        {
          program: "02",
          issue: "01",
          level_1: "03",
          level_2: nil,
          level_3: nil,
          vacols_id: "123456",
          note: "note",
          vacols_user_id: "TEST1"
        }
      end

      it "creates a duplicate issue" do
        expect(IssueRepository).to receive(:create_vacols_issue!)
          .with(issue_attrs: result_params).once
        subject
      end
    end

    context "when disposition is changed to vacated and readjudication is not selected" do
      let(:initial_disposition) { nil }
      let(:disposition) { "Vacated" }
      let(:readjudication) { false }

      it "does not create a duplicate issue" do
        expect(IssueRepository).to_not receive(:create_vacols_issue!)
        subject
      end
    end

    context "when disposition is not changed but readjudication is selected" do
      let(:initial_disposition) { "5" }
      let(:disposition) { "Vacated" }
      let(:readjudication) { true }

      it "does not create a duplicate issue" do
        expect(IssueRepository).to_not receive(:create_vacols_issue!)
        subject
      end
    end
  end
end