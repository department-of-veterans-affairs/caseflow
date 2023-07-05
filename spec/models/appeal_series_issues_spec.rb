# frozen_string_literal: true

describe AppealSeriesIssues, :all_dbs do
  before do
    Timecop.freeze(Time.utc(2015, 1, 1, 12, 0, 0))
  end

  let(:vacols_id) { "12345678" }
  let(:series) { AppealSeries.create(appeals: appeals) }
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
    AppealSeriesIssues.new(appeal_series: series).all
  end

  let(:combined_issues_array) do
    [
      {
        description: "Service connection, limitation of thigh motion (flexion)",
        diagnosticCode: "5252",
        active: true,
        lastAction: :remand,
        date: 6.months.ago.to_date
      },
      {
        description: "New and material evidence to reopen claim for service connection,"\
          " shoulder or arm muscle injury",
        diagnosticCode: "5301",
        active: false,
        lastAction: :allowed,
        date: 6.months.ago.to_date
      }
    ]
  end

  context "#all" do
    subject { combined_issues }

    context "when an issue spans a remand" do
      it "combines issues together" do
        expect(subject.length).to eq(2)
        expect(subject).to match_array(combined_issues_array)
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
          expect(subject).to match_array(combined_issues_array)
        end
      end
    end

    context "when a remand has not yet returned" do
      let(:appeals) { [original] }

      it "is marked as active" do
        expect(subject).to match_array(combined_issues_array)
      end
    end

    context "when there are no issues on one appeal" do
      let(:original_issues) { [] }

      it "returns issues" do
        expect(subject).to match_array(combined_issues_array)
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
        expect(subject.length).to eq(3)
        other_hash = {
          description: "Other",
          diagnosticCode: nil,
          active: false,
          lastAction: nil,
          date: nil
        }
        expect(subject).to match_array(combined_issues_array.push(other_hash))
      end
    end

    context "when a cavc remand has occurred" do
      before do
        CAVCDecision.repository.cavc_decision_records = [cavc_decision]
      end

      it "appears as the last action" do
        expect(subject.length).to eq(2)
        expect(subject).to include(
          a_hash_including(
            lastAction: :cavc_remand,
            date: 1.month.ago.to_date
          )
        )
      end
    end
  end
end
