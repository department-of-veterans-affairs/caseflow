# frozen_string_literal: true

class Hearings::CreateBillOfMaterialsJob < CaseflowJob
  include Hearings::EnsureCurrentUserIsSet

  def perform(work_order)
    ensure_current_user_is_set
    hash = create_bom_hash(work_order)
    path_to_json_file = save_json_file(hash)
    upload_to_s3!(path_to_json_file)
  end

  private

  def create_bom_hash(work_order)
    {
      bomFormat: "CycloneDX",
      specVersion: "1.3",
      serialNumber: "urn:uuid:#{SecureRandom.uuid}",
      version: 1,
      metadata: {
        timestamp: Time.zone.now,
        tools: metadata_tools,
        component: metadata_component,
        supplier: metadata_supplier
      },
      components: components(transcription_files(work_order[:hearings]))
    }
  end

  def metadata_tools
    {
      vendor: "CASEFLOW",
      name: self.class.to_s,
      version: "1.0",
      hashes: hashes_for_metadata_tools,
      authors: [
        {
          name: "CASEFLOW",
          email: "OITAppealsHelpDesk@va.gov"
        }
      ]
    }
  end

  def hashes_for_metadata_tools
    []
  end

  def metadata_component
    {
      type: "file",
      name: "bva_workorder",
      version: "1.0.0.x"
    }
  end

  def metadata_supplier
    {
      name: "CASEFLOW",
      url: "appeals.cf.uat.ds.va.gov/hearings",
      contact: {
        name: "OITAppealsHelpDesk",
        email: "OITAppealsHelpDesk@va.gov"
      }
    }
  end

  def components(files)
    files.map do |file|
      {
        :type => "file",
        "bom-ref" => file.aws_link,
        :author => file.file_type == "mp3" ? "Webex" : "CASEFLOW",
        :name => file.file_name,
        :version => "1.0.0.x",
        :description => "",
        :hashes => [],
        :content => "",
        :licenses => licenses(file),
        :purl => purl(file)
      }
    end
  end

  def transcription_files(hearing_lookups)
    standard_lookups = hearing_lookups.find_all { |hash| hash[:hearing_type] == Hearing.name }
    legacy_lookups = hearing_lookups.find_all { |hash| hash[:hearing_type] == LegacyHearing.name }
    ActiveRecord::Base.transaction do
      files = transcription_file_query_builder(Hearing.name, standard_lookups.pluck(:hearing_id))
      files_for_legacy = transcription_file_query_builder(LegacyHearing.name, legacy_lookups.pluck(:hearing_id))
      files.merge(files_for_legacy)
    end
  end

  def transcription_file_query_builder(hearing_type, hearing_ids)
    TranscriptionFile.where(
      hearing_type: hearing_type,
      hearing_id: hearing_ids,
      file_type: %w(mp3 rtf),
      file_status: "Successful upload (AWS)"
    )
  end

  def save_json_file(hash)
  end

  def create_md5_hash(file_path)
    # to do - figure out how to encode this hash at some point while the file is still available in tmp
    #         to avoid having to refetch from s3
    Digest::MD5.file(file_path)
  end

  def licenses(file)
    {
      id: "",
      specifiedType: "",
      contentType: "",
      encoding: ""
    }
  end

  def purl(file)
  end

  def upload_to_s3!(file_path)
  end
end
