# frozen_string_literal: true

require "helpers/association_wrapper.rb"
require 'ruby-graphviz'

describe "AssocationWrapper" do
  describe "AssocationWrapper#untyped_associations_with User records" do
    subject { AssocationWrapper.new(target_class).untyped_associations_with(User).fieldnames }
    context "for Task class" do
      let(:target_class) { Task }
      it "returns fieldname associated with User records" do
        expect(subject).to match_array %w[assigned_by_id cancelled_by_id]
      end
    end
    context "for Hearing class" do
      let(:target_class) { Hearing }
      it "returns fieldname associated with User records" do
        expect(subject).to match_array %w[created_by_id judge_id updated_by_id]
      end
    end
    context "for AppealIntake class" do
      let(:target_class) { AppealIntake }
      it "returns fieldname associated with User records" do
        expect(subject).to match_array %w[user_id]
      end
    end
  end
  describe "#associations" do
    subject { AssocationWrapper.new(target_class) }
    context "for Task class" do
      let(:target_class) { Task }
      it "returns those with specific foreign_type" do
        expect(subject.having_type_field.fieldnames).to match_array %w[assigned_to_id appeal_id]
      end
      it "returns associations with other tables" do
        # at=subject.associations.select{|a| a.class_name == "AssignedTo"}.first
        # binding.pry
        expect(subject.associations.map do |assoc|
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
                [:cached_appeal, "CachedAppeal", nil, nil, nil]
               ]
        expect(subject.associations.map { |assoc| [assoc.name, assoc.options[:primary_key]] }).to match_array [
          [:versions, nil],
          [:parent, "id"],
          [:children, "id"],
          [:assigned_to, nil],
          [:assigned_by, nil],
          [:cancelled_by, nil],
          [:appeal, nil],
          [:attorney_case_reviews, nil],
          [:task_timers, nil],
          [:cached_appeal, nil]
        ]
        expect(subject.associations.map { |assoc| [assoc.name, assoc.options[:foreign_key]] }).to match_array [
          [:versions, nil],
          [:parent, "parent_id"],
          [:children, "parent_id"],
          [:assigned_to, nil],
          [:assigned_by, nil],
          [:cancelled_by, nil],
          [:appeal, nil],
          [:attorney_case_reviews, nil],
          [:task_timers, nil],
          [:cached_appeal, :appeal_id]
        ]

        map_foreign_keys = lambda { |assoc|
          [assoc.name, assoc.belongs_to?, assoc.has_one?,
           assoc.foreign_key, assoc.association_foreign_key, assoc.foreign_type]
        }
        expect(subject.associations.map(&map_foreign_keys)).to match_array [
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
          # has_many declared in Task
          # Note: JudgeCaseReview is not listed; that `belongs_to` association can be traced from JudgeCaseReview
          [:attorney_case_reviews, false, false, "task_id", "attorney_case_review_id", nil],
          [:task_timers, false, false, "task_id", "task_timer_id", nil],
          # has_one declared in Task
          [:cached_appeal, false, true, :appeal_id, "cached_appeal_id", nil]
        ]
      end

      it "creates graphviz" do
        # klasses = SanitizedJsonConfiguration.new.configuration.keys
        klasses=[
          LegacyAppeal, LegacyHearing,
          # Task, OrganizationsUser, User, Appeal
          Appeal,
          Veteran,
          AppealIntake,
          JudgeCaseReview,
          AttorneyCaseReview,
          DecisionDocument,
          Claimant,
          Task,
          TaskTimer,
          RequestIssue,
          DecisionIssue,
          RequestDecisionIssue,
          CavcRemand,
          Hearing,
          HearingDay,
          VirtualHearing,
          HearingTaskAssociation,
          User,
          Organization,
          OrganizationsUser,
          Person,
        ]
        Rails.application.eager_load!
        klasses = ApplicationRecord.descendants
        node_classes = []

        g = GraphViz.new( :G, :type => :digraph, :rankdir => "LR" )

        puts klasses.map { |klass|
          next if klass != Task && klass.ancestors.include?(Task) # TODO: some Task subclasses may be different belongs_to

          next if klass != Claimant && klass.ancestors.include?(Claimant) # TODO: some Claimant subclasses may be different belongs_to

          aw=AssocationWrapper.new(klass)
          node_classes << klass
          edges = aw.belongs_to.associations!.associations.map {|assoc|

            next if [:created_by, :updated_by].include?(assoc.name)

            to_node = assoc.polymorphic? ? "#{assoc.class_name} (#{assoc.foreign_type})" : assoc.class_name
            
            next if to_node == "User" # TODO: display in node

            if to_node == "User" && assoc.name != :user
              to_node = "#{assoc.name} User"
            end
            
            from = g.add_nodes( klass.name )
            to = g.add_nodes( to_node.to_s )
            from << to

            "\"#{klass.name}\" -> \"#{to_node}\" [label=\"#{assoc.name}\"]"
          }.compact.presence&.join("\n")
        }.compact.join("\n\n")

        puts (node_classes - [Task, CaseflowRecord, VACOLS::Record, ETL::Record]).map { |klass|
          subclass_edges = (klass.subclasses & klasses).map {|subclass|
            from = g.add_nodes( klass.name )
            to = g.add_nodes( subclass.name )
            g.add_edges(from, to, style: "dotted")
            "\"#{klass.name}\" -> \"#{subclass.name}\" [style=dotted]"
          }.compact.presence&.join("\n")
        }.compact.join("\n\n")

        g.output( :png => "belongs_to_erd_all.png" )
        g.output( :dot => "belongs_to_erd_all.dot" )
      end
    end
  end
end
