# frozen_string_literal: true

module Hearings
  class CreateBillOfMaterialsJob < CaseflowJob
    include Hearings::EnsureCurrentUserIsSet

    class BomFileUploadError < StandardError; end

    class BomFile
      # Purpose: We cannot track a BoM file using the transcription_files table since it does not belong to a hearing.
      # .......  This P.O.R.O. will allow us to use TranscriptionFileUpload to upload the BoM file to s3 by passing in
      # .......  an object shaped similarly to a TranscriptionFile record.
      attr_reader :file_name, :file_type, :tmp_location

      def initialize(file_path)
        @file_name = File.basename(file_path)
        @file_type = "json"
        @tmp_location = file_path
      end

      def update_status!(*args); end
    end

    retry_on(TranscriptionFileUpload::FileUploadError) do |job, _exception|
      job.clean_up_tmp_file
      fail BomFileUploadError
    end

    def perform(work_order)
      @work_order = work_order
      ensure_current_user_is_set
      bom_hash = create_bom_hash
      save_json_file(bom_hash)
      upload_to_s3!(@bom_file_path)
      true
    end

    def clean_up_tmp_file
      File.delete(@bom_file_path) if @bom_file_path
    end

    private

    def create_bom_hash
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
        components: components(transcription_files(@work_order[:hearings]))
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
      job_file_path = Rails.root.join("app", "jobs", "hearings", "create_bill_of_materials_job.rb")
      [
        {
          alg: "MD5",
          content: create_md5_hash(job_file_path)
        }
      ]
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

    def file_description(file_type)
      case file_type
      when "mp3"
        "Audio file for appeal"
      when "rtf"
        "Word compatible file created from supplied vtt file"
      end
    end

    def components(files)
      components = files.map do |file|
        {
          :type => "file",
          "bom-ref" => bom_ref(file),
          :author => file.file_type == "mp3" ? "Webex" : "CASEFLOW",
          :name => file.file_name,
          :version => "1.0.0.x",
          :description => file_description(file.file_type),
          :hashes => component_hashes(file.file_name),
          :licenses => licenses(file.file_name),
          :purl => purl(file)
        }
      end
      components << work_order_file_component
    end

    def work_order_file_component
      work_order_file_name = @work_order[:work_order_name] + ".xls"
      {
        :type => "file",
        "bom-ref" => bom_ref(work_order_file_name),
        :author => "CASEFLOW",
        :name => work_order_file_name,
        :version => "1.0.0.x",
        :description => "Work order file",
        :hashes => component_hashes(work_order_file_name),
        :licenses => licenses(work_order_file_name),
        :purl => purl(work_order_file_name)
      }
    end

    def bom_ref(file)
      bucket = "vaec-appeals-caseflow-#{Rails.deploy_env}"
      base = "https://#{bucket}.s3.#{ENV['AWS_REGION']}.amazonaws.com"
      case file
      when TranscriptionFile
        "#{base}/#{file.aws_link}"
      when String
        # for work order xls
        "#{base}/#{bucket}/transcription_text/#{file}"
      end
    end

    def component_hashes(file_name)
      base_path = Rails.root.join("tmp", "transcription_files")
      tmp_dirs = {
        mp3: base_path.join("mp3"),
        rtf: base_path.join("rtf"),
        xls: base_path.join("xls"),
        csv: base_path.join("csv")
      }
      extension = file_name.split(".").last.to_sym
      [
        {
          alg: "MD5",
          content: create_md5_hash(tmp_dirs[extension].join(file_name))
        }
      ]
    end

    def transcription_files(hearing_lookups)
      standard_lookups = hearing_lookups.find_all { |hash| hash[:hearing_type] == Hearing.name }
      legacy_lookups = hearing_lookups.find_all { |hash| hash[:hearing_type] == LegacyHearing.name }
      ActiveRecord::Base.transaction do
        files = transcription_file_query_builder(Hearing.name, standard_lookups.pluck(:hearing_id))
        files_for_legacy = transcription_file_query_builder(LegacyHearing.name, legacy_lookups.pluck(:hearing_id))
        files + files_for_legacy
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
      tmp_path = Rails.root.join("tmp", "transcription_files", "json")
      FileUtils.mkdir_p(tmp_path) unless File.directory?(tmp_path)
      file_name = "#{@work_order[:work_order_name].sub('BVA', 'BOM')}.json"
      file_path = tmp_path.join(file_name)
      File.open(file_path, "w") { |f| f.write(JSON.pretty_generate(hash)) }
      @bom_file_path = file_path.to_s
    end

    def create_md5_hash(file_path)
      Digest::MD5.file(file_path)
    end

    def licenses(file_name, id = "MIT")
      extension = file_name.split(".").last
      content_type = case extension
                     when "mp3" then "audio/mp3"
                     when "rtf" then "application/rtf"
                     when "xls"
                       id = "GPL-3.0"
                       "application/vnd.ms-excel"
                     end
      generate_license_hash(id, content_type, extension)
    end

    def generate_license_hash(id, content_type, extension)
      [
        {
          license: {
            id: id,
            text: {
              contentType: content_type,
              encoding: extension
            }
          }
        }
      ]
    end

    def purl(file)
      case file
      when TranscriptionFile
        name_without_extension = file.file_name.split(".")[0]
        "pkg:#{file.file_type}/#{name_without_extension}@1.0.0"
      when String
        # for work order xls since there is no associated db record
        name_without_extension = file.split(".")[0]
        "pkg:xls/#{name_without_extension}@1.0.0"
      end
    end

    def upload_to_s3!(file_path)
      ruby_object = BomFile.new(file_path)
      TranscriptionFileUpload.new(ruby_object).call
    end
  end
end
