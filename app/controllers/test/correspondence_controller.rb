# frozen_string_literal: true

require "rake"

class Test::CorrespondenceController < ApplicationController
  include RunAsyncable

  before_action :verify_access, only: [:index]
  before_action :verify_feature_toggle, only: [:index]

  VALID_CE_API_VBMS_DOCUMENT_TYPE_IDS = [
    163, 1186, 1320, 1333, 1348, 1458, 1608, 1643, 1754
  ].freeze

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

  def connect_corr_with_vet(valid_file_nums, count)
    count.times do
      valid_file_nums.each do |file|
        veteran = Veteran.find_by_file_number(file)
        ActiveRecord::Base.transaction do
          correspondence = create_correspondence(veteran)
          rand(1..5).times do
            create_correspondence_document(veteran, correspondence)
          end
          if correspondence.nod?
            correspondence.correspondence_documents.last.update!(
              document_type: 1250,
              vbms_document_type_id: 1250
            )
          end
        end
      end
    end

    auto_assign_correspondence
  end

  def create_correspondence(veteran)
    Correspondence.create!(
      uuid: SecureRandom.uuid,
      correspondence_type_id: rand(1..8),
      va_date_of_receipt: Faker::Date.between(from: 90.days.ago, to: Time.zone.yesterday),
      notes: "This is a test note",
      veteran: veteran,
      nod: rand(2).zero?
    )
  end

  def create_correspondence_document(veteran, correspondence)
    doc_type = VALID_CE_API_VBMS_DOCUMENT_TYPE_IDS.sample
    CorrespondenceDocument.find_or_create_by(
      document_file_number: veteran.file_number,
      uuid: SecureRandom.uuid,
      correspondence_id: correspondence.id,
      document_type: doc_type,
      vbms_document_type_id: doc_type,
      pages: rand(1..30)
    )
  end

  def auto_assign_correspondence
    batch = BatchAutoAssignmentAttempt.create!(
      user: current_user,
      status: Constants.CORRESPONDENCE_AUTO_ASSIGNMENT.statuses.started
    )

    job_args = {
      current_user_id: current_user.id,
      batch_auto_assignment_attempt_id: batch.id
    }

    perform_later_or_now(AutoAssignCorrespondenceJob, job_args)
  end
end
