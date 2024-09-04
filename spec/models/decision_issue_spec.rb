# frozen_string_literal: true

describe DecisionIssue, :postgres do
  include IntakeHelpers

  it_behaves_like "DecisionIssue belongs_to polymorphic appeal"

  before do
    Timecop.freeze(Time.utc(2018, 1, 1, 12, 0, 0))
  end

  let(:decision_issue) do
    create(
      :decision_issue,
      decision_review: decision_review,
      disposition: disposition,
      decision_text: decision_text,
      description: description,
      request_issues: request_issues,
      benefit_type: benefit_type,
      rating_profile_date: profile_date,
      rating_promulgation_date: promulgation_date,
      end_product_last_action_date: end_product_last_action_date,
      caseflow_decision_date: caseflow_decision_date,
      diagnostic_code: diagnostic_code
    )
  end

  let(:profile_date) { 20.days.ago }
  let(:promulgation_date) { 19.days.ago }
  let(:caseflow_decision_date) { 20.days.ago }
  let(:benefit_type) { "compensation" }
  let(:end_product_last_action_date) { 10.days.ago }
  let(:request_issues) { [] }
  let(:description) { "description" }
  let(:disposition) { "allowed" }
  let(:diagnostic_code) { nil }
  let(:decision_text) { "decision text" }
  let(:decision_date) { 10.days.ago }
  let(:decision_review) { create(:supplemental_claim, benefit_type: benefit_type) }

  context "scopes" do
    let!(:ri_contesting_decision_issue) { create(:request_issue, contested_decision_issue_id: decision_issue.id) }
    let!(:uncontested_di) { create(:decision_issue, disposition: "other") }
    let!(:uncontested_remand_di) { create(:decision_issue, disposition: "remanded") }
    let!(:uncontested_dta_di) { create(:decision_issue, disposition: "DTA Error - Fed Recs") }
    let!(:granted_di) { create(:decision_issue, disposition: "DTA Error - Fed Recs") }

    context ".contested" do
      it "matches decision issue that has been contested" do
        expect(DecisionIssue.contested).to eq([decision_issue])
        expect(DecisionIssue.contested).to_not include(uncontested_di)
      end
    end

    context ".uncontested" do
      it "matches decision issues that has not been contested" do
        expect(DecisionIssue.uncontested).to include(uncontested_di, uncontested_remand_di, uncontested_dta_di)
        expect(DecisionIssue.uncontested).to_not include(decision_issue)
      end
    end

    context ".remanded" do
      it "includes decision issues with remand and dta error dispositions" do
        expect(DecisionIssue.remanded).to include(uncontested_remand_di, uncontested_dta_di)
        expect(DecisionIssue.remanded).to_not include(decision_issue, uncontested_di)
      end
    end

    context ".not_remanded" do
      it "includes decision issues with remand and dta error dispositions" do
        expect(DecisionIssue.not_remanded).to include(decision_issue, uncontested_di)
        expect(DecisionIssue.not_remanded).to_not include(uncontested_remand_di, uncontested_dta_di)
      end
    end
  end

  context "#save" do
    subject { decision_issue.save }

    it "sets created at" do
      subject
      expect(decision_issue).to have_attributes(created_at: Time.zone.now)
    end

    context "when description is not set" do
      let(:description) { nil }

      context "when decision text is set" do
        it "sets description" do
          subject
          expect(decision_issue).to have_attributes(description: "decision text")
        end
      end

      context "when decision text is not set" do
        let(:decision_text) { nil }
        let(:request_issues) { [create(:request_issue, :rating, contested_issue_description: "req desc")] }

        it "sets description" do
          subject

          expect(decision_issue).to have_attributes(description: "allowed: req desc")
        end
      end
    end

    context "when description is already set" do
      let(:description) { "this is my decision" }

      it "doesn't overwrite description" do
        subject
        expect(decision_issue).to have_attributes(description: "this is my decision")
      end
    end
  end

  context "#valid?" do
    subject { decision_issue.valid? }

    let(:decision_issue) do
      build(
        :decision_issue,
        decision_review: decision_review,
        disposition: disposition,
        decision_text: decision_text,
        description: description,
        request_issues: request_issues,
        benefit_type: benefit_type,
        rating_profile_date: profile_date,
        end_product_last_action_date: end_product_last_action_date,
        diagnostic_code: diagnostic_code
      )
    end

    context "when it is valid" do
      it { is_expected.to be true }
    end

    context "when disposition is not set" do
      let(:disposition) { nil }

      it "adds an error to disposition" do
        is_expected.to be false
        expect(decision_issue.errors[:disposition]).to include("can't be blank")
      end
    end

    context "when benefit type is not in list" do
      let(:benefit_type) { "bogus_benefit_type" }

      it "adds an error to benefit_type" do
        is_expected.to be false
        expect(decision_issue.errors[:benefit_type]).to include("is not included in the list")
      end
    end

    context "when the decision review is an appeal" do
      let(:decision_review) { create(:appeal) }

      context "disposition" do
        context "when it is nil" do
          let(:disposition) { nil }

          it "adds an error to disposition" do
            is_expected.to be false
            expect(decision_issue.errors[:disposition]).to include("is not included in the list")
          end
        end

        context "when it is set to an allowed value" do
          let(:disposition) { "remanded" }
          it { is_expected.to be true }
        end

        context "when it is not an allowed value" do
          let(:disposition) { "bogus_disposition" }

          it "adds an error to disposition" do
            is_expected.to be false
            expect(decision_issue.errors[:disposition]).to include("is not included in the list")
          end
        end
      end

      context "diagnostic code" do
        context "when it is nil" do
          it { is_expected.to be true }
        end
      end
    end

    context "when the decision review is processed in Caseflow" do
      context "end_product_last_action_date is nil" do
        let(:end_product_last_action_date) { nil }

        it "adds an error to end_product_last_action_date" do
          is_expected.to be false
          expect(decision_issue.errors[:end_product_last_action_date]).to include("can't be blank")
        end
      end
    end
  end

  context "#finalized?" do
    subject { decision_issue.finalized? }

    context "decision_review is Appeal" do
      let(:description) { "something" }
      let(:disposition) { "denied" }

      context "is not outcoded" do
        let(:decision_review) { create(:appeal, :with_post_intake_tasks) }

        it { is_expected.to be_falsey }
      end

      context "is outcoded" do
        let(:decision_review) { create(:appeal, :outcoded) }

        it { is_expected.to be_truthy }
      end
    end

    context "decision_review is ClaimReview" do
      context "disposition is set" do
        let(:disposition) { "denied" }

        it { is_expected.to be_truthy }
      end
    end
  end

  context "#rating?" do
    subject { decision_issue.rating? }

    context "when there are no associated nonrating issues" do
      let(:request_issues) do
        [create(:request_issue, :rating)]
      end

      it { is_expected.to eq true }
    end

    context "when there is one associated nonrating issue" do
      let(:request_issues) do
        [create(:request_issue, :rating), create(:request_issue, :nonrating)]
      end

      it { is_expected.to eq false }
    end
  end

  context "#approx_decision_date" do
    subject { decision_issue.approx_decision_date }

    let(:profile_date) { 5.days.ago }
    let(:promulgation_date) { 4.days.ago }
    let(:end_product_last_action_date) { 6.days.ago }
    let(:caseflow_decision_date) { 7.days.ago }

    context "when the decision review is processed in caseflow" do
      context "when there is no promulgation date" do
        let(:promulgation_date) { nil }
        it "returns the end_product_last_action_date" do
          expect(subject).to eq(end_product_last_action_date.to_date)
        end

        context "when there is no last action date" do
          let(:decision_review) { create(:appeal) }
          let(:end_product_last_action_date) { nil }
          it "returns the caseflow decision date" do
            expect(subject).to eq(caseflow_decision_date.to_date)
          end
        end
      end

      context "when there is a promulgation date" do
        it "returns the promulgation_date to_date" do
          expect(subject).to eq(promulgation_date.to_date)
        end
      end
    end

    context "when the decision review is not processed in caseflow" do
      context "non-comp" do
        let(:benefit_type) { "education" }

        it "returns the caseflow_decision_date" do
          expect(subject).to eq(caseflow_decision_date.to_date)
        end
      end

      context "appeal" do
        let(:decision_review) { create(:appeal) }

        it "returns the caseflow_decision_date" do
          expect(subject).to eq(caseflow_decision_date.to_date)
        end
      end
    end
  end

  context "#nonrating_issue_category" do
    subject { decision_issue.nonrating_issue_category }

    let(:request_issues) do
      [create(
        :request_issue,
        nonrating_issue_category: "test category",
        nonrating_issue_description: "request issue description"
      )]
    end

    it "finds the issue category" do
      is_expected.to eq("test category")
    end
  end

  context "#find_or_create_remand_supplemental_claim!" do
    subject { decision_issue.find_or_create_remand_supplemental_claim! }

    context "when approx_decision_date is nil" do
      let(:decision_review) { create(:appeal) }
      let(:caseflow_decision_date) { nil }

      it "throws an error" do
        expect { subject }.to raise_error(
          StandardError, "approx_decision_date is required to create a DTA Supplemental Claim"
        )
      end
    end

    context "when there is an approx_decision_date" do
      let(:caseflow_decision_date) { 20.days.ago }

      context "when supplemental claim already exists matching decision issue" do
        let!(:matching_supplemental_claim) do
          create(
            :supplemental_claim,
            veteran_file_number: decision_review.veteran_file_number,
            decision_review_remanded: decision_review,
            benefit_type: "compensation"
          )
        end

        it "does not create a new supplemental claim" do
          expect do
            expect(subject).to eq(matching_supplemental_claim)
          end.to_not change(SupplementalClaim, :count)
        end
      end

      context "when no supplemental claim matches decision issue" do
        let(:veteran) { create(:veteran) }
        let(:decision_review) do
          create(
            :appeal,
            number_of_claimants: 1,
            veteran_file_number: veteran.file_number,
            veteran_is_not_claimant: true
          )
        end
        let!(:decision_document) { create(:decision_document, decision_date: decision_date, appeal: decision_review) }

        context "when there is a prior claim by the same claimant on the same veteran" do
          let(:prior_payee_code) { "10" }
          before do
            setup_prior_claim_with_payee_code(decision_review, veteran, prior_payee_code)
          end

          it "creates a new supplemental claim" do
            expect(subject).to have_attributes(
              veteran_file_number: decision_review.veteran_file_number,
              decision_review_remanded: decision_review,
              benefit_type: "compensation"
            )
            expect(subject.reload.claimants.count).to eq(1)
            expect(subject.claimant).to have_attributes(
              participant_id: decision_review.claimant_participant_id,
              payee_code: prior_payee_code,
              decision_review: subject
            )
          end
        end

        context "when there is no prior claim by the claimant" do
          context "when there is a bgs payee code" do
            before { allow_any_instance_of(DependentClaimant).to receive(:bgs_payee_code).and_return("12") }

            it "creates a new supplemental claim" do
              expect(subject).to have_attributes(
                veteran_file_number: decision_review.veteran_file_number,
                decision_review_remanded: decision_review,
                benefit_type: "compensation"
              )
              expect(subject.reload.claimants.count).to eq(1)
              expect(subject.claimant).to have_attributes(
                participant_id: decision_review.claimant_participant_id,
                payee_code: "12",
                decision_review: subject
              )
            end
          end

          context "when there is no bgs payee code" do
            before { allow_any_instance_of(DependentClaimant).to receive(:bgs_payee_code).and_return(nil) }

            it "raises an error" do
              expect { subject }.to raise_error(DecisionIssue::AppealDTAPayeeCodeError)

              # verify that both appeal and newly created dta sc have errors
              expect(SupplementalClaim.find_by(
                       veteran_file_number: decision_review.veteran_file_number,
                       establishment_error: "No payee code"
                     )).to_not be_nil
              expect(decision_review.establishment_error).to eq("DTA SC creation failed")
            end
          end
        end
      end
    end
  end
end
