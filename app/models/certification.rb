##
# Certification is responsible for aggregating the information
# and providing methods used to assist the certification of an
# appeal. It also acts as a record of appeals that are certified
# using Caseflow.
#
class Certification < ActiveRecord::Base
  has_one :certification_cancellation, dependent: :destroy

  def async_start!
    return certification_status unless can_be_updated?

    update_attributes!(
      v2: true,
      loading_data: true,
      loading_data_failed: false
    )

    # Most developers don't run shoryuken in development mode.
    if Rails.env.development? || Rails.env.test?
      StartCertificationJob.perform_now(self)
    else
      StartCertificationJob.perform_later(self, RequestStore[:current_user], RequestStore[:current_user].ip_address)
    end
  end

  def bgs_rep_address_found?
    !!appeal.power_of_attorney.bgs_representative_address
  end

  def to_hash
    serializable_hash(
      methods: [:certification_status, :bgs_rep_address_found?],
      include: [
        :form8,
        appeal: {
          include: [:nod, :soc, :form9, :ssocs],
          methods: [:documents_match?, :veteran_name, :vbms_id]
        }
      ]
    )
  end

  def rep_name
    if poa_correct_in_vacols || poa_matches
      vacols_representative_name
    elsif poa_correct_in_bgs
      bgs_representative_name
    else
      representative_name
    end
  end

  def rep_type
    if poa_correct_in_vacols || poa_matches
      vacols_representative_type
    elsif poa_correct_in_bgs
      bgs_representative_type
    else
      representative_type
    end
  end

  def update_vacols_poa!
    appeal.power_of_attorney.update_vacols_rep_info!(
      appeal: appeal,
      representative_type: rep_type,
      representative_name: rep_name,
      address: {
        address_line_1: bgs_rep_address_line_1,
        address_line_2: bgs_rep_address_line_2,
        address_line_3: bgs_rep_address_line_3,
        city: bgs_rep_city,
        state: bgs_rep_state,
        zip: bgs_rep_zip
      }
    )
  end

  def complete!(user_id)
    update_vacols_poa! unless poa_matches || poa_correct_in_vacols
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

  # in order to include certifications created before v2 field was introduced, we have additional 'or' conditions
  # (i.e. bgs_representative_type not nil)
  def self.v2
    where(v2: true).or(where.not(bgs_representative_type: nil))
                   .or(where.not(bgs_representative_name: nil))
                   .or(where.not(vacols_representative_type: nil))
                   .or(where.not(vacols_representative_name: nil))
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

  def can_be_updated?
    Rails.env.development? || Rails.env.demo? || !already_certified
  end

  class << self
    def find_or_create_by_vacols_id(vacols_id)
      find_by_vacols_id(vacols_id) || create!(vacols_id: vacols_id)
    end

    # Return existing certification only if it was not cancelled before
    def find_by_vacols_id(vacols_id)
      Certification.join_cancellations
                   .where(certification_cancellations: { certification_id: nil })
                   .find_by(vacols_id: vacols_id)
    end

    def join_cancellations
      Certification.joins("LEFT OUTER JOIN certification_cancellations ON
        certifications.id = certification_cancellations.certification_id")
    end
  end
end
