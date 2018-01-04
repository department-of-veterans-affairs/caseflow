describe RampRefilingIntake do
  before do
    Timecop.freeze(Time.utc(2015, 1, 1, 12, 0, 0))
  end

  let(:user) { Generators::User.build }
  let!(:veteran) { Generators::Veteran.build(file_number: "64205555") }
  let(:veteran_file_number) { "64205555" }
  let(:detail) { nil }
  let(:original_election_option) { "higher_level_review" }
  let(:option_selected) { nil }
  let(:receipt_date) { nil }

  let(:completed_ramp_election) do
    RampElection.create!(
      veteran_file_number: "64205555",
      notice_date: 3.days.ago,
      receipt_date: 2.days.ago,
      option_selected: original_election_option,
      end_product_reference_id: "123"
    )
  end

  let(:ramp_refiling) do
    RampRefiling.new(
      ramp_election: completed_ramp_election,
      veteran_file_number: veteran_file_number,
      receipt_date: receipt_date,
      option_selected: option_selected
    )
  end

  context "#create_issues!" do
    before { ramp_refiling.save! }
    subject { ramp_refiling.create_issues!(source_issue_ids: source_issues.map(&:id)) }

    let(:source_issues) do
      [
        completed_ramp_election.issues.create!(description: "Firsties"),
        completed_ramp_election.issues.create!(description: "Secondsies")
      ]
    end

    let(:outdated_issue) do
      ramp_refiling.issues.create!(description: "i will be destroyed")
    end

    it "creates issues from the source_issue_ids" do
      subject
      expect(ramp_refiling.issues.count).to eq(2)
      expect(ramp_refiling.issues.first.description).to eq("Firsties")
    end
  end

  context "#valid?" do
    subject { ramp_refiling.valid? }

    context "receipt_date" do
      context "when it is nil" do
        it { is_expected.to be true }
      end

      context "when it is after today" do
        let(:receipt_date) { 1.day.from_now }

        it "adds an error to receipt_date" do
          is_expected.to be false
          expect(ramp_refiling.errors[:receipt_date]).to include("in_future")
        end
      end

      context "when it is before ramp election receipt date" do
        let(:receipt_date) { 3.days.ago }

        it "adds an error to receipt_date" do
          is_expected.to be false
          expect(ramp_refiling.errors[:receipt_date]).to include("before_ramp_receipt_date")
        end
      end

      context "when it is on or after ramp election receipt date and on or before today" do
        let(:receipt_date) { 1.day.ago }
        it { is_expected.to be true }
      end
    end

    context "option_selected" do
      context "when orginal election was higher level review" do
        let(:original_election_option) { "higher_level_review" }

        context "when higher level review" do
          let(:option_selected) { "higher_level_review" }

          it "adds an error to option_selected" do
            is_expected.to be false
            expect(ramp_refiling.errors[:option_selected]).to include("higher_level_review_invalid")
          end
        end

        context "when higher level review with hearing" do
          let(:option_selected) { "higher_level_review_with_hearing" }

          it "adds an error to option_selected" do
            is_expected.to be false
            expect(ramp_refiling.errors[:option_selected]).to include("higher_level_review_invalid")
          end
        end

        context "when another option" do
          let(:option_selected) { "supplemental_claim" }
          it { is_expected.to be true }
        end

        context "when nil" do
          let(:option_selected) { nil }
          it { is_expected.to be true }
        end
      end

      context "when orginal election was higher level review with hearing" do
        let(:original_election_option) { "higher_level_review_with_hearing" }

        context "when higher level review" do
          let(:option_selected) { "higher_level_review" }

          it "adds an error to option_selected" do
            is_expected.to be false
            expect(ramp_refiling.errors[:option_selected]).to include("higher_level_review_invalid")
          end
        end

        context "when higher level review with hearing" do
          let(:option_selected) { "higher_level_review_with_hearing" }

          it "adds an error to option_selected" do
            is_expected.to be false
            expect(ramp_refiling.errors[:option_selected]).to include("higher_level_review_invalid")
          end
        end

        context "when another option" do
          let(:option_selected) { "appeal" }
          it { is_expected.to be true }
        end
      end

      context "when orginal election was supplemental claim" do
        let(:original_election_option) { "supplemental_claim" }

        context "when higher level review" do
          let(:option_selected) { "higher_level_review" }
          it { is_expected.to be true }
        end
      end
    end
  end
end
