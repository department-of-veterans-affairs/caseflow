describe WorksheetIssue do
  context ".create_from_issue" do
    let(:appeal) { Generators::Appeal.create }
    let(:issue) { Generators::Issue.build }

    subject { WorksheetIssue.create_from_issue(appeal, issue) }

    it "should create a worksheet issue" do
      expect(WorksheetIssue.all.size).to eq 0
      subject
      expect(WorksheetIssue.all.size).to eq 1
      expect(subject.program).to eq issue.program.to_s
      expect(subject.levels).to eq issue.levels
      expect(subject.description).to eq issue.description
      expect(subject.name).to eq issue.type[:name].to_s
      expect(subject.from_vacols).to eq true
    end
  end
end
