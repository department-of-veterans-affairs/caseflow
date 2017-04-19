class Issue
  include ActiveModel::Model

  attr_accessor :program, :type, :category, :description, :disposition,
                :program_description

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

  class << self
    # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
    def load_from_vacols(hash)
      description = ["#{hash["isscode"]} - #{hash["isscode_label"]}"]
      description.push("#{hash["isslev1"]} - #{hash["isslev1_label"]}") if hash["isslev1"]
      description.push("#{hash["isslev2"]} - #{hash["isslev2_label"]}") if hash["isslev2"]
      description.push("#{hash["isslev3"]} - #{hash["isslev3_label"]}") if hash["isslev3"]

      category_code = hash["isslev1"] || hash["isslev2"] || hash["isslev3"]

      disposition = (VACOLS::Case::DISPOSITIONS[hash["issdc"]] || "other")
                    .parameterize.underscore.to_sym

      new(
        program: PROGRAMS[hash["issprog"]],
        type: TYPES[hash["isscode"]],
        category: CATEGORIES[category_code],
        program_description: "#{hash["issprog"]} - #{hash["issprog_label"]}",
        description: description,
        disposition: disposition
      )
    end
  end
end
