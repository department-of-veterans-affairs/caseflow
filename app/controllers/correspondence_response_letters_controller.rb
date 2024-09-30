# frozen_string_literal: true

class CorrespondenceResponseLettersController < ApplicationController
  def create
    correspondence_response_letter = CorrespondenceResponseLetter.new(correspondence_response_letter_params)
    if correspondence_response_letter.save
      render json: correspondence_response_letter, status: :ok
    else
      render json: correspondence_response_letter.errors.full_messages, status: :unprocessable_entity
    end
  end

  def correspondence_response_letter_params
    params.require(:correspondence_response_letter).permit(:title, :date_sent, :letter_type, :subcategory, :reason,
                                                           :response_window, :user_id)
  end
end
