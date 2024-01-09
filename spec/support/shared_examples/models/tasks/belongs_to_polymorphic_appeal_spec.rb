# frozen_string_literal: true

require "query_subscriber"

shared_examples "Task belongs_to polymorphic appeal" do
  context "'appeal'-related scopes" do
    let!(:ama_tasks) { create_list(:ama_task, 2) }
    let!(:legacy_tasks) { create_list(:task, 2) }
    let!(:supplemental_claim_tasks) { create_list(:supplemental_claim_task, 2) }
    let!(:higher_level_review_tasks) { create_list(:higher_level_review_task, 2) }

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

    describe ".supplemental_claim" do
      it "returns only Tasks belonging to Supplemental Claim appeals" do
        expect(Task.supplemental_claim).to be_an(ActiveRecord::Relation)
        expect(Task.supplemental_claim).to contain_exactly(*supplemental_claim_tasks)
      end
    end

    describe ".higher_level_review" do
      it "returns only Tasks belonging to Higher Level Review appeals" do
        expect(Task.higher_level_review).to be_an(ActiveRecord::Relation)
        expect(Task.higher_level_review).to contain_exactly(*higher_level_review_tasks)
      end
    end
  end

  context "'appeal'-related associations" do
    it { should belong_to(:appeal) }
    it { should belong_to(:ama_appeal).class_name("Appeal").with_foreign_key(:appeal_id).optional }
    it { should belong_to(:legacy_appeal).class_name("LegacyAppeal").with_foreign_key(:appeal_id).optional }
    it { should belong_to(:supplemental_claim).class_name("SupplementalClaim").with_foreign_key(:appeal_id).optional }
    it { should belong_to(:higher_level_review).class_name("HigherLevelReview").with_foreign_key(:appeal_id).optional }

    context "ama_appeal" do
      context "when used in `joins` query" do
        subject { Task.joins(:ama_appeal) }

        # Create appeals of different types but with a shared ID to cover the possible edge case where the `joins`
        #   injects a `LEFT OUTER JOIN` into the query via an `includes` in the association scope block
        #   (Example: https://github.com/department-of-veterans-affairs/caseflow/blob/42df79fd83aedc4ea4762309eb7bb5df772e34ba/app/models/concerns/belongs_to_polymorphic_concern.rb#L37)
        let(:shared_id) { 1 }
        let!(:_legacy_task) { create(:task, appeal: create(:legacy_appeal, id: shared_id)) }
        let!(:_supplemental_claim_task) { create(:supplemental_claim_task, appeal: create(:supplemental_claim, id: shared_id)) }
        let!(:_higher_level_review_task) { create(:higher_level_review_task, appeal: create(:higher_level_review, id: shared_id)) }

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
        let!(:_supplemental_claim_task) { create(:supplemental_claim_task) }
        let!(:_higher_level_review_task) { create(:higher_level_review_task) }

        context "when there are no Tasks with AMA appeals" do
          it { should be_none }
        end

        context "when there are Tasks with AMA appeals" do
          let!(:ama_tasks) { create_list(:ama_task, 10) }

          it { should contain_exactly(*ama_tasks) }

          it "prevents N+1 queries" do
            QuerySubscriber.new.tap do |subscriber|
              subscriber.track { subject.map { |task| task.ama_appeal.id } }
              expect(subscriber.queries.count).to eq 2
            end
          end
        end
      end

      context "when eager loading with `preload`" do
        subject { Task.ama.preload(:appeal) }

        let!(:_legacy_task) { create(:task) }
        let!(:_supplemental_claim_task) { create(:supplemental_claim_task) }
        let!(:_higher_level_review_task) { create(:higher_level_review_task) }

        context "when there are no Tasks with AMA appeals" do
          it { should be_none }
        end

        context "when there are Tasks with AMA appeals" do
          let!(:ama_tasks) { create_list(:ama_task, 10) }

          it { should contain_exactly(*ama_tasks) }

          it "prevents N+1 queries" do
            QuerySubscriber.new.tap do |subscriber|
              subscriber.track { subject.map { |task| task.appeal.id } }
              expect(subscriber.queries.count).to eq 2
            end
          end
        end
      end

      context "when called on an individual Task" do
        subject { task.ama_appeal }

        context "when the Task is not associated with an AMA appeal" do
          let(:task) { create(:task, appeal: create(:legacy_appeal)) }

          it { should be_nil }
        end

        context "when the task is associated with an AMA appeal" do
          let(:task) { create(:ama_task, appeal: ama_appeal) }
          let(:ama_appeal) { create(:appeal) }

          it { should eq(ama_appeal) }
        end
      end
    end

    context "legacy_appeal" do
      context "when used in `joins` query" do
        subject { Task.joins(:legacy_appeal) }

        # Create appeals of different types but with a shared ID to cover the possible edge case where the `joins`
        #   injects a `LEFT OUTER JOIN` into the query via an `includes` in the association scope block
        #   (Example: https://github.com/department-of-veterans-affairs/caseflow/blob/42df79fd83aedc4ea4762309eb7bb5df772e34ba/app/models/concerns/belongs_to_polymorphic_concern.rb#L37)
        let(:shared_id) { 1 }
        let!(:_ama_task) { create(:task, appeal: create(:appeal, id: shared_id)) }
        let!(:_supplemental_claim_task) { create(:supplemental_claim_task, appeal: create(:supplemental_claim, id: shared_id)) }
        let!(:_higher_level_review_task) { create(:higher_level_review_task, appeal: create(:higher_level_review, id: shared_id)) }

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
        let!(:_supplemental_claim_task) { create(:supplemental_claim_task) }
        let!(:_higher_level_review_task) { create(:higher_level_review_task) }

        context "when there are no Tasks with Legacy appeals" do
          it { should be_none }
        end

        context "when there are Tasks with Legacy appeals" do
          let!(:legacy_tasks) { create_list(:task, 10) }

          it { should contain_exactly(*legacy_tasks) }

          it "prevents N+1 queries" do
            QuerySubscriber.new.tap do |subscriber|
              subscriber.track { subject.map { |task| task.legacy_appeal.id } }
              expect(subscriber.queries.count).to eq 2
            end
          end
        end
      end

      context "when eager loading with `preload`" do
        subject { Task.legacy.preload(:appeal) }

        let!(:_ama_task) { create(:ama_task) }
        let!(:_supplemental_claim_task) { create(:supplemental_claim_task) }
        let!(:_higher_level_review_task) { create(:higher_level_review_task) }

        context "when there are no Tasks with Legacy appeals" do
          it { should be_none }
        end

        context "when there are Tasks with Legacy appeals" do
          let!(:legacy_tasks) { create_list(:task, 10) }

          it { should contain_exactly(*legacy_tasks) }

          it "prevents N+1 queries" do
            QuerySubscriber.new.tap do |subscriber|
              subscriber.track { subject.map { |task| task.appeal.id } }
              expect(subscriber.queries.count).to eq 2
            end
          end
        end
      end

      context "when called on an individual Task" do
        subject { task.legacy_appeal }

        context "when the Task is not associated with a Legacy appeal" do
          let(:task) { create(:task, appeal: create(:appeal)) }

          it { should be_nil }
        end

        context "when the task is associated with a Legacy appeal" do
          let(:task) { create(:ama_task, appeal: legacy_appeal) }
          let(:legacy_appeal) { create(:legacy_appeal) }

          it { should eq(legacy_appeal) }
        end
      end
    end

    context "supplemental_claim" do
      context "when used in `joins` query" do
        subject { Task.joins(:supplemental_claim) }

        # Create appeals of different types but with a shared ID to cover the possible edge case where the `joins`
        #   injects a `LEFT OUTER JOIN` into the query via an `includes` in the association scope block
        #   (Example: https://github.com/department-of-veterans-affairs/caseflow/blob/42df79fd83aedc4ea4762309eb7bb5df772e34ba/app/models/concerns/belongs_to_polymorphic_concern.rb#L37)
        let(:shared_id) { 1 }
        let!(:_ama_task) { create(:ama_task, appeal: create(:appeal, id: shared_id)) }
        let!(:_legacy_task) { create(:task, appeal: create(:legacy_appeal, id: shared_id)) }
        let!(:_higher_level_review_task) { create(:higher_level_review_task, appeal: create(:higher_level_review, id: shared_id)) }

        context "when there are no Tasks with Supplemental Claims" do
          it { should be_none }
        end

        context "when there are Tasks with Supplemental Claims" do
          let!(:supplemental_claim_task) { create(:supplemental_claim_task, appeal: create(:supplemental_claim, id: shared_id)) }

          it { should contain_exactly(supplemental_claim_task) }
        end
      end

      context "when eager loading with `includes`" do
        subject { Task.supplemental_claim.includes(:supplemental_claim) }

        let!(:_ama_task) { create(:ama_task) }
        let!(:_legacy_task) { create(:task) }
        let!(:_higher_level_review_task) { create(:higher_level_review_task) }

        context "when there are no Tasks with Supplemental Claims" do
          it { should be_none }
        end

        context "when there are Tasks with Supplemental Claims" do
          let!(:supplemental_claim_tasks) { create_list(:supplemental_claim_task, 10) }

          it { should contain_exactly(*supplemental_claim_tasks) }

          it "prevents N+1 queries" do
            QuerySubscriber.new.tap do |subscriber|
              subscriber.track { subject.map { |task| task.supplemental_claim.id } }
              expect(subscriber.queries.count).to eq 2
            end
          end
        end
      end

      context "when eager loading with `preload`" do
        subject { Task.supplemental_claim.preload(:appeal) }

        let!(:_ama_task) { create(:ama_task) }
        let!(:_legacy_task) { create(:task) }
        let!(:_higher_level_review_task) { create(:higher_level_review_task) }

        context "when there are no Tasks with Supplemental Claims" do
          it { should be_none }
        end

        context "when there are Tasks with Supplemental Claims" do
          let!(:supplemental_claim_tasks) { create_list(:supplemental_claim_task, 10) }

          it { should contain_exactly(*supplemental_claim_tasks) }

          it "prevents N+1 queries" do
            QuerySubscriber.new.tap do |subscriber|
              subscriber.track { subject.map { |task| task.appeal.id } }
              expect(subscriber.queries.count).to eq 2
            end
          end
        end
      end

      context "when called on an individual Task" do
        subject { task.supplemental_claim }

        context "when the Task is not associated with a Supplemental Claim" do
          let(:task) { create(:task, appeal: create(:appeal)) }

          it { should be_nil }
        end

        context "when the task is associated with a Supplemental Claim" do
          let(:task) { create(:ama_task, appeal: supplemental_claim) }
          let(:supplemental_claim) { create(:supplemental_claim) }

          it { should eq(supplemental_claim) }
        end
      end
    end

    context "higher_level_review" do
      context "when used in `joins` query" do
        subject { Task.joins(:higher_level_review) }

        # Create appeals of different types but with a shared ID to cover the possible edge case where the `joins`
        #   injects a `LEFT OUTER JOIN` into the query via an `includes` in the association scope block
        #   (Example: https://github.com/department-of-veterans-affairs/caseflow/blob/42df79fd83aedc4ea4762309eb7bb5df772e34ba/app/models/concerns/belongs_to_polymorphic_concern.rb#L37)
        let(:shared_id) { 1 }
        let!(:_ama_task) { create(:ama_task, appeal: create(:appeal, id: shared_id)) }
        let!(:_legacy_task) { create(:task, appeal: create(:legacy_appeal, id: shared_id)) }
        let!(:_supplemental_claim_task) { create(:supplemental_claim_task, appeal: create(:supplemental_claim, id: shared_id)) }

        context "when there are no Tasks with Higher Level Reviews" do
          it { should be_none }
        end

        context "when there are Tasks with Higher Level Reviews" do
          let!(:higher_level_review_task) { create(:higher_level_review_task, appeal: create(:higher_level_review, id: shared_id)) }

          it { should contain_exactly(higher_level_review_task) }
        end
      end

      context "when eager loading with `includes`" do
        subject { Task.higher_level_review.includes(:higher_level_review) }

        let!(:_ama_task) { create(:ama_task) }
        let!(:_legacy_task) { create(:task) }
        let!(:_supplemental_claim_task) { create(:supplemental_claim_task) }

        context "when there are no Tasks with Higher Level Reviews" do
          it { should be_none }
        end

        context "when there are Tasks with Higher Level Reviews" do
          let!(:higher_level_review_tasks) { create_list(:higher_level_review_task, 10) }

          it { should contain_exactly(*higher_level_review_tasks) }

          it "prevents N+1 queries" do
            QuerySubscriber.new.tap do |subscriber|
              subscriber.track { subject.map { |task| task.higher_level_review.id } }
              expect(subscriber.queries.count).to eq 2
            end
          end
        end
      end

      context "when eager loading with `preload`" do
        subject { Task.higher_level_review.preload(:appeal) }

        let!(:_ama_task) { create(:ama_task) }
        let!(:_legacy_task) { create(:task) }
        let!(:_supplemental_claim_task) { create(:supplemental_claim_task) }

        context "when there are no Tasks with Higher Level Reviews" do
          it { should be_none }
        end

        context "when there are Tasks with Higher Level Reviews" do
          let!(:higher_level_review_tasks) { create_list(:higher_level_review_task, 10) }

          it { should contain_exactly(*higher_level_review_tasks) }

          it "prevents N+1 queries" do
            QuerySubscriber.new.tap do |subscriber|
              subscriber.track { subject.map { |task| task.appeal.id } }
              expect(subscriber.queries.count).to eq 2
            end
          end
        end
      end

      context "when called on an individual Task" do
        subject { task.higher_level_review }

        context "when the Task is not associated with a Higher Level Review" do
          let(:task) { create(:task, appeal: create(:appeal)) }

          it { should be_nil }
        end

        context "when the task is associated with a Higher Level Review" do
          let(:task) { create(:ama_task, appeal: higher_level_review) }
          let(:higher_level_review) { create(:higher_level_review) }

          it { should eq(higher_level_review) }
        end
      end
    end
  end
end
