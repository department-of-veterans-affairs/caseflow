# frozen_string_literal: true

describe AppealHistory, :all_dbs do
  let(:original) do
    create(:legacy_appeal, vacols_case:
      create(
        :case,
        :type_original,
        bfcorlid: vbms_id,
        bfkey: "1234567",
        bfddec: 365.days.ago.to_date,
        case_issues:
          [
            create(:case_issue, issprog: "02", isscode: "01"),
            create(:case_issue, issprog: "02", isscode: "02"),
            create(:case_issue, issprog: "02", isscode: "03")
          ]
      ))
  end

  let(:another_original) do
    create(:legacy_appeal, vacols_case:
      create(
        :case,
        :type_original,
        bfcorlid: vbms_id,
        bfddec: 365.days.ago.to_date,
        case_issues:
          [
            create(:case_issue, issprog: "02", isscode: "03")
          ]
      ))
  end

  let(:merged) do
    create(:legacy_appeal, vacols_case:
      create(
        :case,
        :type_original,
        :disposition_merged,
        bfkey: "7654321",
        bfcorlid: vbms_id,
        bfddec: merged_appeal_decision_date
      ))
  end

  let(:merged_appeal_decision_date) { 500.days.ago.to_date }

  let(:another_merged) do
    create(:legacy_appeal, vacols_case:
      create(
        :case,
        :type_original,
        :disposition_merged,
        bfkey: "7654322",
        bfcorlid: vbms_id,
        bfddec: 500.days.ago.to_date
      ))
  end

  let(:history) { AppealHistory.new(vbms_id: vbms_id) }
  let(:vbms_id) { "111223333S" }

  context "#appeal_series" do
    subject { history.appeal_series }

    it "uses existing appeal series when possible" do
      original.save
      expect(original.appeal_series).to be_nil
      expect(subject.length).to eq 1
      expect(original.reload.appeal_series).to eq subject.first
      original.appeal_series.update(incomplete: true)
      history = AppealHistory.new(vbms_id: vbms_id)
      history.appeal_series
      expect(original.reload.appeal_series.incomplete).to be true
    end

    it "regenerates appeal series if a new appeal has been added" do
      original.save
      expect(subject.length).to eq 1
      original.reload.appeal_series.update(incomplete: true)
      another_original.save
      history = AppealHistory.new(vbms_id: vbms_id)
      expect(history.appeal_series.length).to eq 2
      expect(original.reload.appeal_series.incomplete).to be false
    end

    it "regenerates appeal series if an appeal has been merged" do
      original.save
      merged.save
      expect(subject.length).to eq 2
      original.reload.appeal_series.update(merged_appeal_count: 0, incomplete: true)
      history = AppealHistory.new(vbms_id: vbms_id)
      expect(history.appeal_series.length).to eq 2
      expect(original.reload.appeal_series.incomplete).to be false
    end

    context "matching on folder number for post-remand field dispositions" do
      let(:post_remand) do
        create(:legacy_appeal, vacols_case:
          create(
            :case,
            :type_post_remand,
            :disposition_granted_by_aoj,
            bfcorlid: vbms_id,
            bfkey: vacols_id
          ))
      end

      context "when there is a matching parent" do
        let(:vacols_id) { "1234567B" }

        it "creates a single, joined appeal series" do
          original.save
          post_remand.save
          expect(subject.length).to eq 1
          expect(original.reload.appeal_series).to eq post_remand.reload.appeal_series
        end
      end

      context "when there is no matching parent" do
        let(:vacols_id) { "7654321B" }

        it "marks the appeal series as incomplete" do
          original.save
          post_remand.save
          expect(subject.length).to eq 2
          expect(post_remand.reload.appeal_series.incomplete).to be true
        end
      end
    end

    context "matching on prior decision date" do
      let(:post_remand) do
        create(:legacy_appeal, vacols_case:
          create(
            :case,
            :type_post_remand,
            bfcorlid: vbms_id,
            bfdpdcn: prior_decision_date
          ))
      end

      context "when there is a single matching parent" do
        let(:prior_decision_date) { 365.days.ago.to_date }

        it "creates a single, joined appeal series" do
          original.save
          post_remand.save
          expect(subject.length).to eq 1
          expect(original.reload.appeal_series).to eq post_remand.reload.appeal_series
        end
      end

      context "when there is no matching parent" do
        let(:prior_decision_date) { 364.days.ago.to_date }

        it "marks the appeal series as incomplete" do
          original.save
          post_remand.save
          expect(subject.length).to eq 2
          expect(post_remand.reload.appeal_series.incomplete).to be true
        end
      end
    end

    context "matching on issues" do
      let(:post_remand) do
        create(:legacy_appeal, vacols_case:
          create(
            :case,
            :type_post_remand,
            bfcorlid: vbms_id,
            bfdpdcn: 365.days.ago.to_date,
            case_issues: issues
          ))
      end

      context "when there is a single matching parent" do
        let(:issues) do
          [
            create(:case_issue, issprog: "02", isscode: "01"),
            create(:case_issue, issprog: "02", isscode: "02")
          ]
        end

        it "creates a single, joined appeal series" do
          original.save
          another_original.save
          post_remand.save
          expect(subject.length).to eq 2
          expect(original.reload.appeal_series).to eq post_remand.reload.appeal_series
        end
      end

      context "when there are multiple matching parents" do
        let(:issues) do
          [
            create(:case_issue, issprog: "02", isscode: "03")
          ]
        end

        it "marks the appeal series as incomplete" do
          original.save
          another_original.save
          post_remand.save
          expect(subject.length).to eq 3
          expect(post_remand.reload.appeal_series.incomplete).to be true
        end
      end

      context "when there is no matching parent" do
        let(:issues) do
          [
            create(:case_issue, issprog: "02", isscode: "04")
          ]
        end

        it "marks the appeal series as incomplete" do
          original.save
          another_original.save
          post_remand.save
          expect(subject.length).to eq 3
          expect(post_remand.reload.appeal_series.incomplete).to be true
        end
      end
    end

    context "merging appeals" do
      let(:merge_target) do
        create(:legacy_appeal, vacols_case:
          create(
            :case,
            :type_original,
            bfcorlid: vbms_id,
            case_issues: [
              create(:case_issue, issdesc: description_1),
              create(:case_issue, issdesc: description_2)
            ]
          ))
      end

      context "decision date is nil" do
        let(:merged_appeal_decision_date) { nil }

        it "does not raise error" do
          original.save
          merged.save
          expect { subject }.to_not raise_error
        end
      end

      context "when there is a matching issue" do
        let(:description_1) do
          "left From appeal merged on #{500.days.ago.strftime('%m/%d/%y')} (7654321)"
        end

        let(:description_2) { "" }

        it "merges the series" do
          merged.save
          another_merged.save
          merge_target.save
          expect(subject.length).to eq 2
          expect(merged.reload.appeal_series).to eq merge_target.reload.appeal_series
          expect(merged.appeal_series.merged_appeal_count).to eq 2
        end
      end

      context "when the issue description is ambiguous" do
        let(:description_1) do
          "really really really really really really really really long note " \
          "From appeal merged on #{500.days.ago.strftime('%m/%d/%y')} (76"
        end

        let(:description_2) { "" }

        it "does not merge the series" do
          merged.save
          another_merged.save
          merge_target.save
          expect(subject.length).to eq 3
          expect(merged.reload.appeal_series.merged_appeal_count).to eq 2
        end
      end

      context "when there are multiple issues, some ambiguous" do
        let(:description_1) do
          "really really really really really really really really long note " \
          "From appeal merged on #{500.days.ago.strftime('%m/%d/%y')} (76"
        end

        let(:description_2) do
          "left From appeal merged on #{500.days.ago.strftime('%m/%d/%y')} (7654321)"
        end

        it "merges the series" do
          merged.save
          another_merged.save
          merge_target.save
          expect(subject.length).to eq 2
          expect(merged.reload.appeal_series).to eq merge_target.reload.appeal_series
          expect(merged.appeal_series.merged_appeal_count).to eq 2
        end
      end
    end
  end

  context ".for_api" do
    subject { AppealHistory.for_api(vbms_id: "999887777S") }

    let!(:veteran_appeals) do
      [
        create(:legacy_appeal, vacols_case: create(:case, bfcorlid: "999887777S")),
        create(:legacy_appeal, vacols_case: create(:case, bfcorlid: "999887777S"))
      ]
    end

    it "returns appeal series" do
      expect(subject.length).to eq(2)
    end
  end
end
