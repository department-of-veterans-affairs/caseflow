# frozen_string_literal: true

##
# Class to extract classes for ERD (entity relationship diagram) documentation.
# Relies on `record_classes` being defined elsewhere.

# rubocop:disable Metrics/ModuleLength
# :reek:TooManyConstants
module ErdRecordAssociations
  def add_subclass_edges(graph, classes)
    classes.each { |klass| add_subclass_edges_for(graph, klass) }
  end

  # These associations typically indicate foreign keys
  def add_association_edges(graph, node_classes)
    node_classes.map do |klass|
      exclude_verbose_associations(belongs_to_associations(klass)).each do |assoc|
        to_node = target_node_for_association(graph, klass, assoc)
        next unless to_node

        graph.add_edges(klass.name, to_node, label: assoc.name)
      end
    end
  end

  def add_polymorphic_nodes(graph)
    polymorphic_nodes_config.each do |node_name, subclasses|
      add_polymorphic_node(graph, node_name, subclasses)
    end
  end

  POLYMORPHIC_COLOR ||= "#0000ff" # blue

  #:reek:UtilityFunction
  def add_polymorphic_node(graph, node_name, subclasses)
    # To avoid clutter, don't list all the subclasses if there are too many (e.g., Task subclasses)
    subclasses_string = if subclasses.size > 5
                          "(#{subclasses.size} #{node_name.downcase.pluralize})"
                        else
                          subclasses.join(",\n")
                        end

    graph.add_node(node_name, label: "#{node_name}|#{subclasses_string}",
                              shape: "record", style: "dotted",
                              color: POLYMORPHIC_COLOR,
                              fontcolor: POLYMORPHIC_COLOR)
  end

  def add_polymorphic_edges(graph)
    polymorphic_edges_config.each do |association_name, edge_list|
      edge_list.each do |from_class, to_class|
        graph.add_edges(from_class.name, to_class.name, label: association_name,
                                                        color: POLYMORPHIC_COLOR,
                                                        fontcolor: POLYMORPHIC_COLOR)
      end
    end

    add_custom_polymorphic_edges(graph)
  end

  private

  SUBCLASS_COLOR ||= "#000099" # dark blue

  def add_subclass_edges_for(graph, klass)
    (klass.subclasses & record_classes).each do |subclass|
      parent_node = graph.add_node(klass.name, shape: "record", style: "dashed",
                                               color: SUBCLASS_COLOR,
                                               fontcolor: SUBCLASS_COLOR)

      # skip if edge already exists
      next if parent_node.neighbors.find { |target_node| target_node.id == subclass.name }

      graph.add_edges(parent_node, subclass.name, style: "dotted",
                                                  color: SUBCLASS_COLOR)
    end
  end

  def belongs_to_associations(klass)
    klass.reflect_on_all_associations.select { |assoc| assoc.macro == :belongs_to }
  end

  EXCLUDED_ASSOCIATIONS ||= [
    # These are common Rails fields that clutter the visualization
    :created_by, :updated_by,

    # These associations are created dynamically by BelongsToPolymorphicAppealConcern
    # and is already indicated in the visualization
    :ama_appeal, :legacy_appeal, :supplemental_claim, :higher_level_review,

    # These associations are created dynamically by BelongsToPolymorphicHearingConcern
    # and is already indicated in the visualization
    :ama_hearing, :legacy_hearing
  ].freeze
  def exclude_verbose_associations(associations)
    associations.reject { |assoc| EXCLUDED_ASSOCIATIONS.include?(assoc.name) }
  end

  def target_node_for_association(graph, klass, assoc)
    label_suffix = label_suffix(graph, klass, assoc)
    if label_suffix
      # set label for source node
      graph.add_node(klass.name, label: "#{klass.name}#{label_suffix}")
      # return nil so that an edge is not created
      return nil
    end

    if assoc.polymorphic?
      if polymorphic_edges_config.key?("#{klass.name}\##{assoc.class_name.downcase}")
        # edges will be added to specific nodes
        nil
      else
        # return polymorphic node
        graph.add_node(assoc.foreign_type, label: "#{assoc.class_name}\n(#{assoc.foreign_type})",
                                           shape: "box", style: "dashed")
      end
    else
      # return class-specific (non-polymorphic) node
      graph.add_node(assoc.class_name)
    end
  end

  def label_suffix(graph, klass, assoc)
    assoc_label = case assoc.class_name
                  when "User"
                    (assoc.name == :user) ? assoc.class_name : "#{assoc.name} User"
                  when "Veteran", "Task"
                    assoc.class_name
                  end

    return nil unless assoc_label

    suffixes = add_label_suffix(graph, klass, assoc_label)
    return "\n(associated with: #{suffixes.first})" if suffixes.length == 1

    "\n(associated with:\n#{suffixes.join(',\n')})"
  end

  def add_label_suffix(graph, klass, assoc_label)
    node_label_suffixes = node_label_suffixes_for(graph)

    suffixes = node_label_suffixes.fetch(klass.name, [])
    if suffixes.exclude?(assoc_label)
      suffixes << assoc_label
      node_label_suffixes[klass.name] ||= suffixes
    end
    suffixes
  end

  def node_label_suffixes_for(graph)
    @graph_node_label_suffixes ||= {}
    node_label_suffixes = @graph_node_label_suffixes.fetch(graph, {})
    @graph_node_label_suffixes[graph] ||= node_label_suffixes
    node_label_suffixes
  end

  DECISION_REVIEW_TYPES ||= %w[Appeal SupplementalClaim HigherLevelReview].freeze

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
  CUSTOM_POLYMORPHIC_EDGE_COLORS ||= {
    color: "#6600cc",
    fontcolor: "#6600cc"
  }.freeze

  # Add custom edges to connect related polymorphic-type nodes
  def add_custom_polymorphic_edges(graph)
    [SchedulePeriod, RampReview].each do |klass|
      add_subclass_edges_for(graph, klass)
    end

    ## Custom edges for decision_review_types
    polymorphic_nodes_config.each do |node_name, subclasses|
      next unless subclasses == DECISION_REVIEW_TYPES

      next unless node_name != "decision_review_type"

      graph.add_edges(node_name, "decision_review_type",
                      label: "a.k.a.", style: "dotted", **CUSTOM_POLYMORPHIC_EDGE_COLORS)
    end
    # RecordSyncedByJob#record_type may later include other decision_review_types
    # For now, create a 'subset of' association
    graph.add_edges("record_type", "decision_review_type", label: "(subset of)", **CUSTOM_POLYMORPHIC_EDGE_COLORS)

    ## Custom edges for RampReview
    graph.add_edges(RampIssue.name, RampReview.name, label: "(ramp_)review", **CUSTOM_POLYMORPHIC_EDGE_COLORS)

    ## Custom edges for Task
    graph.each_node do |node_name, _node|
      next unless node_name.ends_with?("Task") && node_name.constantize.ancestors.include?(Task)

      graph.add_edges(Task.name, node_name, style: "dotted", **CUSTOM_POLYMORPHIC_EDGE_COLORS)
    end
  end
end
# rubocop:enable Metrics/ModuleLength
