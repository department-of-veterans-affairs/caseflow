##
# Certification is responsible for aggregating the information
# and providing methods used to assist the certification of an
# appeal. It also acts as a record of appeals that are certified
# using Caseflow.
#
class Certification < ActiveRecord::Base
  has_one :certification_cancellation, dependent: :destroy

  def start!
    # if we haven't yet started the form8
    # or if we last updated it earlier than 48 hours ago,
    # refresh it with new data.
    if !form8 || form8.updated_at < 48.hours.ago
      @form8 ||= Form8.new(certification_id: id)
      @form8.assign_attributes_from_appeal(appeal)
      @form8.save!
    else
      form8.update_certification_date
    end

    update_attributes!(
      already_certified:   calculate_already_certified,
      vacols_data_missing: calculate_vacols_data_missing,
      nod_matching_at:     calculate_nod_matching_at,
      form9_matching_at:   calculate_form9_matching_at,
      soc_matching_at:     calculate_soc_matching_at,
      ssocs_required:      calculate_ssocs_required,
      ssocs_matching_at:   calculcate_ssocs_matching_at,
      form8_started_at:    (certification_status == :started) ? now : nil
    )

    certification_status
  end

  def to_hash
    serializable_hash(
      methods: :certification_status,
      include: [
        appeal: { methods:
       [:nod_match?,
        :nod_date,
        :soc_match?,
        :soc_date,
        :form9_match?,
        :form9_date,
        :documents_match?,
        :veteran_name,
        :vbms_id] }]
    )
  end

  def complete!(user_id)
    appeal.certify!
    update_attributes!(completed_at: Time.zone.now, user_id: user_id)
  end

  # VACOLS attributes
  def appeal
    @appeal ||= Appeal.find_or_create_by_vacols_id(vacols_id)
  end

  def form8
    @form8 ||= Form8.find_by(certification_id: id)
  end

  def time_to_certify
    return nil if !completed_at || !created_at
    completed_at - created_at
  end

  def self.completed
    where("completed_at IS NOT NULL")
  end

  def self.was_missing_doc
    was_missing_nod.or(was_missing_soc)
                   .or(was_missing_ssoc)
                   .or(was_missing_form9)
  end

  def self.was_missing_nod
    # allow 30 second lag just in case 'nod_matching_at' timestamp is a few seconds
    # greater than 'created_at' timestamp
    where(nod_matching_at: nil).or(where("nod_matching_at > created_at + INTERVAL '30 seconds'"))
  end

  def self.was_missing_soc
    where(soc_matching_at: nil).or(where("soc_matching_at > created_at + INTERVAL '30 seconds'"))
  end

  def self.was_missing_ssoc
    ssoc_required.where(ssocs_matching_at: nil).or(where("ssocs_matching_at > created_at + INTERVAL '30 seconds'"))
  end

  def self.was_missing_form9
    where(form9_matching_at: nil).or(where("form9_matching_at > created_at + INTERVAL '30 seconds'"))
  end

  def self.ssoc_required
    where(ssocs_required: true)
  end

  def certification_status
    if appeal.certified?
      :already_certified
    elsif appeal.missing_certification_data?
      :data_missing
    elsif !appeal.documents_match?
      :mismatched_documents
    else
      :started
    end
  end

  private

  def now
    @now ||= Time.zone.now
  end

  def calculate_form9_matching_at
    appeal.form9_match? ? (form9_matching_at || now) : nil
  end

  def calculate_already_certified
    already_certified || appeal.certified?
  end

  def calculate_vacols_data_missing
    vacols_data_missing || appeal.missing_certification_data?
  end

  def calculate_nod_matching_at
    appeal.nod_match? ? (nod_matching_at || now) : nil
  end

  def calculate_soc_matching_at
    appeal.soc_match? ? (soc_matching_at || now) : nil
  end

  def calculcate_ssocs_matching_at
    (calculate_ssocs_required && appeal.ssoc_all_match?) ? (ssocs_matching_at || now) : nil
  end

  def calculate_ssocs_required
    !appeal.ssoc_dates.empty?
  end

  class << self
    # Return existing certification only if it was not cancelled before
    def find_or_create_by_vacols_id(vacols_id)
      Certification.join_cancellations
                   .where(certification_cancellations: { certification_id: nil })
                   .find_by(vacols_id: vacols_id) || create!(vacols_id: vacols_id)
    end

    def join_cancellations
      Certification.joins("LEFT OUTER JOIN certification_cancellations ON
        certifications.id = certification_cancellations.certification_id")
    end
  end
end
