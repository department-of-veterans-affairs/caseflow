# frozen_string_literal: true

require "query_subscriber"

shared_examples "DecisionDocument belongs_to polymorphic appeal" do
  context do
    context "'appeal'-related associations" do
      it { should belong_to(:appeal) }
      it { should belong_to(:ama_appeal).class_name("Appeal").with_foreign_key(:appeal_id).optional }
      it { should belong_to(:legacy_appeal).class_name("LegacyAppeal").with_foreign_key(:appeal_id).optional }

      describe "ama_appeal" do
        context "when used in `joins` query" do
          subject { DecisionDocument.joins(:ama_appeal) }

          # Create records having different `appeal_type` but the same `appeal_id`. This will ensure the test fails in
          # the case where the `joins` result contains duplicate entries for records having the same `appeal_id` but
          # different `appeal_type`.
          let(:shared_id) { 99999 }
          let!(:_legacy_decision_document) do
            create(:decision_document, appeal: create(:legacy_appeal, vacols_case: create(:case), id: shared_id))
          end

          context "when there are no DecisionDocument with AMA appeals" do
            it { should be_none }
          end

          context "when there are DecisionDocument with AMA appeals" do
            let!(:ama_decision_document) { create(:decision_document, appeal: create(:appeal, id: shared_id)) }

            it { should contain_exactly(ama_decision_document) }
          end
        end

        context "when eager loading with `includes`" do
          subject { DecisionDocument.ama.includes(:ama_appeal) }

          let!(:_legacy_decision_document) { create(:decision_document, :legacy) }

          context "when there are no DecisionDocument with AMA appeals" do
            it { should be_none }
          end

          context "when there are DecisionDocument with AMA appeals" do
            let!(:ama_decision_documents) { create_list(:decision_document, 10, :ama) }

            it { should contain_exactly(*ama_decision_documents) }

            it "prevents N+1 queries" do
              QuerySubscriber.new.tap do |subscriber|
                subscriber.track { subject.map { |record| record.ama_appeal.id } }
                expect(subscriber.queries.count).to eq 2
              end
            end
          end
        end

        context "when eager loading with `preload`" do
          subject { DecisionDocument.ama.preload(:ama_appeal) }

          let!(:_legacy_decision_document) { create(:decision_document, :legacy) }

          context "when there are no DecisionDocument with AMA appeals" do
            it { should be_none }
          end

          context "when there are DecisionDocument with AMA appeals" do
            let!(:ama_decision_documents) { create_list(:decision_document, 10, :ama) }

            it { should contain_exactly(*ama_decision_documents) }

            it "prevents N+1 queries" do
              QuerySubscriber.new.tap do |subscriber|
                subscriber.track { subject.map { |record| record.ama_appeal.id } }
                expect(subscriber.queries.count).to eq 2
              end
            end
          end
        end

        context "when called on an individual DecisionDocument" do
          subject { decision_document.ama_appeal }

          context "when the DecisionDocument is not associated with an AMA appeal" do
            let(:decision_document) { create(:decision_document, :legacy) }

            it { should be_nil }
          end

          context "when the DecisionDocument is associated with an AMA appeal" do
            let(:decision_document) { create(:decision_document, appeal: ama_appeal) }
            let(:ama_appeal) { create(:appeal) }

            it { should eq(ama_appeal) }
          end
        end
      end

      describe "legacy_appeal" do
        context "when used in `joins` query" do
          subject { DecisionDocument.joins(:legacy_appeal) }

          # Create records having different `appeal_type` but the same `appeal_id`. This will ensure the test fails in
          # the case where the `joins` result contains duplicate entries for records having the same `appeal_id` but
          # different `appeal_type`.
          let(:shared_id) { 99999 }
          let!(:_ama_decision_document) { create(:decision_document, appeal: create(:appeal, id: shared_id)) }

          context "when there are no DecisionDocument with Legacy appeals" do
            it { should be_none }
          end

          context "when there are DecisionDocument with Legacy appeals" do
            let!(:legacy_decision_document) do
              create(:decision_document, appeal: create(:legacy_appeal, vacols_case: create(:case), id: shared_id))
            end

            it { should contain_exactly(legacy_decision_document) }
          end
        end

        context "when eager loading with `includes`" do
          subject { DecisionDocument.legacy.includes(:legacy_appeal) }

          let!(:_ama_decision_document) { create(:decision_document, :ama) }

          context "when there are no DecisionDocument with Legacy appeals" do
            it { should be_none }
          end

          context "when there are DecisionDocument with Legacy appeals" do
            let!(:legacy_decision_documents) { create_list(:decision_document, 10, :legacy) }

            it { should contain_exactly(*legacy_decision_documents) }

            it "prevents N+1 queries" do
              QuerySubscriber.new.tap do |subscriber|
                subscriber.track { subject.map { |record| record.legacy_appeal.id } }
                expect(subscriber.queries.count).to eq 2
              end
            end
          end
        end

        context "when eager loading with `preload`" do
          subject { DecisionDocument.legacy.preload(:legacy_appeal) }

          let!(:_ama_decision_document) { create(:decision_document, :ama) }

          context "when there are no DecisionDocument with Legacy appeals" do
            it { should be_none }
          end

          context "when there are DecisionDocument with Legacy appeals" do
            let!(:legacy_decision_documents) { create_list(:decision_document, 10, :legacy) }

            it { should contain_exactly(*legacy_decision_documents) }

            it "prevents N+1 queries" do
              QuerySubscriber.new.tap do |subscriber|
                subscriber.track { subject.map { |record| record.legacy_appeal.id } }
                expect(subscriber.queries.count).to eq 2
              end
            end
          end
        end

        context "when called on an individual DecisionDocument" do
          subject { decision_document.legacy_appeal }

          context "when the DecisionDocument is not associated with a Legacy appeal" do
            let(:decision_document) { create(:decision_document, :ama) }

            it { should be_nil }
          end

          context "when the DecisionDocument is associated with a Legacy appeal" do
            let(:decision_document) { create(:decision_document, appeal: legacy_appeal) }
            let(:legacy_appeal) { create(:legacy_appeal) }

            it { should eq(legacy_appeal) }
          end
        end
      end
    end

    context "'appeal'-related scopes" do
      let!(:ama_decision_documents) { create_list(:decision_document, 2, :ama) }
      let!(:legacy_decision_documents) { create_list(:decision_document, 2, :legacy) }

      describe ".ama" do
        it "returns only DecisionDocument belonging to AMA appeals" do
          expect(DecisionDocument.ama).to be_an(ActiveRecord::Relation)
          expect(DecisionDocument.ama).to contain_exactly(*ama_decision_documents)
        end
      end

      describe ".legacy" do
        it "returns only DecisionDocument belonging to Legacy appeals" do
          expect(DecisionDocument.legacy).to be_an(ActiveRecord::Relation)
          expect(DecisionDocument.legacy).to contain_exactly(*legacy_decision_documents)
        end
      end
    end
  end
end
