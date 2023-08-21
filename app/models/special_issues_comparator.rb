# frozen_string_literal: true

# class to get special issues from ratings
# built for MST/PACT release

class SpecialIssuesComparator
  include ActiveModel::Model

  MST_SPECIAL_ISSUES = ["sexual assault trauma", "sexual trauma/assault", "sexual harassment"].freeze
  PACT_SPECIAL_ISSUES = [
    "agent orange - outside vietnam or unknown",
    "agent orange - vietnam",
    "amyotrophic lateral sclerosis (als)",
    "burn pit exposure",
    "environmental hazard in gulf war",
    "gulf war presumptive",
    "radiation"
  ].freeze
  CONTENTION_PACT_ISSUES = [
    "pact",
    "pactdicre",
    "pees1"
  ].freeze


  def get_special_issues(issue)
    binding.pry
  end

  def fetch_contentions_by_participant_id(participant_id)
    BGSService.new.find_contentions_by_participant_id(participant_id)
  end

  def special_issue_has_mst?(special_issue)
    if special_issue[:spis_tn]&.casecmp("ptsd - personal trauma")&.zero?
      return MST_SPECIAL_ISSUES.include?(special_issue[:spis_basis_tn]&.downcase)
    end

    if special_issue[:spis_tn]&.casecmp("non-ptsd personal trauma")&.zero?
      MST_SPECIAL_ISSUES.include?(special_issue[:spis_basis_tn]&.downcase)
    end
  end

  def special_issue_has_pact?(special_issue)
    if special_issue[:spis_tn]&.casecmp("gulf war presumptive 3.320")&.zero?
      return special_issue[:spis_basis_tn]&.casecmp("particulate matter")&.zero?
    end

    PACT_SPECIAL_ISSUES.include?(special_issue[:spis_tn]&.downcase)
  end

  def mst_from_contentions_for_rating?(contentions)
    return false if contentions.blank?

    contentions.any? { |contention| mst_contention_status?(contention) }
  end

  def pact_from_contentions_for_rating?(contentions)
    return false if contentions.blank?

    contentions.any? { |contention| pact_contention_status?(contention) }
  end

  def participant_contentions(serialized_hash)
    # guard for MST/PACT feature toggle
    # commented out for testing
    # return [] unless FeatureToggle.enabled?(:mst_identification, user: RequestStore[:current_user]) ||
    #                  FeatureToggle.enabled?(:pact_identification, user: RequestStore[:current_user])

    contentions_data = []
    response = fetch_contentions_by_participant_id(serialized_hash[:participant_id])

    return if response.blank?

    serialized_hash[:rba_contentions_data].each do |rba|
      rba_contention = rba.with_indifferent_access
      response.each do |resp|
        next unless resp.is_a?(Hash)

        # if only one contention, check the contention info
        if resp.dig(:contentions).is_a?(Hash)
          # get the single contention from the response
          cntn = resp.dig(:contentions)

          next if cntn.blank?

          # see if the contetion ties to the rating
          contentions_data << cntn if cntn.dig(:cntntn_id) == rba_contention.dig(:cntntn_id)

        # if the response contains an array of contentions, unpack each one and compare
        elsif resp.dig(:contentions).is_a?(Array)

          resp.dig(:contentions).each do |contention|
            next if contention.dig(:cntntn_id).blank?

            contentions_data << contention if contention.dig(:cntntn_id) == rba_contention.dig(:cntntn_id)
          end
        end
      end
    end
    contentions_data.compact
  end

  def mst_contention_status?(bgs_contention)
    return false if bgs_contention.nil? || bgs_contention[:special_issues].blank?

    if bgs_contention[:special_issues].is_a?(Hash)
      bgs_contention[:special_issues][:spis_tc] == "MST"
    elsif bgs_contention[:special_issues].is_a?(Array)
      bgs_contention[:special_issues].any? { |issue| issue[:spis_tc] == "MST" }
    end
  end

  def pact_contention_status?(bgs_contention)
    return false if bgs_contention.nil? || bgs_contention[:special_issues].blank?

    if bgs_contention[:special_issues].is_a?(Hash)
      CONTENTION_PACT_ISSUES.include?(bgs_contention[:special_issues][:spis_tc]&.downcase)
    elsif bgs_contention[:special_issues].is_a?(Array)
      bgs_contention[:special_issues].any? { |issue| CONTENTION_PACT_ISSUES.include?(issue[:spis_tc]&.downcase) }
    end
  end
end
