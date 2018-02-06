class AttorneyCaseReview < ActiveRecord::Base
  belongs_to :reviewing_judge, class_name: "User"
  belongs_to :attorney, class_name: "User"


  validate :format_of_document_id

  private

  def format_of_document_id
    # document ID formats: XXXXXXXXX.XXXX and XXXXX-XXXXXXXX.docx where .docx is optional
    document_id && (document_id ~= /^[0-9]{9}\.[0-9]{4}$/ || document_id ~= /^[0-9]{5}-[0-9]{8}(\.docx)?$/)
  end
end