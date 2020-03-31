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
        expect(subject.buffer).to eq([legacy_appeal.vacols_id])
      end

      context "when Legacy Appeal has only cancelled tasks" do
        let!(:legacy_appeal) do
          create(:legacy_appeal, :with_judge_assign_task).tap { |legapp| legapp.tasks.each(&:cancelled!) }
        end

        it "reports zero missing cases" do
          subject.call
          expect(subject.report?).to be_falsey
          expect(subject.buffer).to eq []
        end
      end
    end
  end
end
