# frozen_string_literal: true

require "query_subscriber"

shared_examples "JudgeCaseReview belongs_to polymorphic appeal" do
  context do
    context "'appeal'-related associations" do
      it { should belong_to(:appeal) }
      it { should belong_to(:ama_appeal).class_name("Appeal").with_foreign_key(:appeal_id).optional }
      it { should belong_to(:legacy_appeal).class_name("LegacyAppeal").with_foreign_key(:appeal_id).optional }

      describe "ama_appeal" do
        context "when used in `joins` query" do
          subject { JudgeCaseReview.joins(:ama_appeal) }

          # Create records having different `appeal_type` but the same `appeal_id`. This will ensure the test fails in
          # the case where the `joins` result contains duplicate entries for records having the same `appeal_id` but
          # different `appeal_type`.
          let(:shared_id) { 99999 }
          let!(:_legacy_judge_case_review) do
            create(:judge_case_review, :legacy, appeal: create(:legacy_appeal, id: shared_id))
          end

          context "when there are no JudgeCaseReviews with AMA appeals" do
            it { should be_none }
          end

          context "when there are JudgeCaseReviews with AMA appeals" do
            let!(:ama_judge_case_review) do
              create(:judge_case_review, :ama, appeal: create(:appeal, id: shared_id))
            end

            it { should contain_exactly(ama_judge_case_review) }
          end
        end

        context "when eager loading with `includes`" do
          subject { JudgeCaseReview.ama.includes(:ama_appeal) }

          let!(:_legacy_judge_case_review) { create(:judge_case_review, :legacy) }

          context "when there are no JudgeCaseReviews with AMA appeals" do
            it { should be_none }
          end

          context "when there are JudgeCaseReviews with AMA appeals" do
            let!(:ama_judge_case_reviews) { create_list(:judge_case_review, 10, :ama) }

            it { should contain_exactly(*ama_judge_case_reviews) }

            it "prevents N+1 queries" do
              QuerySubscriber.new.tap do |subscriber|
                subscriber.track { subject.map { |record| record.ama_appeal.id } }
                expect(subscriber.queries.count).to eq 2
              end
            end
          end
        end

        context "when eager loading with `preload`" do
          subject { JudgeCaseReview.ama.preload(:ama_appeal) }

          let!(:_legacy_judge_case_review) { create(:judge_case_review, :legacy) }

          context "when there are no JudgeCaseReviews with AMA appeals" do
            it { should be_none }
          end

          context "when there are JudgeCaseReviews with AMA appeals" do
            let!(:ama_judge_case_reviews) { create_list(:judge_case_review, 10, :ama) }

            it { should contain_exactly(*ama_judge_case_reviews) }

            it "prevents N+1 queries" do
              QuerySubscriber.new.tap do |subscriber|
                subscriber.track { subject.map { |record| record.ama_appeal.id } }
                expect(subscriber.queries.count).to eq 2
              end
            end
          end
        end

        context "when called on an individual JudgeCaseReview" do
          subject { judge_case_review.ama_appeal }

          context "when the JudgeCaseReview is not associated with an AMA appeal" do
            let(:judge_case_review) { create(:judge_case_review, :legacy) }

            it { should be_nil }
          end

          context "when the JudgeCaseReview is associated with an AMA appeal" do
            let(:judge_case_review) { create(:judge_case_review, :ama, appeal: ama_appeal) }
            let(:ama_appeal) { create(:appeal) }

            it { should eq(ama_appeal) }
          end
        end
      end

      describe "legacy_appeal" do
        context "when used in `joins` query" do
          subject { JudgeCaseReview.joins(:legacy_appeal) }

          # Create records having different `appeal_type` but the same `appeal_id`. This will ensure the test fails in
          # the case where the `joins` result contains duplicate entries for records having the same `appeal_id` but
          # different `appeal_type`.
          let(:shared_id) { 99999 }
          let!(:_ama_judge_case_review) do
            create(:judge_case_review, :ama, appeal: create(:appeal, id: shared_id))
          end

          context "when there are no JudgeCaseReviews with Legacy appeals" do
            it { should be_none }
          end

          context "when there are JudgeCaseReviews with Legacy appeals" do
            let!(:legacy_judge_case_review) do
              create(:judge_case_review, :legacy, appeal: create(:legacy_appeal, id: shared_id))
            end

            it { should contain_exactly(legacy_judge_case_review) }
          end
        end

        context "when eager loading with `includes`" do
          subject { JudgeCaseReview.legacy.includes(:legacy_appeal) }

          let!(:_ama_judge_case_review) { create(:judge_case_review, :ama) }

          context "when there are no JudgeCaseReviews with Legacy appeals" do
            it { should be_none }
          end

          context "when there are JudgeCaseReviews with Legacy appeals" do
            let!(:legacy_judge_case_reviews) { create_list(:judge_case_review, 10, :legacy) }

            it { should contain_exactly(*legacy_judge_case_reviews) }

            it "prevents N+1 queries" do
              QuerySubscriber.new.tap do |subscriber|
                subscriber.track { subject.map { |record| record.legacy_appeal.id } }
                expect(subscriber.queries.count).to eq 2
              end
            end
          end
        end

        context "when eager loading with `preload`" do
          subject { JudgeCaseReview.legacy.preload(:legacy_appeal) }

          let!(:_ama_judge_case_review) { create(:judge_case_review, :ama) }

          context "when there are no JudgeCaseReviews with Legacy appeals" do
            it { should be_none }
          end

          context "when there are JudgeCaseReviews with Legacy appeals" do
            let!(:legacy_judge_case_reviews) { create_list(:judge_case_review, 10, :legacy) }

            it { should contain_exactly(*legacy_judge_case_reviews) }

            it "prevents N+1 queries" do
              QuerySubscriber.new.tap do |subscriber|
                subscriber.track { subject.map { |record| record.legacy_appeal.id } }
                expect(subscriber.queries.count).to eq 2
              end
            end
          end
        end

        context "when called on an individual JudgeCaseReview" do
          subject { judge_case_review.legacy_appeal }

          context "when the JudgeCaseReview is not associated with a Legacy appeal" do
            let(:judge_case_review) { create(:judge_case_review, :ama) }

            it { should be_nil }
          end

          context "when the JudgeCaseReview is associated with a Legacy appeal" do
            let(:judge_case_review) { create(:judge_case_review, :legacy, appeal: legacy_appeal) }
            let(:legacy_appeal) { create(:legacy_appeal) }

            it { should eq(legacy_appeal) }
          end
        end
      end
    end

    context "'appeal'-related scopes" do
      let!(:ama_judge_case_reviews) { create_list(:judge_case_review, 2, :ama) }
      let!(:legacy_judge_case_reviews) { create_list(:judge_case_review, 2, :legacy) }

      describe ".ama" do
        it "returns only JudgeCaseReviews belonging to AMA appeals" do
          expect(JudgeCaseReview.ama).to be_an(ActiveRecord::Relation)
          expect(JudgeCaseReview.ama).to contain_exactly(*ama_judge_case_reviews)
        end
      end

      describe ".legacy" do
        it "returns only JudgeCaseReviews belonging to Legacy appeals" do
          expect(JudgeCaseReview.legacy).to be_an(ActiveRecord::Relation)
          expect(JudgeCaseReview.legacy).to contain_exactly(*legacy_judge_case_reviews)
        end
      end
    end
  end
end
