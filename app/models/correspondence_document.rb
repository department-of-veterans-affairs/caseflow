# frozen_string_literal: true

class CorrespondenceDocument < CaseflowRecord
  belongs_to :correspondence

  attr_accessor :uuid

  S3_BUCKET_NAME = "correspondence_documents"

  def fetch_document
    if FeatureToggle.enabled?(:correspondence_queue)
      S3Service.files["#{S3_BUCKET_NAME}/#{uuid}"]
    end
  end
end
