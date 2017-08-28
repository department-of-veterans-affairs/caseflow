describe IssueRepository do
  before do
    @old_repo = Issue.repository
    Issue.repository = IssueRepository
  end
  after { Issue.repository = @old_repo }

  context ".load_vacols_data" do
    let(:appeal) { Appeal.new(vacols_id: "123C") }
    let(:issue) { Issue.new(appeal: appeal, vacols_sequence_id: "1") }
    subject { IssueRepository.load_vacols_data(issue) }
    it do
      issue.appeal.issues = [issue]
      is_expected.to eq(true)
    end
  end
end
