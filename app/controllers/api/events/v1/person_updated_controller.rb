# frozen_string_literal: true

class Api::V1::PersonUpdatedController < Api::ApplicationController
  def does_person_exist
    person = Person.where(participant_id: params["participant_id"])

    if person.any?
      render json: nil, status: :no_content
    else
      render json: nil, status: :ok
    end
  end
end
