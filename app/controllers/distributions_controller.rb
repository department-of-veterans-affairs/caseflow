class DistributionsController < ApplicationController
  def set_application
    RequestStore.store[:application] = "queue"
  end

  def new
    return render_403_error(:feature_not_enabled) unless feature_enabled?

    render_single(Distribution.create!(judge: current_user))
  rescue ActiveRecord::RecordInvalid => invalid
    errors = invalid.record.errors.details.values.flatten.map { |e| e[:error] }

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

  def render_single(distribution)
    render json: { distribution: distribution.as_json }
  end

  def render_distribution_error
    render json: {
      errors: [{
        "error": "distribution_error",
        "title": "Distribution Error",
        "detail": "An error occurred while trying to retrieve cases. Please try again."
      }]
    }, status: 500
  end

  def render_403_error(errors)
    errors = [*errors]

    render json: {
      errors: errors.map { |error| json_error(error) }
    }, status: 403
  end

  # rubocop:disable Metrics/MethodLength
  def json_error(error)
    case error
    when :not_judge
      {
        "error": error,
        "title": "You Must Be a Judge in VACOLS",
        "detail": "In order to request a distribution, you must be listed as a judge in VACOLS."
      }
    when :unassigned_cases
      {
        "error": error,
        "title": "You Have Unassigned Cases",
        "detail": "Please assign all unassigned cases before requesting a distribution."
      }
    when :different_user
      {
        "error": error,
        "title": "Forbidden",
        "detail": "You don't have permission to access this distribution."
      }
    when :feature_not_enabled
      {
        "error": error,
        "title": "Automatic Case Distribution Not Enabled",
        "detail": "The automatic case distribution feature has not yet been enabled for you."
      }
    else
      {
        "error": error,
        "title": "Unknown Error",
        "detail": "Distribution request is invalid."
      }
    end
  end
  # rubocop:enable Metrics/MethodLength

  def feature_enabled?
    FeatureToggle.enabled?(:automatic_case_distribution, user: current_user)
  end

  def pending_distribution
    Distribution.pending_for_judge(current_user).first
  end
end
