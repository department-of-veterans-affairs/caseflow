# frozen_string_literal: true

require "helpers/association_wrapper.rb"

describe "AssocationWrapper" do
  subject { AssocationWrapper.new(target_class) }
  describe "#fieldnames and #select_associations}" do
    context "for Task class" do
      let(:target_class) { Task }
      it "returns those with specific foreign_type" do
        expect(subject.having_type_field.fieldnames).to match_array %w[assigned_to_id appeal_id]
      end
      it "returns associations with other tables" do
        expect(subject.select_associations.map do |assoc|
                 [assoc.name, assoc.class_name, assoc.options[:class_name], assoc.polymorphic?, assoc.foreign_type]
               end).to match_array [
                 [:versions, "PaperTrail::Version", "PaperTrail::Version", nil, nil],
                 [:parent, "Task", "Task", nil, nil],
                 [:children, "Task", "Task", nil, nil],
                 [:assigned_to, "AssignedTo", nil, true, "assigned_to_type"],
                 [:assigned_by, "User", "User", nil, nil],
                 [:cancelled_by, "User", "User", nil, nil],
                 [:appeal, "Appeal", nil, true, "appeal_type"],
                 [:attorney_case_reviews, "AttorneyCaseReview", nil, nil, nil],
                 [:task_timers, "TaskTimer", nil, nil, nil],
                 [:cached_appeal, "CachedAppeal", nil, nil, nil],
                 [:ama_appeal, "Appeal", "Appeal", nil, nil],
                 [:legacy_appeal, "LegacyAppeal", "LegacyAppeal", nil, nil]
               ]
        expect(subject.select_associations.map { |assoc| [assoc.name, assoc.options[:primary_key]] }).to match_array [
          [:versions, nil],
          [:parent, "id"],
          [:children, "id"],
          [:assigned_to, nil],
          [:assigned_by, nil],
          [:cancelled_by, nil],
          [:appeal, nil],
          [:attorney_case_reviews, nil],
          [:task_timers, nil],
          [:cached_appeal, nil],
          [:ama_appeal, nil],
          [:legacy_appeal, nil]
        ]
        expect(subject.select_associations.map { |assoc| [assoc.name, assoc.options[:foreign_key]] }).to match_array [
          [:versions, nil],
          [:parent, "parent_id"],
          [:children, "parent_id"],
          [:assigned_to, nil],
          [:assigned_by, nil],
          [:cancelled_by, nil],
          [:appeal, nil],
          [:attorney_case_reviews, nil],
          [:task_timers, nil],
          [:cached_appeal, :appeal_id],
          [:ama_appeal, "appeal_id"],
          [:legacy_appeal, "appeal_id"]
        ]

        map_foreign_keys = lambda { |assoc|
          [assoc.name, assoc.belongs_to?, assoc.has_one?,
           assoc.foreign_key, assoc.association_foreign_key, assoc.foreign_type]
        }
        expect(subject.select_associations.map(&map_foreign_keys)).to match_array [
          # has_paper_trail declared in Task
          [:versions, false, false, "item_id", "version_id", nil],
          # acts_as_tree declared in Task
          [:parent, true, false, "parent_id", "task_id", nil],
          [:children, false, false, "parent_id", "task_id", nil],
          # belongs_to declared in Task
          [:assigned_to, true, false, "assigned_to_id", "assigned_to_id", "assigned_to_type"],
          [:assigned_by, true, false, "assigned_by_id", "user_id", nil],
          [:cancelled_by, true, false, "cancelled_by_id", "user_id", nil],
          [:appeal, true, false, "appeal_id", "appeal_id", "appeal_type"],
          # belongs_to created dynamically by BelongsToPolymorphicAppealConcern
          [:ama_appeal, true, false, "appeal_id", "appeal_id", nil],
          [:legacy_appeal, true, false, "appeal_id", "legacy_appeal_id", nil],
          # has_many declared in Task
          # Note: JudgeCaseReview is not listed; that `belongs_to` association can be traced from JudgeCaseReview
          [:attorney_case_reviews, false, false, "task_id", "attorney_case_review_id", nil],
          [:task_timers, false, false, "task_id", "task_timer_id", nil],
          # has_one declared in Task
          [:cached_appeal, false, true, :appeal_id, "cached_appeal_id", nil]
        ]
      end
    end
    describe "#polymorphic" do
      subject { AssocationWrapper.new(target_class).belongs_to.polymorphic }
      context "for DecisionDocument class" do
        let(:target_class) { DecisionDocument }
        it "returns those with polymorphic belongs_to associations" do
          assocs = subject.associated_with_type(Appeal).select_associations
          expect(assocs.length).to eq 1
          assoc = assocs.first
          expect(assoc.name).to eq :appeal
          expect(assoc.class_name).to eq "Appeal"
          expect(assoc.foreign_type).to eq "appeal_type"
          expect(assoc.foreign_key).to eq "appeal_id"
        end
      end
      context "for DecisionIssue class" do
        let(:target_class) { DecisionIssue }
        it "returns those with polymorphic belongs_to associations" do
          assocs = subject.associated_with_type(DecisionReview).select_associations
          expect(assocs.length).to eq 1
          assoc = assocs.first
          expect(assoc.name).to eq :decision_review
          expect(assoc.class_name).to eq "DecisionReview"
          expect(assoc.foreign_type).to eq "decision_review_type"
          expect(assoc.foreign_key).to eq "decision_review_id"
        end
      end
    end
  end
  describe "AssocationWrapper#fieldnames_of_untyped_associations_with User records" do
    subject { AssocationWrapper.new(target_class).fieldnames_of_untyped_associations_with(User) }
    context "for Task class" do
      let(:target_class) { Task }
      it "returns fieldnames associated with User records" do
        expect(subject).to match_array %w[assigned_by_id cancelled_by_id]
      end
    end
    context "for Hearing class" do
      let(:target_class) { Hearing }
      it "returns fieldnames associated with User records" do
        expect(subject).to match_array %w[created_by_id judge_id updated_by_id]
      end
    end
    context "for AppealIntake class" do
      let(:target_class) { AppealIntake }
      it "returns fieldnames associated with User records" do
        expect(subject).to match_array %w[user_id]
      end
    end
  end
end
