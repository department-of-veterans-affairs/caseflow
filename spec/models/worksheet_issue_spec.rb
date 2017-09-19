describe WorksheetIssue do
  context ".create_from_issue" do
    let(:appeal) { Generators::Appeal.create }
    let(:issue) { Generators::Issue.build }

    subject { WorksheetIssue.create_from_issue(appeal, issue) }

    it "should create a worksheet issue" do
      expect(WorksheetIssue.all.size).to eq 0
      subject
      expect(WorksheetIssue.all.size).to eq 1
    end
  end
end
