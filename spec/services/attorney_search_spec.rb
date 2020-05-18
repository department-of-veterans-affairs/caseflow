# frozen_string_literal: true

describe AttorneySearch do
  let(:names) do
    [
      "JOHN SMITH",
      "MARILEE NIKOLAUS IV",
      "HUGH JACKMAN",
      "JAYMIE SMITHAM V",
      "BOYCE KOSS SR.",
      "ZELLA D'AMORE JR.",
      "TAINA TERRANCE-KLEIN",
      "JOHN SMITH"
    ]
  end
  let!(:attorneys) { names.map { |name| create(:bgs_attorney, name: name) } }
  let(:search) { AttorneySearch.new(query_text) }

  describe "#similarity_multiplier" do
    subject { AttorneySearch.similarity_multiplier(*name_pair) }

    context "names are identical" do
      let(:name_pair) { %w[BARRY barry] }
      it { is_expected.to eq 1.5 }
    end

    context "names are nearly the same" do
      let(:name_pair) { %w[BARRY barrey] }
      it { is_expected.to be_between(1.1, 1.4) }
    end

    context "names are different" do
      let(:name_pair) { %w[SHERY barry] }
      it { is_expected.to eq 1 }
    end
  end

  describe "#candidates" do
    subject { search.candidates.map(&:name) }

    context "no words are provided" do
      let(:query_text) { "123 _no_words" }
      it { is_expected.to be_empty }
    end

    context "one word matches multiple first letters" do
      let(:query_text) { "JONATHAN" }
      it {
        is_expected.to contain_exactly(
          "JOHN SMITH",
          "HUGH JACKMAN",
          "JAYMIE SMITHAM V",
          "ZELLA D'AMORE JR.",
          "JOHN SMITH"
        )
      }
    end
  end

  describe "#fetch_attorneys" do
    subject { search.fetch_attorneys.map(&:name) }

    context "query matches one name exactly" do
      let(:query_text) { "HUGH JACKMAN" }
      it { is_expected.to contain_exactly("HUGH JACKMAN") }
    end

    context "query matches a duplicate name" do
      let(:query_text) { "JON SMITHY" }
      it { is_expected.to start_with("JOHN SMITH", "JOHN SMITH") }
    end

    context "query approximately matches a name with apostrophe and abbreviation" do
      let(:query_text) { "ZELDA DAMORE JR" }
      it { is_expected.to start_with("ZELLA D'AMORE JR.") }
    end

    context "query approximately matches a hyphenated name" do
      let(:query_text) { "TAINA TERRENCE KLEIN" }
      it { is_expected.to start_with("TAINA TERRANCE-KLEIN") }
    end

    context "query has exact match on one name but high Dice's coefficient on another" do
      let(:names) { ["SHERY BARROWS", "BARRY JOHNSTON"] }
      let(:query_text) { "barry" }
      it { is_expected.to start_with("BARRY JOHNSTON") }
    end
  end
end
