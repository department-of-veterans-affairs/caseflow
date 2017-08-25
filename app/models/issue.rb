# Note: The vacols_sequence_id column maps to the ISSUE table ISSSEQ column in VACOLS
# Using this and the appeal's vacols_id, we can directly map a Caseflow issue back to its
# VACOLS' equivalent
class Issue < ActiveRecord::Base
  include AssociatedVacolsModel

  vacols_attr_accessor :program, :type, :category, :description, :disposition, :levels,
                       :program_description, :note

  belongs_to :appeal
  belongs_to :hearing, foreign_key: :appeal_id, primary_key: :appeal_id

  PROGRAMS = {
    "02" => :compensation
  }.freeze

  TYPES = {
    "15" => :service_connection
  }.freeze

  CATEGORIES = {
    "04" => :new_material
  }.freeze

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
    super.merge(vacols_attributes.stringify_keys)
  end

  def vacols_attributes
    {
      levels: levels,
      program: program,
      type: type,
      category: category,
      description: description,
      disposition: disposition,
      program_description: program_description,
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
      category_code = hash["isslev1"] || hash["isslev2"] || hash["isslev3"]

      disposition = (VACOLS::Case::DISPOSITIONS[hash["issdc"]] || "other")
                    .parameterize.underscore.to_sym
      new(
        levels: parse_levels_from_vacols(hash),
        vacols_sequence_id: hash["issseq"],
        program: PROGRAMS[hash["issprog"]],
        type: { name: TYPES[hash["isscode"]], label: hash["isscode_label"] },
        note: hash["issdesc"],
        category: CATEGORIES[category_code],
        program_description: "#{hash['issprog']} - #{hash['issprog_label']}",
        description: description(hash),
        disposition: disposition
      )
    end

    def repository
      @repository ||= IssueRepository
    end
  end
end
