# frozen_string_literal: true

class DistributionsController < ApplicationController
  include RunAsyncable

  def set_application
    RequestStore.store[:application] = "queue"
  end

  def new
    return action_forbidden_error unless current_user_can_request_cases

    distribution = Distribution.create!(judge: judge)
    enqueue_distribution_job(distribution)
    render_single(distribution)
  rescue ActiveRecord::RecordInvalid => error
    render_errors(error)
  end

  def show
    distribution = Distribution.find(params[:id])

    return render_403_error(:different_user) if distribution.judge != current_user
    return render_distribution_error if distribution.status == "error"

    render_single(distribution)
  end

  private

  def enqueue_distribution_job(distribution)
    if run_async?
      StartDistributionJob.perform_later(distribution, judge)
    else
      StartDistributionJob.perform_now(distribution)
    end
  end

  def render_errors(error)
    errors = error.record.errors.details.values.flatten.map { |e| e[:error] }
    return render_single(pending_distribution) if errors.include? :pending_distribution

    render_403_error(errors)
  end

  def render_single(distribution)
    render json: { distribution: DistributionSerializer.new(distribution).as_json }
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
    Distribution.pending_for_judge(judge)
  end

  def judge
    @judge ||= User.find(params[:user_id])
  end

  def current_user_can_request_cases
    current_user == judge || current_user.can_act_on_behalf_of_judges?
  end

  def action_forbidden_error
    render json: {
      "errors": [
        "error": "forbidden",
        "title": "Cannot request cases for another judge",
        "detail": "Only #{SpecialCaseMovementTeam.name} members may request cases for another judge."
      ]
    }, status: :forbidden
  end
end
