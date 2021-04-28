# frozen_string_literal: true

class ExportController < ApplicationController
  def show
    return render_access_error unless current_user.admin?

    no_cache

    # https://chodounsky.com/2015/01/26/respond-to-different-formats-in-rails-controller/
    respond_to do |format|
      format.html { render layout: "plain_application" }
      format.text { render plain:  export_as_text }
      format.json { render json: sanitized_json }
    end
  end

  private

  helper_method :appeal,
                :show_pii_query_param, :treee_fields,
                :available_fields,
                :task_tree_as_text, :intake_as_text,
                :sje, :timeline_data, :network_graph_data

  def export_as_text
    [
      task_tree_as_text,
      intake_as_text
    ].join("\n\n")
  end

  def available_fields
    (Task.column_names + TaskTreeRenderModule::PRESET_VALUE_FUNCS.keys).map(&:to_s)
  end

  def task_tree_as_text
    [appeal.tree(*treee_fields),
     legacy_task_tree_as_text].compact.join("\n\n")
  end

  DEFAULT_TREEE_FIELDS = [:id, :status, :ASGN_BY, :ASGN_TO, :ASGN_DATE, :UPD_DATE, :CRE_DATE, :CLO_DATE].freeze

  def treee_fields
    return DEFAULT_TREEE_FIELDS unless fields_query_param

    fields_query_param.split(",").map(&:strip).map(&:to_sym)
  end

  def legacy_task_tree_as_text
    return nil unless legacy_appeal?

    [legacy_tasks_as_text,
     appeal.location_history.map(&:summary)]
  end

  # :reek:FeatureEnvy
  def legacy_tasks_as_text
    return nil unless legacy_appeal?

    tasks = LegacyWorkQueue.tasks_by_appeal_id(appeal.vacols_id)
    tasks.map do |task|
      "#{task.class.name}, "\
      "\n  assigned_by: #{task.assigned_by&.inspect} #{task.assigned_by&.sdomainid}, "\
      "\n  assigned_to: #{task.assigned_to&.inspect} #{task.assigned_to&.sdomainid}, "\
      "\n  at: #{task.assigned_at}\n"
    rescue StandardError
      "#{task.class.name}, "\
        "\n  assigned_by: #{task.assigned_by&.inspect}, "\
        "\n  assigned_to: #{task.assigned_to&.inspect}, "\
        "\n  at: #{task.assigned_at}\n"
    end.join("\n")
  end

  def intake_as_text
    IntakeRenderer.render(appeal, show_pii: show_pii_query_param)
  end

  def sanitized_json
    return "(LegacyAppeals are not yet supported)".to_json if legacy_appeal?

    sje.file_contents
  end

  def sje
    @sje ||= SanitizedJsonExporter.new(appeal, sanitize: !show_pii_query_param, verbosity: 0)
  end

  # :reek:FeatureEnvy
  def timeline_data
    tasks_as_timeline_data + intakes_as_timeline_data
  end

  # :reek:FeatureEnvy
  def tasks_as_timeline_data
    sje.records_hash[Task.table_name].map do |record|
      record = record.clone
      significant_duration = record["closed_at"] - record["created_at"] > 120 if record["closed_at"]
      end_time = significant_duration ? record["closed_at"] : nil if record["closed_at"]
      { id: "#{Task.name}#{record['id']}",
        content: "#{record['type']}_#{record['id']}",
        start: record["created_at"],
        end: end_time }
    end
  end

  # :reek:FeatureEnvy
  def intakes_as_timeline_data
    sje.records_hash[Intake.table_name].map do |record|
      record = record.clone
      significant_duration = record["completed_at"] - record["created_at"] > 120
      end_time = significant_duration ? record["completed_at"] : nil if record["completed_at"]
      { id: "#{record['type']}#{record['id']}",
        content: "#{record['type']}_#{record['id']}",
        start: record["created_at"],
        end: end_time }
    end
  end

  def network_graph_data
    return "(LegacyAppeals are not yet supported)".to_json if legacy_appeal?

    @network_graph_data ||= create_network_graph_data
  end

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
      Appeal => {
      },
      AppealIntake => {
      },
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
      }
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

  # :reek:FeatureEnvy
  def create_network_graph_data
    # Reminder of records to add
    # pp "----- record_types_not_in_network_graph: #{record_types_not_in_network_graph}"

    {
      nodes: NETWORK_GRAPH_CONFIG[:nodes].keys.map { |klass| prep_nodes(klass) }.flatten,
      edges: NETWORK_GRAPH_CONFIG[:edges].keys.map { |klass| prep_edges(klass) }.flatten
    }
  end

  # :reek:FeatureEnvy
  # The `id` of the nodes are referenced by edges
  def prep_nodes(klass, label_for: nil, id_for: nil)
    id_for ||= NETWORK_GRAPH_CONFIG[:nodes][klass][:id_for] || ->(record) { "#{klass.name}#{record['id']}" }
    label_for ||= NETWORK_GRAPH_CONFIG[:nodes][klass][:label_for] || ->(record) { "#{klass.name}_#{record['id']}" }
    sje.records_hash[klass.table_name].map do |record|
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
      sje.records_hash[klass.table_name].map do |record|
        { from: edge_config[:from_id_for].call(record),
          to: edge_config[:to_id_for].call(record),
          label: edge_config[:label_for]&.call(record) }
      end
    end.flatten
  end

  def legacy_appeal?
    appeal.is_a?(LegacyAppeal)
  end

  def appeal
    @appeal ||= fetch_appeal
  end

  def fetch_appeal
    if Appeal::UUID_REGEX.match?(appeal_id)
      Appeal.find_by(uuid: appeal_id)
    else
      LegacyAppeal.find_by_vacols_id(appeal_id)
    end
  end

  def appeal_id
    params[:appeal_id]
  end

  def show_pii_query_param
    request.query_parameters.key?("show_pii")
  end

  def fields_query_param
    request.query_parameters["fields"]
  end

  def render_access_error
    render(Caseflow::Error::ActionForbiddenError.new(
      message: COPY::ACCESS_DENIED_TITLE
    ).serialize_response)
  end
end
