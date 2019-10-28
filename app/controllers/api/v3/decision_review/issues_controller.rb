# frozen_string_literal: true

class Api::V3::DecisionReview::IssuesController < Api::V3::BaseController
  def index
    # REVIEW move these before filters?
    veteran = Veteran.find_by_file_number(request.headers['veteranId'])
    unless veteran
      render_error(
        status: 404,
        code: :veteran_not_found,
        title: "Veteran not found"
      )
      return
    end

    receipt_date = Date.parse(request.headers['receiptDate'])
    if receipt_date < Constants::DATES["AMA_ACTIVATION"].to_date || Date.today < receipt_date
      render_error(
        status: 422,
        code: :bad_receipt_date,
        title: "Bad receipt date"
      )
      return
    end

    # successfully render issues
    render plain: 'so many issues'
  end
end
