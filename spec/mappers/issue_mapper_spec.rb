describe IssueMapper do
  context ".transform_issue_attrs" do
    let(:issue_attrs) do
      {
        program: "02",
        issue: "18",
        level_2: "03",
        level_3: nil,
        note: "another one"
      }
    end

    let(:expected_result) do
      # level_1 is not passed, level_3 is passed with nil value
      {
        issprog: "02",
        isscode: "18",
        isslev2: "03",
        isslev3: nil,
        issdesc: "another one"
      }
    end

    subject { IssueMapper.rename_and_validate_vacols_attrs(issue_attrs) }

    context "when codes are valid" do
      it "transforms the hash" do
        allow(IssueRepository).to receive(:find_issue_reference).and_return([OpenStruct.new])
        expect(subject).to eq expected_result
      end
    end

    context "when codes are not valid" do
      it "raises IssueRepository::IssueError" do
        allow(IssueRepository).to receive(:find_issue_reference).and_return([])
        expect { subject }.to raise_error(IssueRepository::IssueError)
      end
    end
  end
end
