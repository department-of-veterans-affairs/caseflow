# Note: The vacols_sequence_id column maps to the ISSUE table ISSSEQ column in VACOLS
# Using this and the appeal's vacols_id, we can directly map a Caseflow issue back to its
# VACOLS' equivalent
class Issue < ActiveRecord::Base
  attr_accessor :program, :type, :category, :description, :disposition,
                :program_description

  belongs_to :appeal
  belongs_to :hearing, foreign_key: :appeal_id, primary_key: :appeal_id

  enum hearing_worksheet_status: {
    allow: 0,
    deny: 1,
    remand: 2,
    dismiss: 3
  }

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

  # "New Material" (and "Non new material") are the exact
  # terms used internally by attorneys/judges. These mean the issue
  # was allowing/denying new material (such as medical evidence) to be used
  # in the appeal
  def new_material?
    program == :compensation &&
      type == :service_connection &&
      category == :new_material
  end

  def non_new_material?
    !new_material?
  end

  def attributes
    super.merge(
      program: program,
      type: type,
      category: category,
      description: description,
      disposition: disposition,
      program_description: program_description
    )
  end

  class << self
    def description(hash)
      description = ["#{hash['isscode']} - #{hash['isscode_label']}"]
      description.push("#{hash['isslev1']} - #{hash['isslev1_label']}") if hash["isslev1"]
      description.push("#{hash['isslev2']} - #{hash['isslev2_label']}") if hash["isslev2"]
      description.push("#{hash['isslev3']} - #{hash['isslev3_label']}") if hash["isslev3"]
      description
    end

    def load_from_vacols(hash)
      category_code = hash["isslev1"] || hash["isslev2"] || hash["isslev3"]

      disposition = (VACOLS::Case::DISPOSITIONS[hash["issdc"]] || "other")
                    .parameterize.underscore.to_sym

      new(
        vacols_sequence_id: hash["issseq"],
        program: PROGRAMS[hash["issprog"]],
        type: TYPES[hash["isscode"]],
        category: CATEGORIES[category_code],
        program_description: "#{hash['issprog']} - #{hash['issprog_label']}",
        description: description(hash),
        disposition: disposition
      )
    end
  end
end
