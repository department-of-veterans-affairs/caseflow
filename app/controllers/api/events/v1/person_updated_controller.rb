# frozen_string_literal: true

class Api::Events::V1::PersonUpdatedController < Api::ApplicationController
  # Checks if API is disabled
  before_action do
    if FeatureToggle.enabled?(:disable_ama_eventing)
      render json: {
        errors: [
          {
            status: "501",
            title: "API is disabled",
            detail: "This endpoint is not supported."
          }
        ]
      }, status: :not_implemented
    end
  end

  def does_person_exist
    person = Person.where(participant_id: params["participant_id"])

    if person.any?
      render json: nil, status: :ok
    else
      render json: nil, status: :no_content
    end
  end

  def person_updated
    Events::PersonUpdated.new(
      params["event_id"],
      params["participant_id"],
      JSON.parse(params["is_veteran"].to_s),
      Events::PersonUpdated::Attributes.new(
        person_updated_attributes
      )
    ).call

    render json: { message: "PersonUpdated successfully processed" }, status: :created
  rescue Caseflow::Error::RedisLockFailed
    render json: { message: "Lock failed" }, status: :conflict
  rescue StandardError
    render json: { message: "Something went wrong" }, status: :unprocessable_entity
  end

  def person_updated_error
    Events::PersonUpdatedError.new(
      params["event_id"],
      params["errored_participant_id"].to_i,
      params["error"]
    ).call

    render json: { "message": "Person Updated Error Saved in Caseflow" }, status: :created
  rescue Caseflow::Error::RedisLockFailed
    render json: { message: "Lock failed" }, status: :conflict
  rescue StandardError
    render json: { message: "Something went wrong" }, status: :unprocessable_entity
  end

  private

  def person_updated_attributes
    params.permit(
      *Events::PersonUpdated::Attributes.members
    ).to_h
  end
end
