describe IssueMapper do
  context ".transform_issue_hash" do
    let(:issue_hash) do
      {
        program: { "description" => "compensation", "code" => "02" },
        issue: { "description" => "service connection", "code" => "18" },
        level_2: { "description" => "leg", "code" => "07" },
        level_3: { "description" => "head", "code" => "##" },
        note: "another one"
      }
    end

    let(:expected_result) do
      {
        program: "02",
        issue: "18",
        level_2: "07",
        level_3: "##",
        note: "another one"
      }
    end

    subject { IssueMapper.transform_and_validate(issue_hash) }

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
