describe WorksheetIssue do
  context ".create_from_issue" do
    let(:appeal) { Generators::Appeal.create }
    let(:issue) { Generators::Issue.build }

    subject { WorksheetIssue.create_from_issue(appeal, issue) }

    it "should create a worksheet issue" do
      expect(WorksheetIssue.all.size).to eq 0
      subject
      expect(WorksheetIssue.all.size).to eq 1
      expect(subject.program).to eq issue.program.to_s.capitalize
      expect(subject.levels).to eq issue.levels_with_codes.join("; ")
      expect(subject.description).to eq issue.formatted_program_type_levels
      expect(subject.notes).to eq issue.note
      expect(subject.name).to eq issue.type
      expect(subject.from_vacols).to eq true
    end
  end
end
