# frozen_string_literal: true

describe VACOLS::Staff, :all_dbs do
  describe ".find_by_css_id" do
    let(:css_id) { "BVASTAFF" }
    let!(:staff) { create(:staff, sdomainid: css_id, sactive: "A") }
    let(:search_css_id) { css_id }
    subject { described_class.find_by_css_id(search_css_id) }

    context "when given valid CSS_ID" do
      it "returns corresponding Staff" do
        expect(subject).to eq staff
      end
    end
    context "when given invalid/unknown CSS_ID" do
      let(:search_css_id) { "INVALID_CSS_ID" }
      it "returns nil" do
        expect(subject).to be_nil
      end
    end
  end
end
