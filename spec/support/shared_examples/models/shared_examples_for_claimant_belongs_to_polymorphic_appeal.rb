# frozen_string_literal: true

require "query_subscriber"

# rubocop:disable Layout/LineLength

# @param claimant_subclass [Class] a subclass of `Claimant`
shared_examples "Claimant belongs_to polymorphic appeal" do |claimant_subclass|
  context do
    context "'appeal'-related associations" do
      it { should belong_to(:decision_review) }
      it { should belong_to(:ama_appeal).class_name("Appeal").with_foreign_key(:decision_review_id).optional }
      it { should belong_to(:legacy_appeal).class_name("LegacyAppeal").with_foreign_key(:decision_review_id).optional }
      it { should belong_to(:higher_level_review).class_name("HigherLevelReview").with_foreign_key(:decision_review_id).optional }
      it { should belong_to(:supplemental_claim).class_name("SupplementalClaim").with_foreign_key(:decision_review_id).optional }

      describe "ama_appeal" do
        context "when used in `joins` query" do
          subject { claimant_subclass.joins(:ama_appeal) }

          # Create records having different `decision_review_type` but the same `decision_review_id`. This will ensure
          # the test fails in the case where the `joins` result contains duplicate entries for records having the same
          # `decision_review_id` but different `decision_review_type`.
          let(:shared_id) { 99_999 }
          let!(:_legacy_claimant) do
            create(:claimant, type: claimant_subclass.to_s,
                              decision_review: create(:legacy_appeal, vacols_case: create(:case), id: shared_id))
          end

          context "when there are no Claimants with AMA appeals" do
            it { should be_none }
          end

          context "when there are Claimants with AMA appeals" do
            let!(:ama_claimant) do
              create(:claimant, :ama, type: claimant_subclass.to_s,
                                      decision_review: create(:appeal, number_of_claimants: 0, id: shared_id))
            end

            it { should contain_exactly(ama_claimant) }
          end
        end

        context "when eager loading with `includes`" do
          subject { claimant_subclass.ama.includes(:decision_review) }

          let!(:_legacy_claimant) { create(:claimant, :legacy, type: claimant_subclass.to_s) }

          context "when there are no Claimants with AMA appeals" do
            it { should be_none }
          end

          context "when there are Claimants with AMA appeals" do
            let!(:ama_claimants) { create_list(:claimant, 10, :ama, type: claimant_subclass.to_s) }

            it { should contain_exactly(*ama_claimants) }

            it "prevents N+1 queries" do
              QuerySubscriber.new.tap do |subscriber|
                subscriber.track { subject.map { |record| record.decision_review.id } }
                expect(subscriber.queries.count).to eq 2
              end
            end
          end
        end

        context "when eager loading with `preload`" do
          subject { claimant_subclass.ama.preload(:decision_review) }

          let!(:_legacy_claimant) { create(:claimant, :legacy, type: claimant_subclass.to_s) }

          context "when there are no Claimants with AMA appeals" do
            it { should be_none }
          end

          context "when there are Claimants with AMA appeals" do
            let!(:ama_claimants) { create_list(:claimant, 10, :ama, type: claimant_subclass.to_s) }

            it { should contain_exactly(*ama_claimants) }

            it "prevents N+1 queries" do
              QuerySubscriber.new.tap do |subscriber|
                subscriber.track { subject.map { |record| record.decision_review.id } }
                expect(subscriber.queries.count).to eq 2
              end
            end
          end
        end
      end

      describe "legacy_appeal" do
        context "when used in `joins` query" do
          subject { claimant_subclass.joins(:legacy_appeal) }

          # Create records having different `decision_review_type` but the same `decision_review_id`. This will ensure
          # the test fails in the case where the `joins` result contains duplicate entries for records having the same
          # `decision_review_id` but different `decision_review_type`.
          let(:shared_id) { 99_999 }
          let!(:_ama_claimant) do
            create(:claimant, :ama, type: claimant_subclass.to_s,
                                    decision_review: create(:appeal, number_of_claimants: 0, id: shared_id))
          end

          context "when there are no Claimants with Legacy appeals" do
            it { should be_none }
          end

          context "when there are Claimants with Legacy appeals" do
            let!(:legacy_claimant) do
              create(:claimant, type: claimant_subclass.to_s,
                                decision_review: create(:legacy_appeal, vacols_case: create(:case), id: shared_id))
            end

            it { should contain_exactly(legacy_claimant) }
          end
        end

        context "when eager loading with `includes`" do
          subject { claimant_subclass.legacy.includes(:decision_review) }

          let!(:_ama_claimants) { create_list(:claimant, 10, :ama, type: claimant_subclass.to_s) }

          context "when there are no Claimants with Legacy appeals" do
            it { should be_none }
          end

          context "when there are Claimants with Legacy appeals" do
            let!(:legacy_claimants) { create(:claimant, :legacy, type: claimant_subclass.to_s) }

            it { should contain_exactly(*legacy_claimants) }

            it "prevents N+1 queries" do
              QuerySubscriber.new.tap do |subscriber|
                subscriber.track { subject.map { |record| record.decision_review.id } }
                expect(subscriber.queries.count).to eq 2
              end
            end
          end
        end

        context "when eager loading with `preload`" do
          subject { claimant_subclass.legacy.preload(:decision_review) }

          let!(:_ama_claimants) { create_list(:claimant, 10, :ama, type: claimant_subclass.to_s) }

          context "when there are no Claimants with Legacy appeals" do
            it { should be_none }
          end

          context "when there are Claimants with Legacy appeals" do
            let!(:legacy_claimants) { create(:claimant, :legacy, type: claimant_subclass.to_s) }

            it { should contain_exactly(*legacy_claimants) }

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
          subject { claimant_subclass.joins(:higher_level_review) }

          # Create records having different `decision_review_type` but the same `decision_review_id`. This will ensure
          # the test fails in the case where the `joins` result contains duplicate entries for records having the same
          # `decision_review_id` but different `decision_review_type`.
          let(:shared_id) { 99_999 }
          let!(:_legacy_claimant) do
            create(:claimant, type: claimant_subclass.to_s,
                              decision_review: create(:legacy_appeal, vacols_case: create(:case), id: shared_id))
          end

          context "when there are no Claimants with HigherLevelReviews" do
            it { should be_none }
          end

          context "when there are Claimants with HigherLevelReviews" do
            let!(:higher_level_review_claimant) do
              create(:claimant, type: claimant_subclass.to_s, decision_review: higher_level_review)
            end
            let(:higher_level_review) do
              create(:higher_level_review, number_of_claimants: 0, benefit_type: "vha", id: shared_id)
            end

            it { should contain_exactly(higher_level_review_claimant) }
          end
        end

        context "when eager loading with `preload`" do
          subject { claimant_subclass.higher_level_review.preload(:decision_review) }

          let!(:_legacy_claimant) { create(:claimant, :legacy, type: claimant_subclass.to_s) }

          context "when there are no Claimants with HigherLevelReviews" do
            it { should be_none }
          end

          context "when there are Claimants with HigherLevelReviews" do
            let!(:higher_level_review_claimants) do
              create_list(:claimant, 10, :higher_level_review, type: claimant_subclass.to_s)
            end

            it { should contain_exactly(*higher_level_review_claimants) }

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
          subject { claimant_subclass.joins(:supplemental_claim) }

          # Create records having different `decision_review_type` but the same `decision_review_id`. This will ensure
          # the test fails in the case where the `joins` result contains duplicate entries for records having the same
          # `decision_review_id` but different `decision_review_type`.
          let(:shared_id) { 99_999 }
          let!(:_legacy_claimant) do
            create(:claimant, type: claimant_subclass.to_s,
                              decision_review: create(:legacy_appeal, vacols_case: create(:case), id: shared_id))
          end

          context "when there are no Claimants with SupplementalClaims" do
            it { should be_none }
          end

          context "when there are Claimants with SupplementalClaims" do
            let!(:supplemental_claim_claimant) do
              create(:claimant, type: claimant_subclass.to_s, decision_review: supplemental_claim)
            end
            let(:supplemental_claim) do
              create(:supplemental_claim, number_of_claimants: 0, benefit_type: "vha", id: shared_id)
            end

            it { should contain_exactly(supplemental_claim_claimant) }
          end
        end

        context "when eager loading with `preload`" do
          subject { claimant_subclass.supplemental_claim.preload(:decision_review) }

          let!(:_legacy_claimant) { create(:claimant, :legacy, type: claimant_subclass.to_s) }

          context "when there are no Claimants with SupplementalClaims" do
            it { should be_none }
          end

          context "when there are Claimants with SupplementalClaims" do
            let!(:supplemental_claim_claimants) do
              create_list(:claimant, 10, :supplemental_claim, type: claimant_subclass.to_s)
            end

            it { should contain_exactly(*supplemental_claim_claimants) }

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
      let!(:ama_claimants) { create_list(:claimant, 2, :ama, type: claimant_subclass.to_s) }
      let!(:legacy_claimants) { create_list(:claimant, 2, :legacy, type: claimant_subclass.to_s) }
      let!(:higher_level_review_claimants) { create_list(:claimant, 2, :higher_level_review, type: claimant_subclass.to_s) }
      let!(:supplemental_claim_claimants) { create_list(:claimant, 2, :supplemental_claim, type: claimant_subclass.to_s) }

      describe ".ama" do
        it "returns only Claimants belonging to AMA appeals" do
          expect(claimant_subclass.ama).to be_an(ActiveRecord::Relation)
          expect(claimant_subclass.ama).to contain_exactly(*ama_claimants)
        end
      end

      describe ".legacy" do
        it "returns only Claimants belonging to Legacy appeals" do
          expect(claimant_subclass.legacy).to be_an(ActiveRecord::Relation)
          expect(claimant_subclass.legacy).to contain_exactly(*legacy_claimants)
        end
      end

      describe ".higher_level_review" do
        it "returns only Claimants belonging to Legacy appeals" do
          expect(claimant_subclass.higher_level_review).to be_an(ActiveRecord::Relation)
          expect(claimant_subclass.higher_level_review).to contain_exactly(*higher_level_review_claimants)
        end
      end

      describe ".supplemental_claim" do
        it "returns only Claimants belonging to Legacy appeals" do
          expect(claimant_subclass.supplemental_claim).to be_an(ActiveRecord::Relation)
          expect(claimant_subclass.supplemental_claim).to contain_exactly(*supplemental_claim_claimants)
        end
      end
    end
  end
end
# rubocop:enable Layout/LineLength
