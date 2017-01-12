class ReviewController < ApplicationController
  def index
  end

  def logo_name
    "Decision"
  end

  def pdf
    puts params
    if params[:document] == "0"
      file_name = "VA8.pdf"
    elsif params[:document] == "1"
      file_name = "FakeDecisionDocument.pdf"
    elsif params[:document] == "2"
      file_name = "VA9.pdf"
    elsif params[:document] == "3"
      file_name = "KnockKnockJokes.pdf"
    else
      return redirect_to "/404"
    end
    send_file(File.join(Rails.root, "lib", "pdfs", file_name), type: "application/pdf", disposition: "inline")
  end

  def get_pdfs
    pdfs = []
    for i in 0..3
      pdfs.push(pdf_review_index_path(document: i))
    end
    puts pdfs
    pdfs
  end
  helper_method :get_pdfs
end
