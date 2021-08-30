# frozen_string_literal: true

# This controller allows explains an appeal and associated records via the browser.
# The endpoint is only accessible to System Admins (user.admin? => true).
# The returned data is also used to display visualizations for the specified appeal.

class ExplainController < ApplicationController
  include ExplainAppealEventsConcern
  include ExplainTimelineConcern
  include ExplainNetworkConcern

  def show
    return render_access_error unless access_allowed?

    no_cache

    begin
      # https://chodounsky.com/2015/01/26/respond-to-different-formats-in-rails-controller/
      respond_to do |format|
        format.html { render layout: "plain_application" }
        format.text { render plain:  explain_as_text }
        format.json { render json: sanitized_json }
      end
    rescue StandardError => error
      raise error.full_message
    end
  end

  private

  def access_allowed?
    current_user.admin? ||
      BoardProductOwners.singleton.user_has_access?(current_user) ||
      CaseflowSupport.singleton.user_has_access?(current_user)
  end

  helper_method :legacy_appeal?, :appeal,
                :show_pii_query_param, :fields_query_param, :sections_query_param,
                :treee_fields, :enabled_sections,
                :available_fields,
                :task_tree_as_text, :intake_as_text, :hearing_as_text,
                :event_table_data, :appeal_object_id,
                :timeline_data,
                :network_graph_data,
                :sje

  def appeal_object_id
    @appeal_object_id ||= "#{appeal.class.name}_#{appeal.id}"
  end

  def explain_as_text
    [
      "show_pii = #{show_pii_query_param}",
      task_tree_as_text,
      intake_as_text,
      hearing_as_text,
      JSON.pretty_generate(event_table_data),
      JSON.pretty_generate(timeline_data),
      JSON.pretty_generate(network_graph_data)
    ].join("\n\n")
  end

  def available_fields
    (Task.column_names + TaskTreeRenderModule::PRESET_VALUE_FUNCS.keys).map(&:to_s)
  end

  def task_tree_as_text
    [
      appeal.tree(*treee_fields),
      legacy_task_tree_as_text
    ].compact.join("\n\n")
  end

  DEFAULT_TREEE_FIELDS = [:id, :status, :ASGN_BY, :ASGN_TO, :CRE_DATE, :ASGN_DATE, :UPD_DATE, :CLO_DATE].freeze

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

  def hearing_as_text
    HearingRenderer.render(appeal, show_pii: show_pii_query_param)
  end

  def sanitized_json
    return "(LegacyAppeals are not yet supported)".to_json if legacy_appeal?

    SanitizedJsonExporter.new(appeal, sanitize: !show_pii_query_param, verbosity: 0).file_contents
  end

  def exported_records(klass)
    sje.records_hash[klass.table_name] || []
  end

  def sje
    @sje ||= SanitizedJsonExporter.new(appeal, sanitize: false, verbosity: 0)
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
    request.query_parameters.key?("show_pii") && request.query_parameters["show_pii"]&.downcase != "false"
  end

  def fields_query_param
    request.query_parameters["fields"]
  end

  def sections_query_param
    request.query_parameters["sections"]
  end

  def enabled_sections
    return [] unless sections_query_param

    sections_query_param.split(",").map(&:strip)
  end

  def render_access_error
    render(Caseflow::Error::ActionForbiddenError.new(
      message: COPY::ACCESS_DENIED_TITLE
    ).serialize_response)
  end
end
