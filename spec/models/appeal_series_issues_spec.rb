# frozen_string_literal: true

describe AppealSeriesIssues, :all_dbs do
  before do
    Timecop.freeze(Time.utc(2015, 1, 1, 12, 0, 0))
  end

  let(:vacols_id) { "12345678" }
  let!(:series) { AppealSeries.create(appeals: appeals) }
  let(:appeals) { [original, post_remand] }

  let(:original) do
    create(:legacy_appeal, vacols_case: create(
      :case,
      :type_original,
      :disposition_remanded,
      bfkey: vacols_id,
      bfddec: 6.months.ago,
      case_issues: original_issues
    ))
  end

  let(:post_remand) do
    create(:legacy_appeal, vacols_case: create(
      :case,
      :type_post_remand,
      bfmpro: "ACT",
      case_issues: post_remand_issues
    ))
  end

  let(:original_issues) do
    [
      create(
        :case_issue,
        :disposition_remanded,
        issseq: 1,
        issdcls: 6.months.ago,
        issprog: "02",
        isscode: "15",
        isslev1: "03",
        isslev2: "5252"
      ),
      create(
        :case_issue,
        :disposition_allowed,
        issseq: 2,
        issdcls: 6.months.ago,
        issprog: "02",
        isscode: "15",
        isslev1: "04",
        isslev2: "5301"
      )
    ]
  end

  let(:post_remand_issues) do
    [create(:case_issue, issseq: 1, issprog: "02", isscode: "15", isslev1: "03", isslev2: "5252")]
  end

  let(:cavc_decision) do
    CAVCDecision.new(
      appeal_vacols_id: vacols_id,
      issue_vacols_sequence_id: 1,
      decision_date: 1.month.ago,
      disposition: "CAVC Vacated and Remanded"
    )
  end

  let(:combined_issues) do
    AppealSeriesIssues.new(appeal_series: series).all.sort_by { |issue_hash| issue_hash[:diagnostic_code] }
  end

  context "#all" do
    subject { combined_issues }

    context "when an issue spans a remand" do
      it "combines issues together" do
        expect(subject.length).to eq(2)
        expect(subject.first[:description]).to eq(
          "Service connection, limitation of thigh motion (flexion)"
        )
        expect(subject.first[:active]).to be_truthy
        expect(subject.first[:lastAction]).to eq(:remand)
        expect(subject.first[:date]).to eq(6.months.ago.to_date)
        expect(subject.last[:description]).to eq(
          "New and material evidence to reopen claim for service connection, shoulder or arm muscle injury"
        )
        expect(subject.last[:active]).to be_falsey
        expect(subject.last[:lastAction]).to eq(:allowed)
        expect(subject.last[:date]).to eq(6.months.ago.to_date)
      end

      context "when there is a draft decision" do
        let(:post_remand_issues) do
          [create(:case_issue,
                  :disposition_allowed,
                  issdcls: 1.day.ago,
                  issseq: 1,
                  issprog: "02",
                  isscode: "15",
                  isslev1: "03",
                  isslev2: "5252")]
        end

        it "does not show the draft disposition" do
          expect(subject.length).to eq(2)
          expect(subject.first[:active]).to be_truthy
          expect(subject.first[:date]).to eq(6.months.ago.to_date)
          expect(subject.first[:lastAction]).to eq(:remand)
        end
      end
    end

    context "when a remand has not yet returned" do
      let(:appeals) { [original] }

      it "is marked as active" do
        expect(subject.first[:active]).to be_truthy
      end
    end

    context "when there are no issues on one appeal" do
      let(:original_issues) { [] }

      it "returns issues" do
        expect(subject.first[:description]).to eq("Service connection, limitation of thigh motion (flexion)")
      end
    end

    context "when there are no issues on any appeal" do
      let(:original_issues) { [] }
      let(:post_remand_issues) { [] }

      it "returns an empty array" do
        expect(subject).to eq([])
      end
    end

    context "when an appeal was merged" do
      let(:appeals) { [original, merged_appeal] }
      let(:merged_appeal) do
        create(:legacy_appeal, vacols_case: create(
          :case,
          :type_post_remand,
          :disposition_merged,
          bfddec: 3.months.ago,
          bfdpdcn: 6.months.ago,
          case_issues: [create(:case_issue, :disposition_merged, issdcls: 3.months.ago)]
        ))
      end

      it "does not show as a last_action" do
        expect(subject.first[:lastAction]).to eq(:remand)
      end
    end

    context "when a cavc remand has occurred" do
      before do
        CAVCDecision.repository.cavc_decision_records = [cavc_decision]
      end

      it "appears as the last action" do
        expect(subject.first[:lastAction]).to eq(:cavc_remand)
        expect(subject.first[:date]).to eq(1.month.ago.to_date)
      end
    end
  end
end
