# frozen_string_literal: true

require "query_subscriber"

shared_examples "DecisionIssue belongs_to polymorphic appeal" do
  context do
    context "'appeal'-related associations" do
      describe "ama_appeal" do
        context "when used in `joins` query" do
          subject { DecisionIssue.joins(:ama_appeal) }

          # Create records having different `decision_review_type` but the same `decision_review_id`. This will ensure
          # the test fails in  the case where the `joins` result contains duplicate entries for records having the same
          # `decision_review_id` but different `decision_review_type`.
          let(:shared_id) { 99_999 }
          let!(:_supplemental_claim_decision_issue) do
            create(:decision_issue, decision_review: create(:supplemental_claim, number_of_claimants: 0, id: shared_id))
          end

          context "when there are no DecisionIssues with AMA appeals" do
            it { should be_none }
          end

          context "when there are DecisionIssues with AMA appeals" do
            let!(:ama_decision_issue) do
              create(:decision_issue, decision_review: create(:appeal, id: shared_id))
            end

            it { should contain_exactly(ama_decision_issue) }
          end
        end

        context "when eager loading with `includes`" do
          subject { DecisionIssue.ama.includes(:decision_review) }

          let!(:_supplemental_claim_decision_issue) { create(:decision_issue, :supplemental_claim) }

          context "when there are no DecisionIssues with AMA appeals" do
            it { should be_none }
          end

          context "when there are DecisionIssues with AMA appeals" do
            let!(:ama_decision_issues) { create_list(:decision_issue, 10, :ama) }

            it { should contain_exactly(*ama_decision_issues) }

            it "prevents N+1 queries" do
              QuerySubscriber.new.tap do |subscriber|
                subscriber.track { subject.map { |record| record.decision_review.id } }
                expect(subscriber.queries.count).to eq 2
              end
            end
          end
        end

        context "when eager loading with `preload`" do
          subject { DecisionIssue.ama.preload(:decision_review) }

          let!(:_supplemental_claim_decision_issue) { create(:decision_issue, :supplemental_claim) }

          context "when there are no DecisionIssues with AMA appeals" do
            it { should be_none }
          end

          context "when there are DecisionIssues with AMA appeals" do
            let!(:ama_decision_issues) { create_list(:decision_issue, 10, :ama) }

            it { should contain_exactly(*ama_decision_issues) }

            it "prevents N+1 queries" do
              QuerySubscriber.new.tap do |subscriber|
                subscriber.track { subject.map { |record| record.decision_review.id } }
                expect(subscriber.queries.count).to eq 2
              end
            end
          end
        end
      end

      describe "higher_level_review" do
        context "when used in `joins` query" do
          subject { DecisionIssue.joins(:higher_level_review) }

          # Create records having different `decision_review_type` but the same `decision_review_id`. This will ensure
          # the test fails in  the case where the `joins` result contains duplicate entries for records having the same
          # `decision_review_id` but different `decision_review_type`.
          let(:shared_id) { 99_999 }
          let!(:_supplemental_claim_decision_issue) do
            create(:decision_issue, decision_review: create(:supplemental_claim, number_of_claimants: 0, id: shared_id))
          end

          context "when there are no DecisionIssues with HigherLevelReviews" do
            it { should be_none }
          end

          context "when there are DecisionIssues with HigherLevelReviews" do
            let!(:higher_level_review_decision_issue) { create(:decision_issue, decision_review: higher_level_review) }
            let(:higher_level_review) do
              create(:higher_level_review, benefit_type: "vha", id: shared_id)
            end

            it { should contain_exactly(higher_level_review_decision_issue) }
          end
        end

        context "when eager loading with `preload`" do
          subject { DecisionIssue.higher_level_review.preload(:decision_review) }

          let!(:_supplemental_claim_decision_issue) { create(:decision_issue, :supplemental_claim) }

          context "when there are no DecisionIssues with HigherLevelReviews" do
            it { should be_none }
          end

          context "when there are DecisionIssues with HigherLevelReviews" do
            let!(:higher_level_review_decision_issues) { create_list(:decision_issue, 10, :higher_level_review) }

            it { should contain_exactly(*higher_level_review_decision_issues) }

            it "prevents N+1 queries" do
              QuerySubscriber.new.tap do |subscriber|
                subscriber.track { subject.map { |record| record.decision_review.id } }
                expect(subscriber.queries.count).to eq 2
              end
            end
          end
        end
      end

      describe "supplemental_claim" do
        context "when used in `joins` query" do
          subject { DecisionIssue.joins(:supplemental_claim) }

          # Create records having different `decision_review_type` but the same `decision_review_id`. This will ensure
          # the test fails in  the case where the `joins` result contains duplicate entries for records having the same
          # `decision_review_id` but different `decision_review_type`.
          let(:shared_id) { 99_999 }
          let!(:_ama_decision_issue) do
            create(:decision_issue, decision_review: create(:appeal, id: shared_id))
          end

          context "when there are no DecisionIssues with SupplementalClaims" do
            it { should be_none }
          end

          context "when there are DecisionIssues with SupplementalClaims" do
            let!(:supplemental_claim_decision_issue) { create(:decision_issue, decision_review: supplemental_claim) }
            let(:supplemental_claim) do
              create(:supplemental_claim, benefit_type: "vha", id: shared_id)
            end

            it { should contain_exactly(supplemental_claim_decision_issue) }
          end
        end

        context "when eager loading with `preload`" do
          subject { DecisionIssue.supplemental_claim.preload(:decision_review) }

          let!(:_ama_decision_issue) { create(:decision_issue, :ama) }

          context "when there are no DecisionIssues with SupplementalClaims" do
            it { should be_none }
          end

          context "when there are DecisionIssues with SupplementalClaims" do
            let!(:supplemental_claim_decision_issues) { create_list(:decision_issue, 10, :supplemental_claim) }

            it { should contain_exactly(*supplemental_claim_decision_issues) }

            it "prevents N+1 queries" do
              QuerySubscriber.new.tap do |subscriber|
                subscriber.track { subject.map { |record| record.decision_review.id } }
                expect(subscriber.queries.count).to eq 2
              end
            end
          end
        end
      end
    end

    context "'appeal'-related scopes" do
      let!(:ama_decision_issues) { create_list(:decision_issue, 2, :ama) }
      let!(:higher_level_review_decision_issues) { create_list(:decision_issue, 2, :higher_level_review) }
      let!(:supplemental_claim_decision_issues) { create_list(:decision_issue, 2, :supplemental_claim) }

      describe ".ama" do
        it "returns only DecisionIssues belonging to AMA appeals" do
          expect(DecisionIssue.ama).to be_an(ActiveRecord::Relation)
          expect(DecisionIssue.ama).to contain_exactly(*ama_decision_issues)
        end
      end

      describe ".higher_level_review" do
        it "returns only DecisionIssues belonging to Legacy appeals" do
          expect(DecisionIssue.higher_level_review).to be_an(ActiveRecord::Relation)
          expect(DecisionIssue.higher_level_review).to contain_exactly(*higher_level_review_decision_issues)
        end
      end

      describe ".supplemental_claim" do
        it "returns only DecisionIssues belonging to Legacy appeals" do
          expect(DecisionIssue.supplemental_claim).to be_an(ActiveRecord::Relation)
          expect(DecisionIssue.supplemental_claim).to contain_exactly(*supplemental_claim_decision_issues)
        end
      end
    end
  end
end
