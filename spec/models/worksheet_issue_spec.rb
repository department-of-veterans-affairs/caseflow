# frozen_string_literal: true

describe WorksheetIssue, :postgres do
  context ".create_from_issue" do
    let(:appeal) { Generators::LegacyAppeal.create }
    let(:issue) { Generators::Issue.build }

    subject { WorksheetIssue.create_from_issue(appeal, issue) }

    it "should create a worksheet issue" do
      expect(WorksheetIssue.all.size).to eq 0
      subject
      expect(WorksheetIssue.all.size).to eq 1
      expect(subject.description).to eq issue.formatted_program_type_levels
      expect(subject.notes).to eq issue.note
      expect(subject.disposition).to eq issue.formatted_disposition
      expect(subject.from_vacols).to eq true
    end
  end
end
