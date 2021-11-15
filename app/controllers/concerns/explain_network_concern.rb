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
        # claimant is associated with person via participant_id, so show that as the label instead of the record id
        label_for: ->(record) { "#{record['type']}_#{record['participant_id']}" }
      },
      CavcRemand => {
        label_for: ->(record) { "#{record['remand_subtype']}_#{record['cavc_decision_type']}_#{record['id']}" }
      },
      DecisionIssue => {
        label_for: ->(record) { "#{record['benefit_type']}_Decision_#{record['id']}" }
      },
      OrganizationsUser => { skip: true },
      HearingTaskAssociation => { skip: true },
      RequestDecisionIssue => { skip: true }
    },
    edges: {
      Appeal => [{
        to_id_for: ->(record) { "#{Veteran.name}#{record['veteran_file_number']}" }
      }],
      AppealIntake => [{
        from_id_for: ->(record) { "#{Intake.name}#{record['id']}" },
        to_id_for: ->(record) { "#{Appeal.name}#{record['detail_id']}" }
      }, {
        from_id_for: ->(record) { "#{User.name}#{record['user_id']}" },
        to_id_for: ->(record) { "#{Intake.name}#{record['id']}" }
      }],
      CavcRemand => [{
        to_id_for: ->(record) { "#{Appeal.name}#{record['remand_appeal_id']}" }
      }, {
        from_id_for: ->(record) { "#{Appeal.name}#{record['source_appeal_id']}" }
      }, {
        from_id_for: ->(record) { "#{User.name}#{record['created_by_id']}" }
      }],
      Veteran => [{
        from_id_for: ->(record) { "#{Veteran.name}#{record['file_number']}" },
        to_id_for: ->(record) { "#{Person.name}#{record['participant_id']}" }
      }],
      Claimant => [{
        to_id_for: ->(record) { "#{Person.name}#{record['participant_id']}" }
      }, {
        from_id_for: ->(record) { "#{record['decision_review_type']}#{record['decision_review_id']}" }
      }],
      OrganizationsUser => [{
        from_id_for: ->(record) { "#{Organization.name}#{record['organization_id']}" },
        to_id_for: ->(record) { "#{User.name}#{record['user_id']}" },
        label_for: ->(record) { record["admin"] ? "admin" : nil }
      }],
      RequestIssue => [{
        from_id_for: ->(record) { "#{record['decision_review_type']}#{record['decision_review_id']}" }
      }, {
        from_id_for: ->(record) { "#{DecisionIssue.name}#{record['contested_decision_issue_id']}" },
        label_for: ->(_record) { "appealed by" }
      }],
      RequestDecisionIssue => [{
        from_id_for: ->(record) { "#{RequestIssue.name}#{record['request_issue_id']}" },
        to_id_for: ->(record) { "#{DecisionIssue.name}#{record['decision_issue_id']}" },
        label_for: ->(_record) { "decided by" }
      }],
      Hearing => [{
        from_id_for: ->(record) { record["created_by_id"] ? "#{User.name}#{record['created_by_id']}" : nil },
        label_for: ->(_record) { "created" }
      }, {
        from_id_for: ->(record) { record["updated_by_id"] ? "#{User.name}#{record['updated_by_id']}" : nil },
        label_for: ->(_record) { "updated" }
      }, {
        to_id_for: ->(record) { record["hearing_day_id"] ? "#{HearingDay.name}#{record['hearing_day_id']}" : nil },
        label_for: ->(_record) { "on" }
      }],
      HearingTaskAssociation => [{
        from_id_for: ->(record) { "#{Task.name}#{record['hearing_task_id']}" },
        to_id_for: ->(record) { "#{Hearing.name}#{record['hearing_id']}" }
      }],
      HearingDay => [{
        from_id_for: ->(record) { "#{Appeal.name}#{record['appeal_id']}" }
      }, {
        from_id_for: ->(record) { record["created_by_id"] ? "#{User.name}#{record['created_by_id']}" : nil },
        label_for: ->(_record) { "created" }
      }, {
        from_id_for: ->(record) { record["updated_by_id"] ? "#{User.name}#{record['updated_by_id']}" : nil },
        label_for: ->(_record) { "updated" }
      }, {
        to_id_for: ->(record) { record["judge_id"] ? "#{User.name}#{record['judge_id']}" : nil },
        label_for: ->(_record) { "judge" }
      }],
      VirtualHearing => [{
        from_id_for: ->(record) { "#{Hearing.name}#{record['hearing_id']}" }
      }, {
        from_id_for: ->(record) { record["created_by_id"] ? "#{User.name}#{record['created_by_id']}" : nil },
        label_for: ->(_record) { "created" }
      }, {
        from_id_for: ->(record) { record["updated_by_id"] ? "#{User.name}#{record['updated_by_id']}" : nil },
        label_for: ->(_record) { "updated" }
      }],
      DecisionDocument => [{
        from_id_for: ->(record) { "#{record['appeal_type']}#{record['appeal_id']}" }
      }],
      JudgeCaseReview => [{
        from_id_for: ->(record) { "#{Task.name}#{record['task_id']}" }
      }, {
        from_id_for: ->(record) { "#{User.name}#{record['judge_id']}" }
      }],
      AttorneyCaseReview => [{
        from_id_for: ->(record) { "#{Task.name}#{record['task_id']}" }
      }, {
        from_id_for: ->(record) { "#{User.name}#{record['attorney_id']}" }
      }],
      Task => [{
        from_id_for: lambda do |record|
                       if record["parent_id"]
                         "#{Task.name}#{record['parent_id']}"
                       elsif record["appeal_id"]
                         "#{record['appeal_type']}#{record['appeal_id']}"
                       end
                     end
      }, {
        to_id_for: lambda do |record|
          record["assigned_to_id"] ? "#{record['assigned_to_type']}#{record['assigned_to_id']}" : nil
        end,
        label_for: ->(_record) { "assigned_to" }
      }, {
        from_id_for: ->(record) { record["assigned_by_id"] ? "#{User.name}#{record['assigned_by_id']}" : nil },
        label_for: ->(_record) { "assigned" }
      }, {
        from_id_for: ->(record) { record["cancelled_by_id"] ? "#{User.name}#{record['cancelled_by_id']}" : nil },
        label_for: ->(_record) { "cancelled" }
      }]
    }
  }.freeze

  # :reek:FeatureEnvy
  def create_network_graph_data
    {
      nodes: NETWORK_GRAPH_CONFIG[:nodes].keys.map { |klass| prep_nodes(klass) }.flatten + remaining_nodes,
      edges: NETWORK_GRAPH_CONFIG[:edges].keys.map { |klass| prep_edges(klass) }.flatten
    }
  end

  # List of tablenames that are not explicitly listed in NETWORK_GRAPH_CONFIG
  def remaining_table_names
    sje.records_hash.keys - %w[metadata task_timers] - NETWORK_GRAPH_CONFIG[:nodes].keys.map(&:table_name)
  end

  # Nodes for remaining records to add to graph
  def remaining_nodes
    remaining_table_names.map { |tablename| prep_nodes(tablename.classify.constantize) }.flatten
  end

  # Use `fetch` so that if key doesn't exist, an error is raised
  DEFAULT_NODE_ID_LAMBDA = ->(record) { "#{record.fetch('class')}#{record.fetch('id')}" }
  DEFAULT_NODE_LABEL_LAMBDA = ->(record) { "#{record['type'] || record.fetch('class')}_#{record.fetch('id')}" }

  # :reek:FeatureEnvy
  # The `id` of the nodes are referenced by edges
  def prep_nodes(klass, label_for: nil, id_for: nil)
    return [] if NETWORK_GRAPH_CONFIG[:nodes][klass]&.fetch(:skip, false)

    id_for ||= NETWORK_GRAPH_CONFIG[:nodes][klass]&.[](:id_for) || DEFAULT_NODE_ID_LAMBDA
    label_for ||= NETWORK_GRAPH_CONFIG[:nodes][klass]&.[](:label_for) || DEFAULT_NODE_LABEL_LAMBDA
    exported_records(klass).map(&:clone).map do |record|
      # Set some attributes that can be used by lambdas
      record["tableName"] = klass.table_name
      record["class"] = klass.name

      # Now call lambdas
      record["label"] = label_for.call(record)
      # Run this lambda last since it overrides "id", which is possibly used by other lambdas
      record["id"] = id_for.call(record)
      record
    end
  end

  # Use `fetch` to raise error if key doesn't exist
  DEFAULT_EDGE_FROM_ID_LAMBDA = ->(record) { "#{record.fetch('class')}#{record.fetch('id')}" }
  DEFAULT_EDGE_TO_ID_LAMBDA = ->(record) { "#{record.fetch('class')}#{record.fetch('id')}" }

  # :reek:FeatureEnvy
  def prep_edges(klass)
    NETWORK_GRAPH_CONFIG[:edges][klass].map do |edge_config|
      from_id_for = edge_config&.[](:from_id_for) || DEFAULT_EDGE_FROM_ID_LAMBDA
      to_id_for = edge_config&.[](:to_id_for) || DEFAULT_EDGE_TO_ID_LAMBDA

      exported_records(klass).map(&:clone).map do |record|
        record["class"] = klass.name

        {
          from: from_id_for.call(record),
          to: to_id_for.call(record),
          label: edge_config[:label_for]&.call(record)
        }
      end
    end.flatten
  end
end
# rubocop:enable Metrics/ModuleLength
