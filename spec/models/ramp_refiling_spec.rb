# frozen_string_literal: true

describe RampRefiling, :postgres do
  before do
    Timecop.freeze(Time.utc(2018, 1, 1, 12, 0, 0))
    FeatureToggle.enable!(:ramp_intake)
  end

  after { FeatureToggle.disable!(:ramp_intake) }

  let(:user) { Generators::User.build }
  let!(:veteran) { Generators::Veteran.build(file_number: "64205555") }
  let(:veteran_file_number) { "64205555" }
  let(:detail) { nil }
  let(:original_election_option) { "higher_level_review" }
  let(:option_selected) { nil }
  let(:receipt_date) { nil }
  let(:appeal_docket) { nil }

  let!(:completed_ramp_election) do
    create(:ramp_election,
           veteran_file_number: veteran_file_number,
           notice_date: 3.days.ago,
           receipt_date: 2.days.ago,
           option_selected: original_election_option,
           established_at: 1.day.ago)
  end

  let(:ramp_refiling) do
    RampRefiling.new(
      veteran_file_number: veteran_file_number,
      receipt_date: receipt_date,
      option_selected: option_selected,
      appeal_docket: appeal_docket
    )
  end

  context ".need_to_reprocess" do
    subject { RampRefiling.need_to_reprocess }

    let!(:ramp_refiling_processed) do
      RampRefiling.create!(
        veteran_file_number: veteran_file_number,
        establishment_submitted_at: 2.minutes.ago,
        establishment_processed_at: 30.seconds.ago
      )
    end

    let!(:ramp_refiling_recently_submitted) do
      RampRefiling.create!(
        veteran_file_number: veteran_file_number,
        establishment_submitted_at: 1.minute.ago
      )
    end

    let!(:ramp_refiling_not_processed) do
      RampRefiling.create!(
        veteran_file_number: veteran_file_number,
        establishment_submitted_at: 2.minutes.ago
      )
    end

    it "returns unprocessed ramp elections processed a long time ago" do
      expect(subject).to contain_exactly(ramp_refiling_not_processed)
    end
  end

  context "#create_issues!" do
    before { ramp_refiling.save! }
    subject { ramp_refiling.create_issues!(source_issue_ids: source_issues.map(&:id)) }

    let!(:source_issues) do
      [
        completed_ramp_election.issues.create!(description: "Firsties"),
        completed_ramp_election.issues.create!(description: "Secondsies")
      ]
    end

    let!(:outdated_issue) do
      ramp_refiling.issues.create!(description: "i will be destroyed")
    end

    it "creates issues from the source_issue_ids" do
      subject
      expect(ramp_refiling.issues.count).to eq(2)
      expect(ramp_refiling.issues.first.description).to eq("Firsties")
    end
  end

  # The create_end_product! side is more thoroughly tested in ramp_election_spec.rb
  # This spec is more concerned with create_contentions!
  context "#create_end_product_and_contentions!" do
    subject { ramp_refiling.create_end_product_and_contentions! }

    before do
      ramp_refiling.save!
      Fakes::VBMSService.end_product_claim_id = "1337"

      allow(Fakes::VBMSService).to receive(:establish_claim!).and_call_original
      allow(Fakes::VBMSService).to receive(:create_contentions!).and_call_original
    end

    let(:receipt_date) { 1.day.ago }
    let(:option_selected) { "supplemental_claim" }

    let!(:issue_already_created) do
      ramp_refiling.issues.create!(description: "Already created", contention_reference_id: "123")
    end

    context "when no issues that need to be created in VBMS" do
      it "does not try and create end product or contentions" do
        expect(subject).to be_nil

        expect(Fakes::VBMSService).to_not have_received(:establish_claim!)
        expect(Fakes::VBMSService).to_not have_received(:create_contentions!)
      end
    end

    context "when issues need to have contentions created in VBMS" do
      let!(:issues) do
        [
          ramp_refiling.issues.create!(description: "Leg"),
          ramp_refiling.issues.create!(description: "Arm"),
          ramp_refiling.issues.create!(description: "Arm"), # intentional duplicate
          ramp_refiling.issues.create!(description: "Long Description" * 20)
        ]
      end
      let(:modifier) { RampReview::END_PRODUCT_DATA_BY_OPTION[option_selected][:modifier] }

      let!(:ramp_refiling_intake) do
        RampRefilingIntake.create!(
          veteran_file_number: veteran_file_number,
          detail: ramp_refiling,
          user: user
        )
      end

      context "when an issue is not created in VBMS" do
        # Issues with the description "FAIL ME" are configured to fail in Fakes::VBMSService
        let!(:issue_to_fail) do
          ramp_refiling.issues.create!(description: "FAIL ME")
        end

        it "doesn't raise error, but does not set establishment_processed_at" do
          subject

          # Even though there was a failure, we should still save the contention ids that were created
          expect(issues.first.reload.contention_reference_id).to_not be_nil
          expect(issues.second.reload.contention_reference_id).to_not be_nil
          expect(issues.third.reload.contention_reference_id).to_not be_nil
          expect(issue_to_fail.reload.contention_reference_id).to be_nil

          # When the contention fails the End Product Establishment should not be committed
          expect(ramp_refiling.end_product_establishment.established_at).to eq(Time.zone.now)
          expect(ramp_refiling.end_product_establishment.committed_at).to be_nil
          expect(ramp_refiling.establishment_processed_at).to be_nil
        end
      end

      context "when the EP is already established" do
        let!(:end_product_establishment) do
          create(
            :end_product_establishment,
            veteran_file_number: veteran_file_number,
            reference_id: "testtest",
            source: ramp_refiling,
            user: user
          )
        end

        it "creates contentions but doesn't establish the claim" do
          subject

          expect(Fakes::VBMSService).to_not have_received(:establish_claim!)

          expect(Fakes::VBMSService).to have_received(:create_contentions!).with(
            veteran_file_number: "64205555",
            claim_id: "testtest",
            contentions: [
              { description: "Arm" },
              { description: "Arm" },
              { description: "Leg" },
              { description: "#{('Long Description' * 20).slice(0, 252)}..." }
            ],
            user: user,
            claim_date: ramp_refiling.receipt_date.to_date
          )
        end
      end

      it "sends requests to VBMS to create both the end_product and the uncreated issues" do
        subject

        expect(Fakes::VBMSService).to have_received(:establish_claim!).with(
          hash_including(claim_hash: hash_including(end_product_modifier: modifier))
        )
        expect(Fakes::VBMSService).to have_received(:create_contentions!).with(
          veteran_file_number: "64205555",
          claim_id: "1337",
          contentions: [
            { description: "Arm" },
            { description: "Arm" },
            { description: "Leg" },
            { description: "#{('Long Description' * 20).slice(0, 252)}..." }
          ],
          user: user,
          claim_date: ramp_refiling.receipt_date.to_date
        )

        expect(issues.first.reload.contention_reference_id).to_not be_nil
        expect(ramp_refiling.end_product_establishment.committed_at).to eq(Time.zone.now)
        expect(ramp_refiling.establishment_processed_at).to eq(Time.zone.now)
        expect(ramp_refiling.end_product_establishment.contentions.count).to eq(4)
      end
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
      context "when orginal election was Higher-Level Review" do
        let(:original_election_option) { "higher_level_review" }

        context "when Higher-Level Review" do
          let(:option_selected) { "higher_level_review" }

          it "adds an error to option_selected" do
            is_expected.to be false
            expect(ramp_refiling.errors[:option_selected]).to include("higher_level_review_invalid")
          end
        end

        context "when Higher-Level Review with hearing" do
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

      context "when orginal election was Higher-Level Review with hearing" do
        let(:original_election_option) { "higher_level_review_with_hearing" }

        context "when Higher-Level Review" do
          let(:option_selected) { "higher_level_review" }

          it "adds an error to option_selected" do
            is_expected.to be false
            expect(ramp_refiling.errors[:option_selected]).to include("higher_level_review_invalid")
          end
        end

        context "when Higher-Level Review with hearing" do
          let(:option_selected) { "higher_level_review_with_hearing" }

          it "adds an error to option_selected" do
            is_expected.to be false
            expect(ramp_refiling.errors[:option_selected]).to include("higher_level_review_invalid")
          end
        end

        context "when another option" do
          let(:option_selected) { "appeal" }
          let(:appeal_docket) { Constants.AMA_DOCKETS.hearing }
          it { is_expected.to be true }
        end
      end

      context "when orginal election was supplemental claim" do
        let(:original_election_option) { "supplemental_claim" }

        context "when Higher-Level Review" do
          let(:option_selected) { "higher_level_review" }
          it { is_expected.to be true }
        end
      end
    end

    context "appeal docket" do
      context "if option selected isn't appeal" do
        let(:option_selected) { "supplemental_claim" }
        let(:appeal_docket) { Constants.AMA_DOCKETS.hearing }

        it "sets appeal_docket to nil" do
          is_expected.to be true
          expect(ramp_refiling.appeal_docket).to be_nil
        end
      end

      context "if option selected is appeal" do
        let(:option_selected) { "appeal" }

        context "when not valid" do
          let(:appeal_docket) { nil }

          it "adds an error to appeal_docket" do
            is_expected.to be false
            expect(ramp_refiling.errors[:appeal_docket]).to include("blank")
          end
        end

        context "when set to valid value" do
          let(:appeal_docket) { Constants.AMA_DOCKETS.hearing }

          it { is_expected.to be true }
        end
      end
    end
  end
end
