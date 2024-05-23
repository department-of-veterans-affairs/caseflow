# frozen_string_literal: true

require "query_subscriber"

shared_examples "SpecialIssueList belongs_to polymorphic appeal" do
  context do
    context "'appeal'-related associations" do
      it { should belong_to(:appeal) }
      it { should belong_to(:ama_appeal).class_name("Appeal").with_foreign_key(:appeal_id).optional }
      it { should belong_to(:legacy_appeal).class_name("LegacyAppeal").with_foreign_key(:appeal_id).optional }

      describe "ama_appeal" do
        context "when used in `joins` query" do
          subject { SpecialIssueList.joins(:ama_appeal) }

          # Create records having different `appeal_type` but the same `appeal_id`. This will ensure the test fails in
          # the case where the `joins` result contains duplicate entries for records having the same `appeal_id` but
          # different `appeal_type`.
          let(:shared_id) { 99_999 }
          let!(:_legacy_special_issue_list) do
            create(:special_issue_list, appeal: create(:legacy_appeal, id: shared_id))
          end

          context "when there are no SpecialIssueLists with AMA appeals" do
            it { should be_none }
          end

          context "when there are SpecialIssueLists with AMA appeals" do
            let!(:ama_special_issue_list) { create(:special_issue_list, appeal: create(:appeal, id: shared_id)) }

            it { should contain_exactly(ama_special_issue_list) }
          end
        end

        context "when eager loading with `includes`" do
          subject { SpecialIssueList.ama.includes(:appeal) }

          let!(:_legacy_special_issue_list) { create(:special_issue_list, :legacy) }

          context "when there are no SpecialIssueLists with AMA appeals" do
            it { should be_none }
          end

          context "when there are SpecialIssueLists with AMA appeals" do
            let!(:ama_special_issue_lists) { create_list(:special_issue_list, 10, :ama) }

            it { should contain_exactly(*ama_special_issue_lists) }

            it "prevents N+1 queries" do
              QuerySubscriber.new.tap do |subscriber|
                subscriber.track { subject.map { |record| record.appeal.id } }
                expect(subscriber.queries.count).to eq 2
              end
            end
          end
        end

        context "when eager loading with `preload`" do
          subject { SpecialIssueList.ama.preload(:appeal) }

          let!(:_legacy_special_issue_list) { create(:special_issue_list, :legacy) }

          context "when there are no SpecialIssueLists with AMA appeals" do
            it { should be_none }
          end

          context "when there are SpecialIssueLists with AMA appeals" do
            let!(:ama_special_issue_lists) { create_list(:special_issue_list, 10, :ama) }

            it { should contain_exactly(*ama_special_issue_lists) }

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
          subject { SpecialIssueList.joins(:legacy_appeal) }

          # Create records having different `appeal_type` but the same `appeal_id`. This will ensure the test fails in
          # the case where the `joins` result contains duplicate entries for records having the same `appeal_id` but
          # different `appeal_type`.
          let(:shared_id) { 99_999 }
          let!(:_ama_special_issue_list) { create(:special_issue_list, appeal: create(:appeal, id: shared_id)) }

          context "when there are no SpecialIssueLists with Legacy appeals" do
            it { should be_none }
          end

          context "when there are SpecialIssueLists with Legacy appeals" do
            let!(:legacy_special_issue_list) do
              create(:special_issue_list, appeal: create(:legacy_appeal, id: shared_id))
            end

            it { should contain_exactly(legacy_special_issue_list) }
          end
        end

        context "when eager loading with `includes`" do
          subject { SpecialIssueList.legacy.includes(:appeal) }

          let!(:_ama_special_issue_list) { create(:special_issue_list, :ama) }

          context "when there are no SpecialIssueLists with Legacy appeals" do
            it { should be_none }
          end

          context "when there are SpecialIssueLists with Legacy appeals" do
            let!(:legacy_special_issue_lists) { create_list(:special_issue_list, 10, :legacy) }

            it { should contain_exactly(*legacy_special_issue_lists) }

            it "prevents N+1 queries" do
              QuerySubscriber.new.tap do |subscriber|
                subscriber.track { subject.map { |record| record.appeal.id } }
                expect(subscriber.queries.count).to eq 2
              end
            end
          end
        end

        context "when eager loading with `preload`" do
          subject { SpecialIssueList.legacy.preload(:appeal) }

          let!(:_ama_special_issue_list) { create(:special_issue_list, :ama) }

          context "when there are no SpecialIssueLists with Legacy appeals" do
            it { should be_none }
          end

          context "when there are SpecialIssueLists with Legacy appeals" do
            let!(:legacy_special_issue_lists) { create_list(:special_issue_list, 10, :legacy) }

            it { should contain_exactly(*legacy_special_issue_lists) }

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
      let!(:ama_special_issue_lists) { create_list(:special_issue_list, 2, :ama) }
      let!(:legacy_special_issue_lists) { create_list(:special_issue_list, 2, :legacy) }

      describe ".ama" do
        it "returns only SpecialIssueLists belonging to AMA appeals" do
          expect(SpecialIssueList.ama).to be_an(ActiveRecord::Relation)
          expect(SpecialIssueList.ama).to contain_exactly(*ama_special_issue_lists)
        end
      end

      describe ".legacy" do
        it "returns only SpecialIssueLists belonging to Legacy appeals" do
          expect(SpecialIssueList.legacy).to be_an(ActiveRecord::Relation)
          expect(SpecialIssueList.legacy).to contain_exactly(*legacy_special_issue_lists)
        end
      end
    end
  end
end
