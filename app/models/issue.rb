# Note: The vacols_sequence_id column maps to the ISSUE table ISSSEQ column in VACOLS
# Using this and the appeal's vacols_id, we can directly map a Caseflow issue back to its
# VACOLS' equivalent
class Issue
  include ActiveModel::Model

  attr_accessor :id, :program, :code, :category, :disposition,
                :close_date, :levels, :note, :vacols_sequence_id

  # These attributes are only loaded if we run the joins to ISSREF and VFTYPES (see VACOLS::CaseIssue)
  attr_writer :type, :description, :program_description

  def type
    fail Caseflow::Error::AttributeNotLoaded if @type == :not_loaded
    @type
  end

  def description
    fail Caseflow::Error::AttributeNotLoaded if @description == :not_loaded
    @description
  end

  def program_description
    fail Caseflow::Error::AttributeNotLoaded if @program_description == :not_loaded
    @program_description
  end

  PROGRAMS = {
    "01" => :vba_burial,
    "02" => :compensation,
    "03" => :education,
    "04" => :insurance,
    "05" => :loan_guaranty,
    "06" => :medical,
    "07" => :pension,
    "08" => :vre,
    "09" => :other,
    "10" => :bva,
    "11" => :nca_burial,
    "12" => :fiduciary
  }.freeze

  TYPES = {
    "15" => :service_connection
  }.freeze

  CATEGORIES = {
    "04" => :new_material
  }.freeze

  def issue_code
    "#{program}-#{code}"
  end

  def non_new_material_allowed?
    !new_material? && allowed?
  end

  def allowed?
    disposition == :allowed
  end

  def remanded?
    disposition == :remanded
  end

  # "New Material" (and "Non new material") are the exact
  # terms used internally by attorneys/judges. These mean the issue
  # was allowing/denying new material (such as medical evidence) to be used
  # in the appeal
  def new_material?
    program == :compensation &&
      type[:name] == :service_connection &&
      category == :new_material
  end

  def non_new_material?
    !new_material?
  end

  def attributes
    {
      vacols_sequence_id: vacols_sequence_id,
      levels: levels,
      program: program,
      type: type,
      category: category,
      description: description,
      disposition: disposition,
      close_date: close_date,
      program_description: program_description,
      note: note
    }
  end

  def description_attributes
    {
      program_description: program_description,
      description: description,
      note: note
    }
  end

  class << self
    attr_writer :repository

    def description(hash)
      description = ["#{hash['isscode']} - #{hash['isscode_label']}"]
      description.push("#{hash['isslev1']} - #{hash['isslev1_label']}") if hash["isslev1"]
      description.push("#{hash['isslev2']} - #{hash['isslev2_label']}") if hash["isslev2"]
      description.push("#{hash['isslev3']} - #{hash['isslev3_label']}") if hash["isslev3"]
      description
    end

    def parse_levels_from_vacols(hash)
      levels = []
      levels.push((hash["isslev1_label"]).to_s) if hash["isslev1_label"]
      levels.push((hash["isslev2_label"]).to_s) if hash["isslev2_label"]
      levels.push((hash["isslev3_label"]).to_s) if hash["isslev3_label"]
      levels
    end

    def load_from_vacols(hash)
      attributes = {
        id: hash["isskey"],
        levels: parse_levels_from_vacols(hash),
        vacols_sequence_id: hash["issseq"],
        program: PROGRAMS[hash["issprog"]],
        code: hash["isscode"],
        note: hash["issdesc"],
        category: CATEGORIES[(hash["isslev1"] || hash["isslev2"] || hash["isslev3"])],
        disposition: (VACOLS::Case::DISPOSITIONS[hash["issdc"]] || "other").parameterize.underscore.to_sym,
        close_date: AppealRepository.normalize_vacols_date(hash["issdcls"])
      }

      if hash.key? "issprog_label"
        attributes[:type] = { name: TYPES[hash["isscode"]], label: hash["isscode_label"] }
        attributes[:description] = description(hash)
        attributes[:program_description] = "#{hash['issprog']} - #{hash['issprog_label']}"
      else
        attributes[:type] = attributes[:description] = attributes[:program_description] = :not_loaded
      end

      new(**attributes)
    end

    def repository
      @repository ||= IssueRepository
    end
  end
end
