# frozen_string_literal: true

describe BusinessLine do
  subject { VhaBusinessLine.singleton }

  describe ".tasks_url" do
    it { expect(subject.tasks_url).to eq "/decision_reviews/vha" }
  end

  describe ".included_tabs" do
    it { expect(subject.included_tabs).to match_array [:incomplete, :in_progress, :completed] }
  end

  describe ".singleton" do
    it "is named correctly and has vha url" do
      expect(subject).to have_attributes(name: "Veterans Health Administration", url: "vha")
    end
  end

  describe ".tasks_query_type" do
    it "returns the correct task query types" do
      expect(subject.tasks_query_type).to eq(
        incomplete: "on_hold",
        in_progress: "active",
        completed: "recently_completed"
      )
    end
  end
end
