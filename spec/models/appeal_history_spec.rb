describe AppealHistory do
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
          expect(subject.length).to eq 2
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
          expect(subject.length).to eq 3
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
          expect(subject.length).to eq 3
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
            Generators::Issue.build(note: description_1),
            Generators::Issue.build(note: description_2)
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
          expect(subject.length).to eq 2
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
          expect(subject.length).to eq 3
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
          expect(subject.length).to eq 2
          expect(merged.reload.appeal_series).to eq merge_target.reload.appeal_series
          expect(merged.appeal_series.merged_appeal_count).to eq 2
        end
      end
    end
  end

  context ".for_api" do
    subject { AppealHistory.for_api(appellant_ssn: ssn) }

    let(:ssn) { "999887777" }

    let!(:veteran_appeals) do
      [
        Generators::Appeal.build(vbms_id: "999887777S"),
        Generators::Appeal.build(vbms_id: "999887777S")
      ]
    end

    it "returns appeal series" do
      expect(subject.length).to eq(2)
    end

    context "when ssn is nil" do
      let(:ssn) { nil }

      it "raises InvalidSSN error" do
        expect { subject }.to raise_error(Caseflow::Error::InvalidSSN)
      end
    end

    context "when ssn is less than 9 characters" do
      let(:ssn) { "99887777" }

      it "raises InvalidSSN error" do
        expect { subject }.to raise_error(Caseflow::Error::InvalidSSN)
      end
    end

    context "when ssn is more than 9 characters" do
      let(:ssn) { "9998877777" }

      it "raises InvalidSSN error" do
        expect { subject }.to raise_error(Caseflow::Error::InvalidSSN)
      end
    end

    context "when ssn is non-numeric" do
      let(:ssn) { "99988777A" }

      it "raises InvalidSSN error" do
        expect { subject }.to raise_error(Caseflow::Error::InvalidSSN)
      end
    end

    context "when SSN not found in BGS" do
      before do
        Fakes::BGSService.ssn_not_found = true
      end

      it "raises ActiveRecord::RecordNotFound error" do
        expect { subject }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
