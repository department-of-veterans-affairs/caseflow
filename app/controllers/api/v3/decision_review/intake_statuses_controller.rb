# frozen_string_literal: true

class Api::V3::DecisionReview::IntakeStatusesController < Api::V3::BaseController
  def show
    unless decision_review
      render_no_decision_review_error
      return
    end

    render_hash, headers = intake_status.render_hash_and_headers

    load_headers(headers)
    render render_hash
  rescue StandardError
    render_unknown_error
  end

  private

  def uuid
    params[:uuid]
  end

  def decision_review
    @decision_review ||= DecisionReview.where_uuid(uuid)
  end

  def intake
    @intake ||= decision_review.intake
  end

  def intake_status
    Api::V3::DecisionReview::IntakeStatus.new(intake)
  end

  def load_headers(headers)
    headers.each { |key, val| response.set_header(key, val) }
  end

  def render_unknown_error
    render_error status: 500, code: :unknown_error, title: "Unknown error"
  end

  def render_no_decision_review_error
    render_error(
      status: 404,
      code: :decision_review_not_found,
      title: "Unable to find a DecisionReview with uuid: #{uuid}"
    )
  end

  def render_error(status:, code:, title:)
    render(
      json: { errors: [{ status: status, code: code, title: title }] },
      status: status
    )
  end
end

# i think render_hash should become render_hash_and_headers
#
# [{json, status}, {Location: stnrset}]
#
# returns 200
# until 300
#
#
# HigherLevelReviewController needs to override this and return 202
#
# update docs for more asyncable statuses
#
# make intake_status_error class ?
#
# update docs to add status to returns?
