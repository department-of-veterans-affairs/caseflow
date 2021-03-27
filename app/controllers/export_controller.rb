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
                :network_graph_data

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

    sje = SanitizedJsonExporter.new(appeal, sanitize: !show_pii_query_param, verbosity: 0)
    sje.file_contents
  end

  def network_graph_data
    return "(LegacyAppeals are not yet supported)".to_json if legacy_appeal?

    sje = SanitizedJsonExporter.new(appeal, sanitize: !show_pii_query_param, verbosity: 0)
    nodes = []
    edges = []

    prep_nodes(sje, Veteran, nodes,
               icon: "\uf29a",
               id_for: ->(klass, record) { "#{klass.name}#{record['file_number']}" })
    sje.records_hash[Veteran.table_name].each do |veteran|
      edges << { from: veteran["id"], to: "#{Person.name}#{veteran['participant_id']}" }
    end

    prep_nodes(sje, Person, nodes,
               icon: "\uf2bb", color: "gray",
               id_for: ->(klass, record) { "#{klass.name}#{record['participant_id']}" },
               label_for: ->(klass, record) { "#{klass.name}_#{record['participant_id']}" })

    prep_nodes(sje, User, nodes,
               icon: "\uf007",
               label_for: ->(klass, record) { "#{klass.name}_#{record['css_id']}" })

    prep_nodes(sje, Organization, nodes,
               icon: "\uf0e8", color: "gray",
               label_for: ->(_klass, record) { "#{record['type']}_#{record['name']}" })
    sje.records_hash[OrganizationsUser.table_name].each do |ou|
      edges << { from: "#{Organization.name}#{ou['organization_id']}", to: "#{User.name}#{ou['user_id']}",
                 label: ou["admin"] ? "admin" : nil }
    end

    prep_nodes(sje, Claimant, nodes,
               label_for: ->(_klass, record) { "#{record['type']}_#{record['participant_id']}" })
    sje.records_hash[Claimant.table_name].each do |claimant|
      edges << { to: claimant["id"], from: "#{claimant['decision_review_type']}#{claimant['decision_review_id']}" }
      edges << { from: claimant["id"], to: "#{Person.name}#{claimant['participant_id']}" }
    end

    prep_nodes(sje, Appeal, nodes, shape: "star", color: "#ff8888")
    sje.records_hash[Appeal.table_name].each do |appeal|
      edges << { from: appeal["id"], to: "#{Veteran.name}#{appeal['veteran_file_number']}" }
    end

    prep_nodes(sje, Task, nodes,
               shape: "box", color: "#00ff00",
               label_for: ->(_klass, record) { "#{record['type']}_#{record['id']}" })

    klass = Task
    sje.records_hash[klass.table_name].each do |task|
      if task["parent_id"]
        edges << { from: "#{klass.name}#{task['parent_id']}", to: task["id"] }
      elsif task["appeal_id"]
        edges << { from: "#{task['appeal_type']}#{task['appeal_id']}", to: task["id"] }
      end
      edges << { to: "#{task['assigned_to_type']}#{task['assigned_to_id']}", from: task["id"] } if task["assigned_to_id"]
      edges << { from: "#{User.name}#{task['assigned_by_id']}", to: task["id"] } if task["assigned_by_id"]
    end

    prep_nodes(sje, RequestIssue, nodes,
               label_for: ->(_klass, record) { "#{record['type']}_#{record['id']}" })
    sje.records_hash[RequestIssue.table_name].each do |ri|
      edges << { to: ri["id"], from: "#{ri['decision_review_type']}#{ri['decision_review_id']}" }
    end

    { nodes: nodes, edges: edges }
  end

  def prep_node(sje, klass, nodes,
                label_for: ->(clazz, record) { "#{clazz.name}_#{record['id']}" },
                id_for: ->(clazz, record) { "#{clazz.name}#{record['id']}" },
                shape: nil, icon: nil, color: nil)
    sje.records_hash[klass.table_name].each do |record|
      record["label"] = label_for.call(klass, record)
      record["id"] = id_for.call(klass, record)
      if icon
        record["icon"] = {
          code: icon,
          color: color.presence
        }
        record["shape"] = "icon"
      end
      record["shape"] = shape if shape
      record["color"] = color if color
      nodes << record
    end
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
