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
    invalid_nums = invalid_file_numbers(nums)

    valid_file_nums = "78907"
    # once after generating correspondence for these file numbers we have to send the response
    render json: {
      invalid_file_numbers: invalid_nums,
      valid_file_nums: valid_file_nums
    }, status: :created
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
    # if Rails.deploy_env?(:uat)
    # veteran = VeteranFinder.find_best_match(file_number)

    # return veteran&.fetch_bgs_record.present?

    # elsif Rails.deploy_env?(:demo)
    veterans = Veteran.all.map(&:file_number)

    veterans.any?(file_number.to_s)

    # end
  end

  def invalid_file_numbers(file_number_arr)
    invalid_file_num = []

    file_number_arr.map do |vet_file_num|
      if valid_veteran?(vet_file_num) == false
        invalid_file_num.push(vet_file_num)
      end
    end

    invalid_file_num
  end
end
