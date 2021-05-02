# frozen_string_literal: true

##
# Class to extract classes for ERD (entity relationship diagram) documentation.
# Relies on `record_classes` being defined elsewhere.

# rubocop:disable Metrics/ModuleLength
module ErdRecordAssociations
  def add_subclass_edges(graph, classes)
    classes.each { |klass| add_subclass_edges_for(graph, klass) }
  end

  def add_association_edges(graph, node_classes)
    node_classes.map do |klass|
      exclude_verbose_associations(belongs_to_associations(klass)).each do |assoc|
        to_node = target_node_for_association(graph, klass, assoc)
        next unless to_node

        graph.add_edges(klass.name, to_node, label: assoc.name)
      end
    end
  end

  POLYMORPHIC_NODES_SEPARATOR = ",\n"

  def add_polymorphic_nodes(graph)
    polymorphic_nodes_config.each do |node_name, subclasses|
      add_polymorphic_node(graph, node_name, subclasses)
    end
  end

  SUBCLASS_LISTING_LIMIT = 5

  def add_polymorphic_node(graph, node_name, subclasses)
    subclasses_string = if subclasses.size > SUBCLASS_LISTING_LIMIT
                          "(#{subclasses.size} #{node_name.downcase.pluralize})"
                        else
                          subclasses.join(POLYMORPHIC_NODES_SEPARATOR)
                        end

    graph.add_node(node_name, label: "#{node_name}|#{subclasses_string}", shape: "record", style: "dotted",
                              color: POLYMORPHIC_COLOR, fontcolor: POLYMORPHIC_COLOR)
  end

  def add_polymorphic_edges(graph)
    polymorphic_edges_config.each do |association_name, edge_list|
      edge_list.each do |from_class, to_class|
        graph.add_edges(from_class.name, to_class.name, label: association_name,
                                                        color: POLYMORPHIC_COLOR, fontcolor: POLYMORPHIC_COLOR)
      end
    end

    add_custom_polymorphic_edges(graph)
  end

  private

  POLYMORPHIC_COLOR = "blue"

  def add_subclass_edges_for(graph, klass)
    (klass.subclasses & record_classes).each do |subclass|
      parent_node = graph.add_nodes(klass.name, shape: "record", style: "dashed",
                                                color: POLYMORPHIC_COLOR, fontcolor: POLYMORPHIC_COLOR)
      # subclasses = klass.descendants.map(&:name)
      # parent_node = add_polymorphic_node(graph, klass.name, subclasses)

      # skip if edge already exists
      next if parent_node.neighbors.find { |target_node| target_node.id == subclass.name }

      graph.add_edges(parent_node, subclass.name, style: "dotted", color: POLYMORPHIC_COLOR)
    end
  end

  def belongs_to_associations(klass)
    klass.reflect_on_all_associations.select { |assoc| assoc.macro == :belongs_to }
  end

  def exclude_verbose_associations(associations)
    associations.reject { |assoc| [:created_by, :updated_by].include?(assoc.name) }
  end

  def target_node_for_association(graph, klass, assoc)
    if assoc.class_name == "User"
      user_string = (assoc.name == :user) ? "User" : "#{assoc.name} User"
      graph.add_node(klass.name, label: "#{klass.name}\n  (assoc with #{user_string})")
      return nil
    end

    if assoc.polymorphic?
      if polymorphic_edges_config.key?("#{klass.name}\##{assoc.class_name.downcase}")
        # edges will be added to specific nodes
        nil
      else
        # return polymorphic node
        graph.add_nodes(assoc.foreign_type, label: "#{assoc.class_name}\n(#{assoc.foreign_type})",
                                            shape: "box", style: "dashed")
      end
    else
      # return specific node
      # subclasses = assoc.class_name.constantize.descendants.map(&:name)
      # add_polymorphic_node(graph, assoc.class_name, subclasses)
      graph.add_nodes(assoc.class_name)
    end
  end

  DECISION_REVIEW_TYPES = %w[Appeal SupplementalClaim HigherLevelReview].freeze

  def polymorphic_nodes_config
    @polymorphic_nodes_config ||= {
      "Task" => Task.descendants.map(&:name),
      "Claimant" => Claimant.descendants.map(&:name),
      "DecisionReview" => DecisionReview.descendants.map(&:name),
      "ClaimReview" => ClaimReview.descendants.map(&:name),
      "RampReview" => RampReview.descendants.map(&:name),
      "RequestIssue" => %w[RatingRequestIssue NonratingRequestIssue],

      "appeal_type" => %w[Appeal LegacyAppeal],
      "hearing_type" => %w[Hearing LegacyHearing],
      "decision_review_type" => DECISION_REVIEW_TYPES,

      # SupplementalClaim.select(:decision_review_remanded_type).distinct.pluck(:decision_review_remanded_type)
      # => [nil, "Appeal", "SupplementalClaim", "HigherLevelReview"]
      "decision_review_remanded_type" => DECISION_REVIEW_TYPES,

      # RequestIssuesUpdate.select(:review_type).distinct.pluck(:review_type)
      # => ["Appeal", "SupplementalClaim", "HigherLevelReview"]
      "review_type" => DECISION_REVIEW_TYPES,
      # NOTE: There's also 'review_type' for RampIssue that belongs to RampReview. We handle this manually below.
      # To-do: RampIssue#review should be renamed RampIssue#ramp_review to prevent conflict

      # EndProductUpdate.select(:original_decision_review_type).distinct.pluck(:original_decision_review_type)
      # => ["SupplementalClaim", "HigherLevelReview"]
      "original_decision_review_type" => %w[SupplementalClaim HigherLevelReview],

      # EndProductEstablishment.select(:source_type).distinct.pluck(:source_type)
      # => ["DecisionDocument", "SupplementalClaim", "HigherLevelReview", "RampRefiling", "RampElection"]
      "source_type" => %w[DecisionDocument SupplementalClaim HigherLevelReview RampRefiling RampElection],

      # Task.select(:assigned_to_type).distinct.pluck(:assigned_to_type)
      # => ["User", "Organization"]
      "assigned_to_type" => %w[User Organization],

      # RecordSyncedByJob.select(:record_type).distinct.pluck(:record_type)
      # => ["Appeal", "LegacyAppeal"]
      "record_type" => %w[Appeal LegacyAppeal]

      # To-do: DocketSwitch, CavcRemand, and AppellantSubstitution should have a common parent record
      # since they all have a source and target appeal. This would also declutter the diagram.
    }
  end

  def polymorphic_edges_config
    @polymorphic_edges_config ||= {
      # Message.select(:detail_type).distinct.pluck(:detail_type)
      # => ["JobNote", "SupplementalClaim", "HigherLevelReview"]
      "Message#detail" => [
        [Message, JobNote],
        [Message, SupplementalClaim],
        [Message, HigherLevelReview]
      ],

      # Intake.select(:type).distinct.pluck(:type)
      # => ["HigherLevelReviewIntake", "AppealIntake", "SupplementalClaimIntake",
      #     "RampElectionIntake", "RampRefilingIntake"]
      # RampElectionIntake.select(:detail_type).distinct.pluck(:detail_type)
      "AppealIntake#detail" => [[AppealIntake, Appeal]],
      "RampElectionIntake#detail" => [[RampElectionIntake, RampElection]],
      "RampRefilingIntake#detail" => [[RampRefilingIntake, RampRefiling]],
      "HigherLevelReviewIntake#detail" => [[HigherLevelReviewIntake, HigherLevelReview]],
      "SupplementalClaimIntake#detail" => [[SupplementalClaimIntake, SupplementalClaim]],

      # These 2 are non-concrete records
      # Show them so they don't have an edge to generic "Detail (detail_type)" polymorphic node
      "DecisionReviewIntake#detail" => [[DecisionReviewIntake, DecisionReview]],
      "ClaimReviewIntake#detail" => [[ClaimReviewIntake, ClaimReview]],

      # JobNote.select(:job_type).distinct.pluck(:job_type)
      # => ["SupplementalClaim", "HigherLevelReview"]
      "JobNote#job" => [
        [JobNote, SupplementalClaim],
        [JobNote, HigherLevelReview]
      ],

      # RampIssue.select(:review_type).distinct.pluck(:review_type)
      # => ["RampRefiling", "RampElection"]
      # Since edge RampIssue->RampReview exists, don't need more edges
      "RampIssue#review" => [
        # [RampReview, RampRefiling],
        # [RampReview, RampElection]
      ]
    }
  end

  # for custom edges
  CUSTOM_EDGE_COLOR = "#6600cc"

  # Add custom edges to connect related polymorphic-type nodes
  def add_custom_polymorphic_edges(graph)
    [SchedulePeriod, RampReview].each do |klass|
      add_subclass_edges_for(graph, klass)
    end

    ## Custom edges for decision_review_types
    polymorphic_nodes_config.each do |node_name, subclasses|
      next unless subclasses == DECISION_REVIEW_TYPES

      if node_name != "decision_review_type"
        graph.add_edges(node_name, "decision_review_type", label: "a.k.a.", style: "dotted",
                                                           color: CUSTOM_EDGE_COLOR, fontcolor: CUSTOM_EDGE_COLOR)
      end
    end
    # RecordSyncedByJob#record_type may later include other decision_review_types
    # For now, create a 'subset of' association
    graph.add_edges("record_type", "decision_review_type", label: "(subset of)",
                                                           color: CUSTOM_EDGE_COLOR, fontcolor: CUSTOM_EDGE_COLOR)

    ## Custom edges for RampReview
    graph.add_edges(RampIssue.name, RampReview.name, label: "(ramp_)review",
                                                     color: CUSTOM_EDGE_COLOR, fontcolor: CUSTOM_EDGE_COLOR)

    ## Custom edges for Task
    graph.each_node do |node_name, _node|
      if node_name.ends_with?("Task") && node_name.constantize.ancestors.include?(Task)
        graph.add_edges(Task.name, node_name, style: "dotted",
                                              color: CUSTOM_EDGE_COLOR, fontcolor: CUSTOM_EDGE_COLOR)
      end
    end
  end
end
# rubocop:enable Metrics/ModuleLength
