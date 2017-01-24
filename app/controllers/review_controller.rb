class ReviewController < ApplicationController
  def index
    render layout: "full_screen"
  end

  def logo_name
    "Decision"
  end

  def pdf
    case params[:document]
    when "0"
      file_name = "VA8.pdf"
    when "1"
      file_name = "FakeDecisionDocument.pdf"
    when "2"
      file_name = "VA9.pdf"
    when "3"
      file_name = "KnockKnockJokes.pdf"
    else
      return redirect_to "/404"
    end

    send_file(
      File.join(Rails.root, "lib", "pdfs", file_name),
      type: "application/pdf",
      disposition: "inline")
  end

  def pdf_urls
    [*0..3].map do |i|
      pdf_review_index_path(document: i)
    end
  end
  helper_method :pdf_urls
end
