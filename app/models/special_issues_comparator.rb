# frozen_string_literal: true

# class to get special issues from ratings
# built for MST/PACT release

class SpecialIssuesComparator
  def initialize(issue)
    @issue = issue
    @rating_special_issues = issue&.special_issues
  end

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
  CONTENTION_MST_ISSUES = [
    "mst"
  ].freeze


  # returns a hash with mst_available and pact_available values
  # values generated from ratings special issues and contentions
  def special_issues
    # guard for MST/PACT feature toggle
    # commented out for testing
    # return [] unless FeatureToggle.enabled?(:mst_identification, user: RequestStore[:current_user]) ||
    #                  FeatureToggle.enabled?(:pact_identification, user: RequestStore[:current_user])

    [{
      mst_available: mst_from_rating_or_contention,
      pact_available: pact_from_rating_or_contention
    }]
  end

  # check rating for existing mst status; if none, search contentions
  def mst_from_rating_or_contention
    return mst_from_rating? if mst_from_rating?
    return mst_from_contention? if mst_from_contention?

    false
  end

  # check rating for existing pact status; if none, search contentions
  def pact_from_rating_or_contention
    return pact_from_rating? if pact_from_rating?
    return pact_from_contention? if pact_from_contention?

    false
  end

  def mst_from_rating?
    return false if @rating_special_issues.blank?

    @rating_special_issues.each do |special_issue|
      return special_issue_has_mst?(special_issue) if special_issue_has_mst?(special_issue)
    end

    false
  end

  def pact_from_rating?
    return false if @rating_special_issues.blank?

    @rating_special_issues.each do |special_issue|
      return special_issue_has_pact?(special_issue) if special_issue_has_pact?(special_issue)
    end

    false
  end

  def special_issue_has_mst?(special_issue)
    special_issue.transform_keys!(&:to_s)
    if special_issue["spis_tn"]&.casecmp("ptsd - personal trauma")&.zero?
      return MST_SPECIAL_ISSUES.include?(special_issue["spis_basis_tn"]&.downcase)
    end

    if special_issue["spis_tn"]&.casecmp("non-ptsd personal trauma")&.zero?
      MST_SPECIAL_ISSUES.include?(special_issue["spis_basis_tn"]&.downcase)
    end
  end

  def special_issue_has_pact?(special_issue)
    special_issue.transform_keys!(&:to_s)
    if special_issue["spis_tn"]&.casecmp("gulf war presumptive 3.320")&.zero?
      return special_issue.keys(&:to_s)["spis_basis_tn"]&.casecmp("particulate matter")&.zero?
    end

    PACT_SPECIAL_ISSUES.include?(special_issue["spis_tn"]&.downcase)
  end

  # cycle contentions tied to the rating issue/decision and return true if there is a match for mst
  def mst_from_contention?
    return false if contentions_tied_to_issue.blank?

    contentions_tied_to_issue.each do |contention|
      return mst_contention_status?(contention) if mst_contention_status?(contention)
    end

    false
  end

  # cycle contentions tied to the rating issue/decision and return true if there is a match for pact
  def pact_from_contention?
    return false if contentions_tied_to_issue.blank?

    contentions_tied_to_issue.each do |contention|
      return pact_contention_status(contention) if pact_contention_status(contention)
    end

    false
  end

  def mst_contention_status?(bgs_contention)
    bgs_contention.transform_keys!(&:to_s)
    return false if bgs_contention.nil? || bgs_contention["special_issues"].blank?

    if bgs_contention["special_issues"].is_a?(Hash)
      CONTENTION_MST_ISSUES.include?(bgs_contention["special_issues"]["spis_tc"]&.downcase)
    elsif bgs_contention["special_issues"].is_a?(Array)
      bgs_contention["special_issues"].any? { |issue| CONTENTION_MST_ISSUES.include?(issue["spis_tc"]&.downcase) }
    end

    false
  end

  def pact_contention_status?(bgs_contention)
    bgs_contention.transform_keys!(&:to_s)
    return false if bgs_contention.nil? || bgs_contention["special_issues"].blank?

    if bgs_contention["special_issues"].is_a?(Hash)
      CONTENTION_PACT_ISSUES.include?(bgs_contention["special_issues"]["spis_tc"]&.downcase)
    elsif bgs_contention["special_issues"].is_a?(Array)
      bgs_contention["special_issues"].any? { |issue| CONTENTION_PACT_ISSUES.include?(issue["spis_tc"]&.downcase) }
    end

    false
  end

  # get the contentions for the veteran, find the contentions that are tied to the rating issue
  def contentions_tied_to_issue
    @veteran_contentions_from_bgs ||= fetch_contentions_by_participant_id(@issue.participant_id)

    return false if @veteran_contentions.blank?

    @issue.rba_contentions_data.each do |rba|
      rba_contention = rba.with_indifferent_access
      @veteran_contentions.each do |vc|
        next unless vc.is_a?(Hash)

        # if only one contention, check the contention info
        if vc.dig(:contentions).is_a?(Hash)
          # get the single contention from the response
          cntn = vc.dig(:contentions)

          next if cntn.blank?

          # see if the contetion ties to the rating
          contentions_data << cntn if cntn.dig(:cntntn_id) == rba_contention.dig(:cntntn_id)

        # if the response contains an array of contentions, unpack each one and compare
        elsif vc.dig(:contentions).is_a?(Array)

          vc.dig(:contentions).each do |contention|
            next if contention.dig(:cntntn_id).blank?

            contentions_data << contention if contention.dig(:cntntn_id) == rba_contention.dig(:cntntn_id)
          end
        end
      end
    end
    contentions_data.compact
  end

  def fetch_contentions_by_participant_id(participant_id)
    BGSService.new.find_contentions_by_participant_id(participant_id)
  end
end
