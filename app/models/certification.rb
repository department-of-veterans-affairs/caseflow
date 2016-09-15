##
# Certification is responsible for aggregating the information
# and providing methods used to assist the certification of an
# appeal. It also acts as a record of appeals that are certified
# using Caseflow.
#
class Certification < ActiveRecord::Base
  def start!
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

  def complete!
    appeal.certify!
    update_attributes!(completed_at: Time.zone.now)
  end

  def appeal
    @appeal ||= Appeal.find(vacols_id)
  end

  def form8(cache_key)
    @form8 ||= saved_form8(cache_key) || Form8.from_appeal(appeal)
  end

  private

  def now
    @now ||= Time.zone.now
  end

  def calculate_form9_matching_at
    appeal.soc_match? ? (soc_matching_at || now) : nil
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

  def saved_form8(cache_key)
    saved = Rails.cache.read(cache_key)

    return nil unless saved && saved["vacols_id"] == vacols_id
    @saved_form8 ||= Form8.from_session(saved)
  rescue
    return nil
  end

  class << self
    def from_vacols_id!(vacols_id)
      find_by(vacols_id: vacols_id) || create!(vacols_id: vacols_id)
    end
  end
end
