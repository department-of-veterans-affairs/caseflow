# frozen_string_literal: true

require "query_subscriber"

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
          let(:shared_id) { 99999 }
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
          subject { Task.ama.includes(:ama_appeal) }

          let!(:_legacy_task) { create(:task) }

          context "when there are no Tasks with AMA appeals" do
            it { should be_none }
          end

          context "when there are Tasks with AMA appeals" do
            let!(:ama_tasks) { create_list(:ama_task, 10) }

            it { should contain_exactly(*ama_tasks) }

            it "prevents N+1 queries" do
              QuerySubscriber.new.tap do |subscriber|
                subscriber.track { subject.map { |record| record.ama_appeal.id } }
                expect(subscriber.queries.count).to eq 2
              end
            end
          end
        end

        context "when eager loading with `preload`" do
          subject { Task.ama.preload(:ama_appeal) }

          let!(:_legacy_task) { create(:task) }

          context "when there are no Tasks with AMA appeals" do
            it { should be_none }
          end

          context "when there are Tasks with AMA appeals" do
            let!(:ama_tasks) { create_list(:ama_task, 10) }

            it { should contain_exactly(*ama_tasks) }

            it "prevents N+1 queries" do
              QuerySubscriber.new.tap do |subscriber|
                subscriber.track { subject.map { |record| record.ama_appeal.id } }
                expect(subscriber.queries.count).to eq 2
              end
            end
          end
        end

        context "when called on an individual Task" do
          subject { task.ama_appeal }

          context "when the Task is not associated with an AMA appeal" do
            let(:task) { create(:task) }

            it { should be_nil }
          end

          context "when the Task is associated with an AMA appeal" do
            let(:task) { create(:ama_task, appeal: ama_appeal) }
            let(:ama_appeal) { create(:appeal) }

            it { should eq(ama_appeal) }
          end
        end
      end

      describe "legacy_appeal" do
        context "when used in `joins` query" do
          subject { Task.joins(:legacy_appeal) }

          # Create records having different `appeal_type` but the same `appeal_id`. This will ensure the test fails in
          # the case where the `joins` result contains duplicate entries for records having the same `appeal_id` but
          # different `appeal_type`.
          let(:shared_id) { 99999 }
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
          subject { Task.legacy.includes(:legacy_appeal) }

          let!(:_ama_task) { create(:ama_task) }

          context "when there are no Tasks with Legacy appeals" do
            it { should be_none }
          end

          context "when there are Tasks with Legacy appeals" do
            let!(:legacy_tasks) { create_list(:task, 10) }

            it { should contain_exactly(*legacy_tasks) }

            it "prevents N+1 queries" do
              QuerySubscriber.new.tap do |subscriber|
                subscriber.track { subject.map { |record| record.legacy_appeal.id } }
                expect(subscriber.queries.count).to eq 2
              end
            end
          end
        end

        context "when eager loading with `preload`" do
          subject { Task.legacy.preload(:legacy_appeal) }

          let!(:_ama_task) { create(:ama_task) }

          context "when there are no Tasks with Legacy appeals" do
            it { should be_none }
          end

          context "when there are Tasks with Legacy appeals" do
            let!(:legacy_tasks) { create_list(:task, 10) }

            it { should contain_exactly(*legacy_tasks) }

            it "prevents N+1 queries" do
              QuerySubscriber.new.tap do |subscriber|
                subscriber.track { subject.map { |record| record.legacy_appeal.id } }
                expect(subscriber.queries.count).to eq 2
              end
            end
          end
        end

        context "when called on an individual Task" do
          subject { task.legacy_appeal }

          context "when the Task is not associated with a Legacy appeal" do
            let(:task) { create(:ama_task) }

            it { should be_nil }
          end

          context "when the Task is associated with a Legacy appeal" do
            let(:task) { create(:task, appeal: legacy_appeal) }
            let(:legacy_appeal) { create(:legacy_appeal) }

            it { should eq(legacy_appeal) }
          end
        end
      end

      describe "higher_level_review" do
        context "when used in `joins` query" do
          subject { Task.joins(:higher_level_review) }

          # Create records having different `appeal_type` but the same `appeal_id`. This will ensure the test fails in
          # the case where the `joins` result contains duplicate entries for records having the same `appeal_id` but
          # different `appeal_type`.
          let(:shared_id) { 99999 }
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
          subject { Task.higher_level_review.includes(:higher_level_review) }

          let!(:_ama_task) { create(:ama_task) }

          context "when there are no Tasks with HigherLevelReviews" do
            it { should be_none }
          end

          context "when there are Tasks with HigherLevelReviews" do
            let!(:higher_level_review_tasks) { create_list(:higher_level_review_task, 10) }

            it { should contain_exactly(*higher_level_review_tasks) }

            it "prevents N+1 queries" do
              QuerySubscriber.new.tap do |subscriber|
                subscriber.track { subject.map { |record| record.higher_level_review.id } }
                expect(subscriber.queries.count).to eq 2
              end
            end
          end
        end

        context "when eager loading with `preload`" do
          subject { Task.higher_level_review.preload(:higher_level_review) }

          let!(:_ama_task) { create(:ama_task) }

          context "when there are no Tasks with HigherLevelReviews" do
            it { should be_none }
          end

          context "when there are Tasks with HigherLevelReviews" do
            let!(:higher_level_review_tasks) { create_list(:higher_level_review_task, 10) }

            it { should contain_exactly(*higher_level_review_tasks) }

            it "prevents N+1 queries" do
              QuerySubscriber.new.tap do |subscriber|
                subscriber.track { subject.map { |record| record.higher_level_review.id } }
                expect(subscriber.queries.count).to eq 2
              end
            end
          end
        end

        context "when called on an individual Task" do
          subject { task.higher_level_review }

          context "when the Task is not associated with a HigherLevelReview" do
            let(:task) { create(:ama_task) }

            it { should be_nil }
          end

          context "when the Task is associated with a HigherLevelReview" do
            let(:task) { create(:higher_level_review_task, appeal: higher_level_review) }
            let(:higher_level_review) { create(:higher_level_review) }

            it { should eq(higher_level_review) }
          end
        end
      end

      describe "supplemental_claim" do
        context "when used in `joins` query" do
          subject { Task.joins(:supplemental_claim) }

          # Create records having different `appeal_type` but the same `appeal_id`. This will ensure the test fails in
          # the case where the `joins` result contains duplicate entries for records having the same `appeal_id` but
          # different `appeal_type`.
          let(:shared_id) { 99999 }
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
          subject { Task.supplemental_claim.includes(:supplemental_claim) }

          let!(:_ama_task) { create(:ama_task) }

          context "when there are no Tasks with SupplementalClaims" do
            it { should be_none }
          end

          context "when there are Tasks with SupplementalClaims" do
            let!(:supplemental_claim_tasks) { create_list(:supplemental_claim_task, 10) }

            it { should contain_exactly(*supplemental_claim_tasks) }

            it "prevents N+1 queries" do
              QuerySubscriber.new.tap do |subscriber|
                subscriber.track { subject.map { |record| record.supplemental_claim.id } }
                expect(subscriber.queries.count).to eq 2
              end
            end
          end
        end

        context "when eager loading with `preload`" do
          subject { Task.supplemental_claim.preload(:supplemental_claim) }

          let!(:_ama_task) { create(:ama_task) }

          context "when there are no Tasks with SupplementalClaims" do
            it { should be_none }
          end

          context "when there are Tasks with SupplementalClaims" do
            let!(:supplemental_claim_tasks) { create_list(:supplemental_claim_task, 10) }

            it { should contain_exactly(*supplemental_claim_tasks) }

            it "prevents N+1 queries" do
              QuerySubscriber.new.tap do |subscriber|
                subscriber.track { subject.map { |record| record.supplemental_claim.id } }
                expect(subscriber.queries.count).to eq 2
              end
            end
          end
        end

        context "when called on an individual Task" do
          subject { task.supplemental_claim }

          context "when the Task is not associated with a SupplementalClaim" do
            let(:task) { create(:ama_task) }

            it { should be_nil }
          end

          context "when the Task is associated with a SupplementalClaim" do
            let(:task) { create(:supplemental_claim_task, appeal: supplemental_claim) }
            let(:supplemental_claim) { create(:supplemental_claim) }

            it { should eq(supplemental_claim) }
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
