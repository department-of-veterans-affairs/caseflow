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

  # :nocov:
  # :reek:FeatureEnvy
  def timeline_data
    tasks_as_timeline_data + intakes_as_timeline_data
  end

  # :reek:FeatureEnvy
  def tasks_as_timeline_data
    sje.records_hash[Task.table_name].map do |record|
      record = record.clone
      significant_duration = record["closed_at"] - record["assigned_at"] > 120
      end_time = significant_duration ? record["closed_at"] : nil if record["closed_at"]
      { id: "#{Task.name}#{record['id']}",
        content: "#{record['type']}_#{record['id']}",
        start: record["assigned_at"],
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

  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
  def create_network_graph_data
    nodes = []
    edges = []

    nodes += prep_nodes(Veteran,
                        id_for: ->(klass, record) { "#{klass.name}#{record['file_number']}" })
    sje.records_hash[Veteran.table_name].each do |veteran|
      edges << { from: "#{Veteran.name}#{veteran['file_number']}", to: "#{Person.name}#{veteran['participant_id']}" }
    end

    nodes += prep_nodes(Person,
                        id_for: ->(klass, record) { "#{klass.name}#{record['participant_id']}" },
                        label_for: ->(klass, record) { "#{klass.name}_#{record['participant_id']}" })

    nodes += prep_nodes(User,
                        label_for: ->(klass, record) { "#{klass.name}_#{record['css_id']}" })

    nodes += prep_nodes(Organization,
                        label_for: ->(_klass, record) { "#{record['type']}_#{record['name']}" })
    sje.records_hash[OrganizationsUser.table_name].each do |ou|
      edges << { from: "#{Organization.name}#{ou['organization_id']}", to: "#{User.name}#{ou['user_id']}",
                 label: ou["admin"] ? "admin" : nil }
    end

    nodes += prep_nodes(Claimant,
                        label_for: ->(_klass, record) { "#{record['type']}_#{record['participant_id']}" })
    sje.records_hash[Claimant.table_name].each do |claimant|
      edges << { to: "#{Claimant.name}#{claimant['id']}",
                 from: "#{claimant['decision_review_type']}#{claimant['decision_review_id']}" }
      edges << { from: "#{Claimant.name}#{claimant['id']}",
                 to: "#{Person.name}#{claimant['participant_id']}" }
    end

    nodes += prep_nodes(Appeal)
    sje.records_hash[Appeal.table_name].each do |appeal|
      edges << { from: "#{Appeal.name}#{appeal['id']}", to: "#{Veteran.name}#{appeal['veteran_file_number']}" }
    end

    nodes += prep_nodes(AppealIntake)
    sje.records_hash[AppealIntake.table_name].each do |intake|
      if intake["user_id"]
        edges << { from: "#{User.name}#{intake['user_id']}",
                   to: "#{AppealIntake.name}#{intake['id']}" }
      end
      edges << { from: "#{AppealIntake.name}#{intake['id']}",
                 to: "#{intake['detail_type']}#{intake['detail_id']}" }
    end

    nodes += prep_nodes(Task,
                        label_for: ->(_klass, record) { "#{record['type']}_#{record['id']}" })
    # Create edges for Tasks
    klass = Task
    sje.records_hash[klass.table_name].each do |task|
      task_id = "#{Task.name}#{task['id']}"
      if task["parent_id"]
        edges << { from: "#{klass.name}#{task['parent_id']}", to: task_id }
      elsif task["appeal_id"]
        edges << { from: "#{task['appeal_type']}#{task['appeal_id']}", to: task_id }
      end
      edges << { to: "#{task['assigned_to_type']}#{task['assigned_to_id']}", from: task_id } if task["assigned_to_id"]
      edges << { from: "#{User.name}#{task['assigned_by_id']}", to: task_id } if task["assigned_by_id"]
      edges << { from: "#{User.name}#{task['cancelled_by_id']}", to: task_id } if task["cancelled_by_id"]
    end

    nodes += prep_nodes(RequestIssue,
                        label_for: ->(_klass, record) { "#{record['type']}_#{record['id']}" })
    sje.records_hash[RequestIssue.table_name].each do |ri|
      edges << { to: "#{RequestIssue.name}#{ri['id']}",
                 from: "#{ri['decision_review_type']}#{ri['decision_review_id']}" }
    end

    { nodes: nodes, edges: edges }
  end
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

  # :reek:FeatureEnvy
  def prep_nodes(klass,
                 label_for: ->(clazz, record) { "#{clazz.name}_#{record['id']}" },
                 id_for: ->(clazz, record) { "#{clazz.name}#{record['id']}" })
    sje.records_hash[klass.table_name].map do |record|
      record.clone.tap do |clone_record|
        clone_record["label"] = label_for.call(klass, clone_record)
        clone_record["id"] = id_for.call(klass, clone_record)
        clone_record["tableName"] = klass.table_name
      end
    end
  end
  # :nocov:

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
