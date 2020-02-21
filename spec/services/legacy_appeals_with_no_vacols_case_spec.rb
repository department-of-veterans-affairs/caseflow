# frozen_string_literal: true

describe LegacyAppealsWithNoVacolsCase do
  describe "#call" do
    context "when Caseflow and VACOLS match perfectly" do
      let!(:legacy_appeal) { create(:legacy_appeal, vacols_case: create(:case)) }

      it "reports nothing" do
        subject.call
        expect(subject.report?).to be_falsey
      end
    end

    context "when VACOLS case is missing" do
      let!(:legacy_appeal) { create(:legacy_appeal) }

      it "reports one missing case" do
        subject.call
        expect(subject.report?).to be_truthy
        expect(subject.report).to eq("LegacyAppeal.find_by(vacols_id: '#{legacy_appeal.vacols_id}')")
      end
    end
  end
end
