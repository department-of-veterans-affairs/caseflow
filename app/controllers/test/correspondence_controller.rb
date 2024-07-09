# frozen_string_literal: true

require "rake"

class Test::CorrespondenceController < ApplicationController
  before_action :verify_access, only: [:index]
  before_action :verify_feature_toggle, only: [:index]

  def index
    render_access_error unless verify_access && access_allowed?
  end

  def generate_correspondence
    nums = correspondence_params[:file_numbers].split(",").map(&:strip).reject(&:empty?)
    result = classify_file_numbers(nums)
    invalid_nums = result[:invalid]
    valid_file_nums = result[:valid]

    begin
      connect_corr_with_vet(valid_file_nums, correspondence_params[:count].to_i)
      render json: {
        invalid_file_numbers: invalid_nums,
        valid_file_nums: valid_file_nums
      }, status: :created
    rescue StandardError => error
      log_error(error)
    end
  end

  private

  def correspondence_params
    params.permit(:file_numbers, :count)
  end

  def verify_access
    return true if current_user.admin? || current_user.inbound_ops_team_supervisor? || bva?

    redirect_to "/unauthorized"
  end

  def bva?
    Bva.singleton.user_has_access?(current_user)
  end

  def access_allowed?
    Rails.env.development? ||
      Rails.env.test? ||
      Rails.deploy_env?(:uat) ||
      Rails.deploy_env?(:demo)
  end

  def render_access_error
    render(Caseflow::Error::ActionForbiddenError.new(
      message: COPY::ACCESS_DENIED_TITLE
    ).serialize_response)
  end

  def verify_feature_toggle
    correspondence_queue = FeatureToggle.enabled?(:correspondence_queue)
    correspondence_admin = FeatureToggle.enabled?(:correspondence_admin)
    if !correspondence_queue && verify_access
      redirect_to "/under_construction"
    elsif !correspondence_queue || !verify_access || correspondence_admin
      redirect_to "/unauthorized"
    end
  end

  def valid_veteran?(file_number)
    if Rails.deploy_env?(:uat)
      veteran = VeteranFinder.find_best_match(file_number)
      veteran&.fetch_bgs_record.present?
    else
      veteran = Veteran.find_by(file_number: file_number)
      veteran.present?
    end
  end

  def classify_file_numbers(file_number_arr)
    valid_file_nums = []
    invalid_file_nums = []

    file_number_arr.each do |file_number|
      if valid_veteran?(file_number)
        valid_file_nums << file_number
      else
        invalid_file_nums << file_number
      end
    end

    { valid: valid_file_nums, invalid: invalid_file_nums }
  end

  def connect_corr_with_vet(valid_veterans, count)
    count.times do
      valid_veterans.each do |file|
        veteran = Veteran.find_by_file_number(file)
        create_correspondence(veteran)
      end
    end
  end

  # create correspondence for given veteran
  def create_correspondence(veteran)
    vet = veteran
    corr_type = CorrespondenceType.all.sample
    receipt_date = rand(1.month.ago..1.day.ago)
    nod = [true, false].sample
    doc_type = generate_vbms_doc_type(nod)

    correspondence = ::Correspondence.create!(
      uuid: SecureRandom.uuid,
      va_date_of_receipt: receipt_date,
      notes: generate_notes([corr_type, receipt_date]),
      veteran_id: vet.id,
      nod: nod
    )
    create_correspondence_document(correspondence, vet, doc_type)
  end

  def generate_vbms_doc_type(nod)
    return nod_doc if nod

    non_nod_docs.sample
  end

  # randomly generates notes for the correspondence
  def generate_notes(params)
    note_type = params.sample

    note = ""
    # generate note from value pulled
    case note_type

    when CorrespondenceType
      note = "Correspondence Type is #{note_type&.name}"
    when ActiveSupport::TimeWithZone
      note = "Correspondence added to Caseflow on #{note_type&.strftime("%m/%d/%y")}"
    end

    note
  end

  # :reek:UtilityFunction
  def create_correspondence_document(correspondence, veteran, doc_type)
    CorrespondenceDocument.find_or_create_by!(
      document_file_number: veteran.file_number,
      uuid: SecureRandom.uuid,
      vbms_document_type_id: doc_type[:id],
      document_type: doc_type[:id],
      pages: rand(1..30),
      correspondence_id: correspondence.id
    )
  end

  def nod_doc
    {
      id: 1250,
      description: "VA Form 10182, Decision Review Request: Board Appeal (Notice of Disagreement)"
    }
  end

  # rubocop:disable Metrics/MethodLength
  def non_nod_docs
    [
      {
        id: 1419,
        description: "Reissuance Beneficiary Notification Letter"
      },
      {
        id: 1430,
        description: "Bank Letter Beneficiary"
      },
      {
        id: 1448,
        description: "VR-69 Chapter 36 Decision Letter"
      },
      {
        id: 1452,
        description: "Apportionment - notice to claimant"
      },
      {
        id: 1505,
        description: "Higher-Level Review (HLR) Not Timely Letter"
      },
      {
        id: 1578,
        description: "Pension End of Day Letter"
      }
    ]
  end
end
