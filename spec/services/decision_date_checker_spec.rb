# frozen_string_literal: true

describe DecisionDateChecker, :postgres do
  let!(:request_issues) do
    [
      create(:request_issue, :nonrating, decision_date: 1.month.ago),
      create(:request_issue, :nonrating, decision_date: nil),
      create(:request_issue, :nonrating, decision_date: nil),
      create(:request_issue, :rating),
      create(:request_issue, :unidentified)
    ]
  end

  before(:all) do
    Seeds::NotificationEvents.new.seed!
  end

  context "# call" do
    it "should find request issues without decision dates" do
      subject.call
      expect(subject.report).to include(request_issues[1].id.to_s)
      expect(subject.report).to include(request_issues[2].id.to_s)
    end

    it "should not check rating issues" do
      subject.call
      expect(subject.report).not_to include(request_issues[3].id.to_s)
    end

    it "should not find unidentified" do
      subject.call
      expect(subject.report).not_to include(request_issues[4].id.to_s)
    end
  end
end
