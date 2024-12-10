# frozen_string_literal: true

class Api::Events::V1::PersonUpdatedController < Api::ApplicationController
  # Checks if API is disabled
  before_action do
    unless FeatureToggle.enabled?(:enable_person_updated_eventing)
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

  def person_updated
    person = Person.where(participant_id: params["participant_id"])

    if person.any?
      Events::PersonUpdated.new(
        params["event_id"],
        params["participant_id"],
        JSON.parse(params["is_veteran"].to_s),
        Events::PersonUpdated::Attributes.new(
          person_updated_attributes
        )
      ).call

      render json: { message: "PersonUpdated successfully processed" }, status: :ok
    else
      render json: nil, status: :no_content
    end
  rescue Caseflow::Error::RedisLockFailed
    render json: { message: "Lock failed" }, status: :conflict
  rescue StandardError
    render json: { message: "Something went wrong" }, status: :unprocessable_entity
  end

  def person_updated_error
    result = Events::PersonUpdatedError.new(
      params["event_id"],
      params["errored_participant_id"].to_i,
      params["error"]
    ).call

    response_code =
      if result == :created
        :created
      else
        :ok
      end

    render json: { "message": "Person Updated Error Saved in Caseflow" }, status: response_code
  rescue Caseflow::Error::RedisLockFailed
    render json: { message: "Lock failed" }, status: :conflict
  rescue StandardError
    render json: { message: "Something went wrong" }, status: :unprocessable_entity
  end

  private

  def person_updated_attributes
    map = Events::PersonUpdated::PersonUpdatedAttributes.header_attribute_map

    map.reduce({}) do |attributes, (header, attribute)|
      attributes[attribute] = request.headers[header]
      attributes
    end
  end
end
