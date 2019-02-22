module DocumentConcern
  extend ActiveSupport::Concern

  def number_of_documents_from_caseflow
    count = Document.where(file_number: veteran_file_number).size
    (count != 0) ? count : number_of_documents
  end
end
