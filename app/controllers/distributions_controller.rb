# frozen_string_literal: true

class DistributionsController < ApplicationController
  def set_application
    RequestStore.store[:application] = "queue"
  end

  def new
    distribution = Distribution.create!(judge: current_user)
    enqueue_distribution_job(distribution)
    render_single(distribution)
  rescue ActiveRecord::RecordInvalid => error
    errors = error.record.errors.details.values.flatten.map { |e| e[:error] }
    return render_single(pending_distribution) if errors.include? :pending_distribution

    render_403_error(errors)
  end

  def show
    distribution = Distribution.find(params[:id])

    return render_403_error(:different_user) if distribution.judge != current_user
    return render_distribution_error if distribution.status == "error"

    render_single(distribution)
  end

  private

  def enqueue_distribution_job(distribution)
    if Rails.env.development? || Rails.env.test?
      StartDistributionJob.perform_now(distribution)
    else
      StartDistributionJob.perform_later(distribution, current_user)
    end
  end

  def render_single(distribution)
    render json: { distribution: distribution.as_json }
  end

  def render_distribution_error
    render json: {
      errors: [{
        "error": "distribution_error",
        "title": "Distribution error",
        "detail": "An error occurred while trying to retrieve cases. Please try again."
      }]
    }, status: :internal_server_error
  end

  def render_403_error(errors)
    errors = [*errors]

    render json: {
      errors: errors.map { |error| json_error(error) }
    }, status: :forbidden
  end

  def json_error(error)
    case error
    when :not_judge
      {
        "error": error,
        "title": "You must be a judge in VACOLS",
        "detail": "In order to request a distribution, you must be listed as a judge in VACOLS."
      }
    when :too_many_unassigned_cases
      {
        "error": error,
        "title": "Cases in your queue are waiting to be assigned",
        "detail": "Please ensure you have eight or fewer unassigned cases before requesting more."
      }
    when :unassigned_cases_waiting_too_long
      {
        "error": error,
        "title": "Cases in your queue are waiting to be assigned",
        "detail": "Please assign all cases that have been waiting in your " \
                  "assignment queue for more than 30 days before requesting more."
      }
    when :different_user
      {
        "error": error,
        "title": "Forbidden",
        "detail": "You don't have permission to access this distribution."
      }
    else
      {
        "error": error,
        "title": "Unknown Error",
        "detail": "Distribution request is invalid."
      }
    end
  end

  def pending_distribution
    Distribution.pending_for_judge(current_user).first
  end
end
