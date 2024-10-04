# frozen_string_literal: true

class WorkQueue::CorrespondenceResponseLetterSerializer
  include FastJsonapi::ObjectSerializer

  attribute :id
  attribute :correspondence_id
  attribute :letter_type
  attribute :title
  attribute :subcategory
  attribute :reason
  attribute :date_sent
  attribute :response_window
  attribute :user_id

  # Days left calculation as an attribute
  attribute :days_left do |object|
    date_sent = object.date_sent.to_date
    response_window = object.response_window

    if response_window.nil?
      "No response window required"
    else
      expiration_date = date_sent + response_window.days
      days_remaining = (expiration_date - Time.zone.today).to_i

      if days_remaining > 0
        day_label = (days_remaining == 1) ? "day" : "days"
        "#{expiration_date.strftime('%m/%d/%Y')} (#{days_remaining} #{day_label} left)"
      else
        "Expired on #{expiration_date.strftime('%m/%d/%Y')}"
      end
    end
  end
end
