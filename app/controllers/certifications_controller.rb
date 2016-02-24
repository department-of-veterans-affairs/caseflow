class CertificationsController < ApplicationController
  before_action :verify_authentication

  def new
    render "mismatched_documents" unless appeal.ready_to_certify?
    @form8 = Form8.new_from_appeal(appeal)
  end

  def create
    @form8 = Form8.new(params[:form8])
    output_pdf = @form8.save!
    @pdf_file_name = File.basename(output_pdf)
  end

  def show_pdf
    # rails will strip the extension because '.' is a special character; add it back
    file_name = "#{params[:id]}.pdf"
    absolute_path = PdfService.absolute_path_of(file_name)

    if File.exists?(absolute_path)
      send_file(absolute_path, type: 'application/pdf', disposition: 'inline')
    else
      head :not_found
    end
  end

  private

  def appeal
    @appeal ||= Appeal.find(params[:vacols_id] || params[:form8][:vacols_id])
  end
  helper_method :appeal
end
