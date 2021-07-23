# frozen_string_literal: true

# Used by ExplainController to build the data for visualizing a network graph or
# ERD (entity-relationship diagram) based on exported data from SanitizedJsonExporter.

# rubocop:disable Metrics/ModuleLength
module ExplainNetworkConcern
  extend ActiveSupport::Concern

  def network_graph_data
    return "(LegacyAppeals are not yet supported)".to_json if legacy_appeal?

    @network_graph_data ||= create_network_graph_data
  end

  private

  NETWORK_GRAPH_CONFIG = {
    nodes: {
      Veteran => {
        id_for: ->(record) { "#{Veteran.name}#{record['file_number']}" }
      },
      Person => {
        id_for: ->(record) { "#{Person.name}#{record['participant_id']}" },
        label_for: ->(record) { "#{Person.name}_#{record['participant_id']}" }
      },
      User => {
        label_for: ->(record) { record["css_id"] }
      },
      Organization => {
        label_for: ->(record) { "#{record['type']}_#{record['name']}" }
      },
      Claimant => {
        label_for: ->(record) { "#{record['type']}_#{record['participant_id']}" }
      },
      Appeal => {},
      AppealIntake => {},
      CavcRemand => {
        label_for: ->(record) { [record["remand_subtype"], record["cavc_decision_type"], record["id"]].join("_") }
      },
      Task => {
        label_for: ->(record) { "#{record['type']}_#{record['id']}" }
      },
      RequestIssue => {
        label_for: ->(record) { "#{record['type']}_#{record['id']}" }
      },
      DecisionIssue => {
        label_for: ->(record) { "#{record['benefit_type']}_decision#{record['id']}" }
      },
      DecisionDocument => {},
      AttorneyCaseReview => {},
      JudgeCaseReview => {}
    },
    edges: {
      Appeal => [{
        from_id_for: ->(record) { "#{Appeal.name}#{record['id']}" },
        to_id_for: ->(record) { "#{Veteran.name}#{record['veteran_file_number']}" }
      }],
      AppealIntake => [{
        from_id_for: ->(record) { "#{AppealIntake.name}#{record['id']}" },
        to_id_for: ->(record) { "#{record['detail_type']}#{record['detail_id']}" }
      }, {
        from_id_for: ->(record) { "#{User.name}#{record['user_id']}" },
        to_id_for: ->(record) { "#{AppealIntake.name}#{record['id']}" }
      }],
      CavcRemand => [{
        from_id_for: ->(record) { "#{CavcRemand.name}#{record['id']}" },
        to_id_for: ->(record) { "#{Appeal.name}#{record['remand_appeal_id']}" }
      }, {
        from_id_for: ->(record) { "#{Appeal.name}#{record['source_appeal_id']}" },
        to_id_for: ->(record) { "#{CavcRemand.name}#{record['id']}" }
      }, {
        from_id_for: ->(record) { "#{User.name}#{record['created_by_id']}" },
        to_id_for: ->(record) { "#{CavcRemand.name}#{record['id']}" }
      }],
      Veteran => [{
        from_id_for: ->(record) { "#{Veteran.name}#{record['file_number']}" },
        to_id_for: ->(record) { "#{Person.name}#{record['participant_id']}" }
      }],
      Claimant => [{
        from_id_for: ->(record) { "#{Claimant.name}#{record['id']}" },
        to_id_for: ->(record) { "#{Person.name}#{record['participant_id']}" }
      }, {
        from_id_for: ->(record) { "#{record['decision_review_type']}#{record['decision_review_id']}" },
        to_id_for: ->(record) { "#{Claimant.name}#{record['id']}" }
      }],
      OrganizationsUser => [{
        from_id_for: ->(record) { "#{Organization.name}#{record['organization_id']}" },
        to_id_for: ->(record) { "#{User.name}#{record['user_id']}" },
        label_for: ->(record) { record["admin"] ? "admin" : nil }
      }],
      RequestIssue => [{
        from_id_for: ->(record) { "#{record['decision_review_type']}#{record['decision_review_id']}" },
        to_id_for: ->(record) { "#{RequestIssue.name}#{record['id']}" }
      }],
      RequestDecisionIssue => [{
        from_id_for: ->(record) { "#{RequestIssue.name}#{record['request_issue_id']}" },
        to_id_for: ->(record) { "#{DecisionIssue.name}#{record['decision_issue_id']}" }
      }],
      DecisionDocument => [{
        from_id_for: ->(record) { "#{record['appeal_type']}#{record['appeal_id']}" },
        to_id_for: ->(record) { "#{DecisionDocument.name}#{record['id']}" }
      }],
      JudgeCaseReview => [{
        from_id_for: ->(record) { "#{Task.name}#{record['task_id']}" },
        to_id_for: ->(record) { "#{JudgeCaseReview.name}#{record['id']}" }
      }, {
        from_id_for: ->(record) { "#{User.name}#{record['judge_id']}" },
        to_id_for: ->(record) { "#{JudgeCaseReview.name}#{record['id']}" }
      }],
      AttorneyCaseReview => [{
        from_id_for: ->(record) { "#{Task.name}#{record['task_id']}" },
        to_id_for: ->(record) { "#{AttorneyCaseReview.name}#{record['id']}" }
      }, {
        from_id_for: ->(record) { "#{User.name}#{record['attorney_id']}" },
        to_id_for: ->(record) { "#{AttorneyCaseReview.name}#{record['id']}" }
      }],
      Task => [{
        from_id_for: lambda do |record|
                       if record["parent_id"]
                         "#{Task.name}#{record['parent_id']}"
                       elsif record["appeal_id"]
                         "#{record['appeal_type']}#{record['appeal_id']}"
                       end
                     end,
        to_id_for: ->(record) { "#{Task.name}#{record['id']}" }
      }, {
        from_id_for: lambda do |record|
          record["assigned_to_id"] ? "#{record['assigned_to_type']}#{record['assigned_to_id']}" : nil
        end,
        to_id_for: ->(record) { "#{Task.name}#{record['id']}" },
        label_for: ->(_record) { "assigned_to" }
      }, {
        from_id_for: ->(record) { record["assigned_by_id"] ? "#{User.name}#{record['assigned_by_id']}" : nil },
        to_id_for: ->(record) { "#{Task.name}#{record['id']}" },
        label_for: ->(_record) { "assigned_by" }
      }, {
        from_id_for: ->(record) { record["cancelled_by_id"] ? "#{User.name}#{record['cancelled_by_id']}" : nil },
        to_id_for: ->(record) { "#{Task.name}#{record['id']}" },
        label_for: ->(_record) { "cancelled_by" }
      }]
    }
  }.freeze

  # Returns list of tablenames for records that are not yet in the graph
  def record_types_not_in_network_graph
    sje.records_hash.keys - %w[metadata task_timers] -
      NETWORK_GRAPH_CONFIG[:nodes].keys.map(&:table_name) -
      NETWORK_GRAPH_CONFIG[:edges].keys.map(&:table_name)
  end

  def extra_nodes
    # Reminder of records to add
    # pp "----- record_types_not_in_network_graph:", record_types_not_in_network_graph
    record_types_not_in_network_graph.map { |tablename| prep_nodes(tablename.classify.constantize) }.flatten
  end

  # :reek:FeatureEnvy
  def create_network_graph_data
    {
      nodes: NETWORK_GRAPH_CONFIG[:nodes].keys.map { |klass| prep_nodes(klass) }.flatten + extra_nodes,
      edges: NETWORK_GRAPH_CONFIG[:edges].keys.map { |klass| prep_edges(klass) }.flatten
    }
  end

  # :reek:FeatureEnvy
  # The `id` of the nodes are referenced by edges
  def prep_nodes(klass, label_for: nil, id_for: nil)
    id_for ||= NETWORK_GRAPH_CONFIG[:nodes][klass]&.[](:id_for) || ->(record) { "#{klass.name}#{record['id']}" }
    label_for ||= NETWORK_GRAPH_CONFIG[:nodes][klass]&.[](:label_for) || ->(record) { "#{klass.name}_#{record['id']}" }
    exported_records(klass).map do |record|
      record.clone.tap do |clone_record|
        clone_record["label"] = label_for.call(clone_record)
        clone_record["id"] = id_for.call(clone_record)
        clone_record["tableName"] = klass.table_name
      end
    end
  end

  # :reek:FeatureEnvy
  def prep_edges(klass)
    NETWORK_GRAPH_CONFIG[:edges][klass].map do |edge_config|
      exported_records(klass).map do |record|
        { from: edge_config[:from_id_for].call(record),
          to: edge_config[:to_id_for].call(record),
          label: edge_config[:label_for]&.call(record) }
      end
    end.flatten
  end
end
# rubocop:enable Metrics/ModuleLength
