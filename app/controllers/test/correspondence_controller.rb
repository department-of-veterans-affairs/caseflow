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
    valid_file_nums = valid_file_numbers(nums)

    begin
      connect_corr_with_vet(valid_file_nums, correspondence_params[:count])
      return render json: {
        invalid_file_numbers: invalid_nums,
        valid_file_nums: valid_file_nums,
        # correspondence_size: correspondence_size
      }, status: :created
      rescue StandardError => error
      log_error(error)
    end

    # once after generating correspondence for these file numbers we have to send the response
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
    return veteran&.fetch_bgs_record.present?

    else
      veteran = Veteran.find_by(file_number: vet_file_num)
      return veteran if veteran.present?
    end

  end

  def invalid_file_numbers(file_number_arr)

    invalid_file_num = []

      file_number_arr.map do |vet_file_num|
        if valid_veteran?(vet_file_num) === false
          invalid_file_num.push(vet_file_num)
        end
      end

    return invalid_file_num
  end

  def valid_file_numbers(file_number_arr)

    valid_file_num = []

      file_number_arr.map do |vet_file_num|
        if valid_veteran?(vet_file_num) === true
          valid_file_num.push(vet_file_num)
        end
      end

    return valid_file_num
  end

  def initial_values
    @cmp_packet_number = 3000000000
  end

  def connect_corr_with_vet(valid_veterans, count)
    count.times do
      valid_veterans.each do |veterans|
        Correspondence.create!(
          uuid: SecureRandom.uuid,
          portal_entry_date: Time.zone.now,
          source_type: "Mail",
          package_document_type_id: rand(1..15),
          correspondence_type_id: rand(1..8),
          cmp_queue_id: 1,
          cmp_packet_number: @cmp_packet_number,
          va_date_of_receipt: Faker::Date.between(from: 90.days.ago, to: Time.zone.yesterday),
          notes: "This is a test note",
          veteran_id: veteran.id
        )
        @cmp_packet_number = @cmp_packet_number += 1
      end
    end
  end

end
