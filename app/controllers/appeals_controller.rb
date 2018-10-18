class AppealsController < ApplicationController
  include Errors

  before_action :react_routed
  before_action :set_application, only: [:document_count, :new_documents]
  # Only whitelist endpoints VSOs should have access to.
  skip_before_action :deny_vso_access, only: [:index, :show_case_list, :show]

  def index
    get_appeals_for_file_number(request.headers["HTTP_VETERAN_ID"]) && return
  end

  def show_case_list
    respond_to do |format|
      format.html { render template: "queue/index" }
      format.json do
        return get_appeals_for_file_number(Veteran.find(params[:caseflow_veteran_id]).file_number)
      end
    end
  end

  def document_count
    render json: { document_count: appeal.number_of_documents }
  rescue StandardError => e
    return handle_non_critical_error("document_count", e)
  end

  def new_documents
    render json: { new_documents: appeal.new_documents_for_user(current_user) }
  rescue StandardError => e
    return handle_non_critical_error("new_documents", e)
  end

  def power_of_attorney
    render json: {
      representative_type: appeal.representative_type,
      representative_name: appeal.representative_name,
      representative_address: appeal.representative_address
    }
  end

  # Veteran address and death date are the only data that is being pulled from BGS,
  # The rest are from VACOLS for now
  def veteran
    data = {
      full_name: appeal.veteran_full_name,
      gender: appeal.veteran_gender,
      date_of_birth: formatted_date_of_birth,
      date_of_death: appeal.veteran_death_date,
      address: {
        address_line_1: appeal.veteran_address_line_1,
        address_line_2: appeal.veteran_address_line_2,
        city: appeal.veteran_city,
        state: appeal.veteran_state,
        zip: appeal.veteran_zip,
        country: appeal.veteran_country
      },
      regional_office: nil
    }

    if appeal.regional_office
      data[:regional_office] = {
        key: appeal.regional_office.key,
        city: appeal.regional_office.city,
        state: appeal.regional_office.state
      }
    end
    render json: data
  end

  def show
    no_cache

    respond_to do |format|
      format.html { render template: "queue/index" }
      format.json do
        id = params[:id]
        MetricsService.record("Get appeal information for ID #{id}",
                              service: :queue,
                              name: "AppealsController.show") do
          appeal = Appeal.find_appeal_by_id_or_find_or_create_legacy_appeal_by_vacols_id(id)

          render json: { appeal: json_appeals([appeal])[:data][0] }
        end
      end
    end
  end

  private

  def set_application
    RequestStore.store[:application] = "queue"
  end

  def get_appeals_for_file_number(file_number)
    return file_number_not_found_error unless file_number

    return get_vso_appeals_for_file_number(file_number) if current_user.vso_employee?

    MetricsService.record("VACOLS: Get appeal information for file_number #{file_number}",
                          service: :queue,
                          name: "AppealsController.index") do

      appeals = Appeal.where(veteran_file_number: file_number).to_a
      # rubocop:disable Lint/HandleExceptions
      begin
        appeals.concat(LegacyAppeal.fetch_appeals_by_file_number(file_number))
      rescue ActiveRecord::RecordNotFound
      end
      # rubocop:enable Lint/HandleExceptions

      render json: {
        appeals: json_appeals(appeals)[:data]
      }
    end
  end

  def get_vso_appeals_for_file_number(file_number)
    return file_access_prohibited_error if !BGSService.new.can_access?(file_number)

    MetricsService.record("VACOLS: Get vso appeals information for file_number #{file_number}",
                          service: :queue,
                          name: "AppealsController.get_vso_appeals_for_file_number") do
      vso_participant_ids = current_user.vsos_user_represents.map { |poa| poa[:participant_id] }

      veteran = Veteran.find_by(file_number: file_number)

      appeals = if veteran
                  veteran.accessible_appeals_for_poa(vso_participant_ids)
                else
                  []
                end
      render json: {
        appeals: json_appeals(appeals)[:data]
      }
    end
  end

  def appeal
    @appeal ||= Appeal.find_appeal_by_id_or_find_or_create_legacy_appeal_by_vacols_id(params[:appeal_id])
  end

  def formatted_date_of_birth
    if appeal.is_a?(LegacyAppeal)
      appeal.veteran_date_of_birth.strftime("%m/%d/%Y") if appeal.veteran_date_of_birth
    else
      appeal.veteran_date_of_birth
    end
  end

  def file_access_prohibited_error
    render json: {
      "errors": [
        "title": "Access to Veteran file prohibited",
        "detail": "User is prohibited from accessing files associated with provided Veteran ID"
      ]
    }, status: 403
  end

  def file_number_not_found_error
    render json: {
      "errors": [
        "title": "Must include Veteran ID",
        "detail": "Veteran ID should be included as HTTP_VETERAN_ID element of request headers"
      ]
    }, status: 400
  end

  def handle_non_critical_error(endpoint, err)
    if !err.class.method_defined? :serialize_response
      code = (err.class == ActiveRecord::RecordNotFound) ? 404 : 500
      err = Caseflow::Error::SerializableError.new(code: code, message: err.to_s)
    end

    DataDogService.increment_counter(
      metric_group: "errors",
      metric_name: "non_critical",
      app_name: RequestStore[:application],
      attrs: {
        endpoint: endpoint
      }
    )

    render err.serialize_response
  end

  def json_appeals(appeals)
    ActiveModelSerializers::SerializableResource.new(
      appeals
    ).as_json
  end
end
