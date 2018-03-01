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
        level_1: nil,
        level_2: "07",
        level_3: "##",
        note: "another one",
        vacols_id: nil
      }
    end

    subject { IssueMapper.transform_issue_hash(issue_hash) }

    it "transforms the hash" do
      expect(subject).to eq expected_result
    end
  end
end