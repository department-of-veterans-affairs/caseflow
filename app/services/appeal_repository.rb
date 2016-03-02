require "vbms"

class AppealRepository
  def self.find(vacols_id, _args = {})
    case_record = Records::Case.includes(:folder, :correspondent).find(vacols_id)

    appeal = Appeal.from_records(
      case_record: case_record,
      folder_record: case_record.folder,
      correspondent_record: case_record.correspondent
    )

    appeal.documents = fetch_documents_for(appeal).map do |vbms_document|
      Document.from_vbms_document(vbms_document)
    end

    appeal
  end

  def self.cerify(_appeal)
    # Set certification flags on VACOLS record
    # upload Form 8 to VBMS

    #  @kase.bfdcertool = Time.now
    #  @kase.bf41stat = Date.strptime(params[:certification_date], Date::DATE_FORMATS[:va_date])
    #  @kase.save
    #  @kase.efolder_case.upload_form8(corr.snamef, corr.snamemi, corr.snamel, params[:file_name])
  end

  def self.sanitize_vbms_id(vbms_id)
    "0000#{vbms_id.gsub(/[^0-9]/, '')}"[-8..-1]
  end

  def self.fetch_documents_for(appeal)
    @vbms_client ||= init_vbms_client

    request = VBMS::Requests::ListDocuments.new(sanitize_vbms_id(appeal.vbms_id))
    @vbms_client.send_request(request)
  end

  def self.vbms_config
    config = Rails.application.secrets.vbms.clone

    %w(keyfile saml key cacert cert).each do |file|
      config[file] = File.join(config["env_dir"], config[file])
    end

    config
  end

  def self.init_vbms_client
    VBMS::Client.new(
      vbms_config["url"],
      vbms_config["keyfile"],
      vbms_config["saml"],
      vbms_config["key"],
      vbms_config["keypass"],
      vbms_config["cacert"],
      vbms_config["cert"]
    )
  end
end
