# frozen_string_literal: true

class Api::V3::DecisionReview::IssuesController < Api::V3::BaseController
  def index
    veteran = Veteran.find_by_file_number(request.headers['veteranId'])
    unless veteran
      render_error(
        status: 404,
        code: :veteran_not_found,
        title: "Veteran not found"
      )
      return
    end
    # receipt_date = request.headers['receiptDate']

    # successfully render issues
    render plain: 'so many issues'
  end
end
