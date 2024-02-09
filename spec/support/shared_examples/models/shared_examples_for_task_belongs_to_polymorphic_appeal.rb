# frozen_string_literal: true

require "query_subscriber"

# rubocop:disable Layout/LineLength
shared_examples "Task belongs_to polymorphic appeal" do
  context do
    context "'appeal'-related associations" do
      it { should belong_to(:appeal) }
      it { should belong_to(:ama_appeal).class_name("Appeal").with_foreign_key(:appeal_id).optional }
      it { should belong_to(:legacy_appeal).class_name("LegacyAppeal").with_foreign_key(:appeal_id).optional }
      it { should belong_to(:higher_level_review).class_name("HigherLevelReview").with_foreign_key(:appeal_id).optional }
      it { should belong_to(:supplemental_claim).class_name("SupplementalClaim").with_foreign_key(:appeal_id).optional }

      describe "ama_appeal" do
        context "when used in `joins` query" do
          subject { Task.joins(:ama_appeal) }

          # Create records having different `appeal_type` but the same `appeal_id`. This will ensure the test fails in
          # the case where the `joins` result contains duplicate entries for records having the same `appeal_id` but
          # different `appeal_type`.
          let(:shared_id) { 99_999 }
          let!(:_legacy_task) { create(:task, appeal: create(:legacy_appeal, id: shared_id)) }

          context "when there are no Tasks with AMA appeals" do
            it { should be_none }
          end

          context "when there are Tasks with AMA appeals" do
            let!(:ama_task) { create(:ama_task, appeal: create(:appeal, id: shared_id)) }

            it { should contain_exactly(ama_task) }
          end
        end

        context "when eager loading with `includes`" do
          subject { Task.ama.includes(:appeal) }

          let!(:_legacy_task) { create(:task) }

          context "when there are no Tasks with AMA appeals" do
            it { should be_none }
          end

          context "when there are Tasks with AMA appeals" do
            let!(:ama_tasks) { create_list(:ama_task, 10) }

            it { should contain_exactly(*ama_tasks) }

            it "prevents N+1 queries" do
              QuerySubscriber.new.tap do |subscriber|
                subscriber.track { subject.map { |record| record.appeal.id } }
                expect(subscriber.queries.count).to eq 2
              end
            end
          end
        end

        context "when eager loading with `preload`" do
          subject { Task.ama.preload(:appeal) }

          let!(:_legacy_task) { create(:task) }

          context "when there are no Tasks with AMA appeals" do
            it { should be_none }
          end

          context "when there are Tasks with AMA appeals" do
            let!(:ama_tasks) { create_list(:ama_task, 10) }

            it { should contain_exactly(*ama_tasks) }

            it "prevents N+1 queries" do
              QuerySubscriber.new.tap do |subscriber|
                subscriber.track { subject.map { |record| record.appeal.id } }
                expect(subscriber.queries.count).to eq 2
              end
            end
          end
        end
      end

      describe "legacy_appeal" do
        context "when used in `joins` query" do
          subject { Task.joins(:legacy_appeal) }

          # Create records having different `appeal_type` but the same `appeal_id`. This will ensure the test fails in
          # the case where the `joins` result contains duplicate entries for records having the same `appeal_id` but
          # different `appeal_type`.
          let(:shared_id) { 99_999 }
          let!(:_ama_task) { create(:ama_task, appeal: create(:appeal, id: shared_id)) }

          context "when there are no Tasks with Legacy appeals" do
            it { should be_none }
          end

          context "when there are Tasks with Legacy appeals" do
            let!(:legacy_task) { create(:task, appeal: create(:legacy_appeal, id: shared_id)) }

            it { should contain_exactly(legacy_task) }
          end
        end

        context "when eager loading with `includes`" do
          subject { Task.legacy.includes(:appeal) }

          let!(:_ama_task) { create(:ama_task) }

          context "when there are no Tasks with Legacy appeals" do
            it { should be_none }
          end

          context "when there are Tasks with Legacy appeals" do
            let!(:legacy_tasks) { create_list(:task, 10) }

            it { should contain_exactly(*legacy_tasks) }

            it "prevents N+1 queries" do
              QuerySubscriber.new.tap do |subscriber|
                subscriber.track { subject.map { |record| record.appeal.id } }
                expect(subscriber.queries.count).to eq 2
              end
            end
          end
        end

        context "when eager loading with `preload`" do
          subject { Task.legacy.preload(:appeal) }

          let!(:_ama_task) { create(:ama_task) }

          context "when there are no Tasks with Legacy appeals" do
            it { should be_none }
          end

          context "when there are Tasks with Legacy appeals" do
            let!(:legacy_tasks) { create_list(:task, 10) }

            it { should contain_exactly(*legacy_tasks) }

            it "prevents N+1 queries" do
              QuerySubscriber.new.tap do |subscriber|
                subscriber.track { subject.map { |record| record.appeal.id } }
                expect(subscriber.queries.count).to eq 2
              end
            end
          end
        end
      end

      describe "higher_level_review" do
        context "when used in `joins` query" do
          subject { Task.joins(:higher_level_review) }

          # Create records having different `appeal_type` but the same `appeal_id`. This will ensure the test fails in
          # the case where the `joins` result contains duplicate entries for records having the same `appeal_id` but
          # different `appeal_type`.
          let(:shared_id) { 99_999 }
          let!(:_ama_task) { create(:ama_task, appeal: create(:appeal, id: shared_id)) }

          context "when there are no Tasks with HigherLevelReviews" do
            it { should be_none }
          end

          context "when there are Tasks with HigherLevelReviews" do
            let!(:higher_level_review_task) do
              create(:higher_level_review_task, appeal: create(:higher_level_review, id: shared_id))
            end

            it { should contain_exactly(higher_level_review_task) }
          end
        end

        context "when eager loading with `includes`" do
          subject { Task.higher_level_review.includes(:appeal) }

          let!(:_ama_task) { create(:ama_task) }

          context "when there are no Tasks with HigherLevelReviews" do
            it { should be_none }
          end

          context "when there are Tasks with HigherLevelReviews" do
            let!(:higher_level_review_tasks) { create_list(:higher_level_review_task, 10) }

            it { should contain_exactly(*higher_level_review_tasks) }

            it "prevents N+1 queries" do
              QuerySubscriber.new.tap do |subscriber|
                subscriber.track { subject.map { |record| record.appeal.id } }
                expect(subscriber.queries.count).to eq 2
              end
            end
          end
        end

        context "when eager loading with `preload`" do
          subject { Task.higher_level_review.preload(:appeal) }

          let!(:_ama_task) { create(:ama_task) }

          context "when there are no Tasks with HigherLevelReviews" do
            it { should be_none }
          end

          context "when there are Tasks with HigherLevelReviews" do
            let!(:higher_level_review_tasks) { create_list(:higher_level_review_task, 10) }

            it { should contain_exactly(*higher_level_review_tasks) }

            it "prevents N+1 queries" do
              QuerySubscriber.new.tap do |subscriber|
                subscriber.track { subject.map { |record| record.appeal.id } }
                expect(subscriber.queries.count).to eq 2
              end
            end
          end
        end
      end

      describe "supplemental_claim" do
        context "when used in `joins` query" do
          subject { Task.joins(:supplemental_claim) }

          # Create records having different `appeal_type` but the same `appeal_id`. This will ensure the test fails in
          # the case where the `joins` result contains duplicate entries for records having the same `appeal_id` but
          # different `appeal_type`.
          let(:shared_id) { 99_999 }
          let!(:_ama_task) { create(:ama_task, appeal: create(:appeal, id: shared_id)) }

          context "when there are no Tasks with SupplementalClaims" do
            it { should be_none }
          end

          context "when there are Tasks with SupplementalClaims" do
            let!(:supplemental_claim_task) do
              create(:supplemental_claim_task, appeal: create(:supplemental_claim, id: shared_id))
            end

            it { should contain_exactly(supplemental_claim_task) }
          end
        end

        context "when eager loading with `includes`" do
          subject { Task.supplemental_claim.includes(:appeal) }

          let!(:_ama_task) { create(:ama_task) }

          context "when there are no Tasks with SupplementalClaims" do
            it { should be_none }
          end

          context "when there are Tasks with SupplementalClaims" do
            let!(:supplemental_claim_tasks) { create_list(:supplemental_claim_task, 10) }

            it { should contain_exactly(*supplemental_claim_tasks) }

            it "prevents N+1 queries" do
              QuerySubscriber.new.tap do |subscriber|
                subscriber.track { subject.map { |record| record.appeal.id } }
                expect(subscriber.queries.count).to eq 2
              end
            end
          end
        end

        context "when eager loading with `preload`" do
          subject { Task.supplemental_claim.preload(:appeal) }

          let!(:_ama_task) { create(:ama_task) }

          context "when there are no Tasks with SupplementalClaims" do
            it { should be_none }
          end

          context "when there are Tasks with SupplementalClaims" do
            let!(:supplemental_claim_tasks) { create_list(:supplemental_claim_task, 10) }

            it { should contain_exactly(*supplemental_claim_tasks) }

            it "prevents N+1 queries" do
              QuerySubscriber.new.tap do |subscriber|
                subscriber.track { subject.map { |record| record.appeal.id } }
                expect(subscriber.queries.count).to eq 2
              end
            end
          end
        end
      end
    end

    context "'appeal'-related scopes" do
      let!(:ama_tasks) { create_list(:ama_task, 2) }
      let!(:legacy_tasks) { create_list(:task, 2) }
      let!(:higher_level_review_tasks) { create_list(:higher_level_review_task, 2) }
      let!(:supplemental_claim_tasks) { create_list(:supplemental_claim_task, 2) }

      describe ".ama" do
        it "returns only Tasks belonging to AMA appeals" do
          expect(Task.ama).to be_an(ActiveRecord::Relation)
          expect(Task.ama).to contain_exactly(*ama_tasks)
        end
      end

      describe ".legacy" do
        it "returns only Tasks belonging to Legacy appeals" do
          expect(Task.legacy).to be_an(ActiveRecord::Relation)
          expect(Task.legacy).to contain_exactly(*legacy_tasks)
        end
      end

      describe ".higher_level_review" do
        it "returns only Tasks belonging to HigherLevelReviews" do
          expect(Task.higher_level_review).to be_an(ActiveRecord::Relation)
          expect(Task.higher_level_review).to contain_exactly(*higher_level_review_tasks)
        end
      end

      describe ".supplemental_claim" do
        it "returns only Tasks belonging to SupplementalClaims" do
          expect(Task.supplemental_claim).to be_an(ActiveRecord::Relation)
          expect(Task.supplemental_claim).to contain_exactly(*supplemental_claim_tasks)
        end
      end
    end
  end
end
# rubocop:enable Layout/LineLength
