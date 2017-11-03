describe AppealSeries do
  let(:original) do
    Generators::Appeal.build(
      vacols_id: "1234567",
      vbms_id: vbms_id,
      type: "Original",
      decision_date: 365.days.ago.to_date,
      issues: [
        Generators::Issue.build(program: :compensation, code: "01"),
        Generators::Issue.build(program: :compensation, code: "02"),
        Generators::Issue.build(program: :compensation, code: "03")
      ]
    )
  end

  let(:another_original) do
    Generators::Appeal.build(
      vbms_id: vbms_id,
      type: "Original",
      decision_date: 365.days.ago.to_date,
      issues: [
        Generators::Issue.build(program: :compensation, code: "03")
      ]
    )
  end

  let(:merged) do
    Generators::Appeal.build(
      vacols_id: "7654321",
      vbms_id: vbms_id,
      type: "Original",
      disposition: "Merged Appeal",
      decision_date: 500.days.ago.to_date
    )
  end

  let(:another_merged) do
    Generators::Appeal.build(
      vacols_id: "7654320",
      vbms_id: vbms_id,
      type: "Original",
      disposition: "Merged Appeal",
      decision_date: 500.days.ago.to_date
    )
  end

  let(:vbms_id) { "111223333S" }

  context ".appeal_series_by_vbms_id" do
    it "uses existing appeal series when possible" do
      original.save
      expect(original.appeal_series).to be_nil
      series = AppealSeries.appeal_series_by_vbms_id(vbms_id)
      expect(series.length).to eq 1
      expect(original.reload.appeal_series).to eq series.first
      original.appeal_series.update(incomplete: true)
      AppealSeries.appeal_series_by_vbms_id(vbms_id)
      expect(original.reload.appeal_series.incomplete).to be true
    end

    it "regenerates appeal series if a new appeal has been added" do
      original.save
      series = AppealSeries.appeal_series_by_vbms_id(vbms_id)
      expect(series.length).to eq 1
      original.reload.appeal_series.update(incomplete: true)
      another_original.save
      series = AppealSeries.appeal_series_by_vbms_id(vbms_id)
      expect(series.length).to eq 2
      expect(original.reload.appeal_series.incomplete).to be_nil
    end

    it "regenerates appeal series if an appeal has been merged" do
      original.save
      merged.save
      series = AppealSeries.appeal_series_by_vbms_id(vbms_id)
      expect(series.length).to eq 2
      original.reload.appeal_series.update(merged_appeal_count: 0, incomplete: true)
      series = AppealSeries.appeal_series_by_vbms_id(vbms_id)
      expect(series.length).to eq 2
      expect(original.reload.appeal_series.incomplete).to be_nil
    end

    context "matching on folder number for post-remand field dispositions" do
      let(:post_remand) do
        Generators::Appeal.build(
          vacols_id: vacols_id,
          vbms_id: vbms_id,
          type: "Post Remand",
          disposition: "Benefits Granted by AOJ"
        )
      end

      context "when there is a matching parent" do
        let(:vacols_id) { "1234567B" }

        it "creates a single, joined appeal series" do
          original.save
          post_remand.save
          series = AppealSeries.appeal_series_by_vbms_id(vbms_id)
          expect(series.length).to eq 1
          expect(original.reload.appeal_series).to eq post_remand.reload.appeal_series
        end
      end

      context "when there is no matching parent" do
        let(:vacols_id) { "7654321B" }

        it "marks the appeal series as incomplete" do
          original.save
          post_remand.save
          series = AppealSeries.appeal_series_by_vbms_id(vbms_id)
          expect(series.length).to eq 2
          expect(post_remand.reload.appeal_series.incomplete).to be true
        end
      end
    end

    context "matching on prior decision date" do
      let(:post_remand) do
        Generators::Appeal.build(
          vbms_id: vbms_id,
          type: "Post Remand",
          prior_decision_date: prior_decision_date
        )
      end

      context "when there is a single matching parent" do
        let(:prior_decision_date) { 365.days.ago.to_date }

        it "creates a single, joined appeal series" do
          original.save
          post_remand.save
          series = AppealSeries.appeal_series_by_vbms_id(vbms_id)
          expect(series.length).to eq 1
          expect(original.reload.appeal_series).to eq post_remand.reload.appeal_series
        end
      end

      context "when there is no matching parent" do
        let(:prior_decision_date) { 364.days.ago.to_date }

        it "marks the appeal series as incomplete" do
          original.save
          post_remand.save
          series = AppealSeries.appeal_series_by_vbms_id(vbms_id)
          expect(series.length).to eq 2
          expect(post_remand.reload.appeal_series.incomplete).to be true
        end
      end
    end

    context "matching on issues" do
      let(:post_remand) do
        Generators::Appeal.build(
          vbms_id: vbms_id,
          type: "Post Remand",
          prior_decision_date: 365.days.ago.to_date,
          issues: issues
        )
      end

      context "when there is a single matching parent" do
        let(:issues) do
          [
            Generators::Issue.build(program: :compensation, code: "01"),
            Generators::Issue.build(program: :compensation, code: "02")
          ]
        end

        it "creates a single, joined appeal series" do
          original.save
          another_original.save
          post_remand.save
          series = AppealSeries.appeal_series_by_vbms_id(vbms_id)
          expect(series.length).to eq 2
          expect(original.reload.appeal_series).to eq post_remand.reload.appeal_series
        end
      end

      context "when there are multiple matching parents" do
        let(:issues) do
          [Generators::Issue.build(program: :compensation, code: "03")]
        end

        it "marks the appeal series as incomplete" do
          original.save
          another_original.save
          post_remand.save
          series = AppealSeries.appeal_series_by_vbms_id(vbms_id)
          expect(series.length).to eq 3
          expect(post_remand.reload.appeal_series.incomplete).to be true
        end
      end

      context "when there is no matching parent" do
        let(:issues) do
          [Generators::Issue.build(program: :compensation, code: "04")]
        end

        it "marks the appeal series as incomplete" do
          original.save
          another_original.save
          post_remand.save
          series = AppealSeries.appeal_series_by_vbms_id(vbms_id)
          expect(series.length).to eq 3
          expect(post_remand.reload.appeal_series.incomplete).to be true
        end
      end
    end

    context "merging appeals" do
      let(:merge_target) do
        Generators::Appeal.build(
          vbms_id: vbms_id,
          type: "Original",
          issues: [
            Generators::Issue.build(description: description_1),
            Generators::Issue.build(description: description_2)
          ]
        )
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
          series = AppealSeries.appeal_series_by_vbms_id(vbms_id)
          expect(series.length).to eq 2
          expect(merged.reload.appeal_series).to eq merge_target.reload.appeal_series
          expect(merged.appeal_series.merged_appeal_count).to eq 2
        end
      end

      context "when the issue description is ambiguous" do
        let(:description_1) do
          # rubocop:disable Metrics/LineLength
          "really really really really really really really really long note From appeal merged on #{500.days.ago.strftime('%m/%d/%y')} (76"
          # rubocop:enable Metrics/LineLength
        end

        let(:description_2) { "" }

        it "does not merge the series" do
          merged.save
          another_merged.save
          merge_target.save
          series = AppealSeries.appeal_series_by_vbms_id(vbms_id)
          expect(series.length).to eq 3
          expect(merged.reload.appeal_series.merged_appeal_count).to eq 2
        end
      end

      context "when there are multiple issues, some ambiguous" do
        let(:description_1) do
          # rubocop:disable Metrics/LineLength
          "really really really really really really really really long note From appeal merged on #{500.days.ago.strftime('%m/%d/%y')} (76"
          # rubocop:enable Metrics/LineLength
        end

        let(:description_2) do
          "left From appeal merged on #{500.days.ago.strftime('%m/%d/%y')} (7654321)"
        end

        it "merges the series" do
          merged.save
          another_merged.save
          merge_target.save
          series = AppealSeries.appeal_series_by_vbms_id(vbms_id)
          expect(series.length).to eq 2
          expect(merged.reload.appeal_series).to eq merge_target.reload.appeal_series
          expect(merged.appeal_series.merged_appeal_count).to eq 2
        end
      end
    end
  end
end
