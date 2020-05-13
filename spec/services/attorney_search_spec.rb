# frozen_string_literal: true

describe AttorneySearch do
  describe "#fetch_attorneys" do
    subject { AttorneySearch.new(query_text).fetch_attorneys.map(&:name) }

    context "no words are provided" do
      let(:query_text) { "123 _no_words" }
      it { is_expected.to be_empty }
    end
  end
end
