# frozen_string_literal: true

# class to get special issues from ratings
# built for MST/PACT release

class SpecialIssuesComparator

  attr_accessor :issue, :rating_special_issues, :bgs_client, :veteran_contentions, :linked_contentions
  def initialize(issue)
    @issue = issue
    @rating_special_issues = issue&.special_issues
    @bgs_client = BGSService.new
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
    return true if mst_from_rating?
    return true if mst_from_contention?

    false
  end

  # check rating for existing pact status; if none, search contentions
  def pact_from_rating_or_contention
    return true if pact_from_rating?
    return true if pact_from_contention?

    false
  end

  # cycles rating special issues and returns if a special issue is MST
  def mst_from_rating?
    return false if rating_special_issues.blank?

    rating_special_issues.each do |special_issue|
      return true if special_issue_has_mst?(special_issue)
    end

    false
  end

    # cycles rating special issues and returns if a special issue is PACT
  def pact_from_rating?
    return false if rating_special_issues.blank?

    rating_special_issues.each do |special_issue|
      return true if special_issue_has_pact?(special_issue)
    end

    false
  end

  # checks if rating special issue meets MST criteria
  def special_issue_has_mst?(special_issue)
    special_issue.transform_keys!(&:to_s)
    if special_issue["spis_tn"]&.casecmp("ptsd - personal trauma")&.zero?
      return MST_SPECIAL_ISSUES.include?(special_issue["spis_basis_tn"]&.downcase)
    end

    if special_issue["spis_tn"]&.casecmp("non-ptsd personal trauma")&.zero?
      MST_SPECIAL_ISSUES.include?(special_issue["spis_basis_tn"]&.downcase)
    end
  end

  # checks if rating special issue meets PACT criteria
  def special_issue_has_pact?(special_issue)
    special_issue.transform_keys!(&:to_s)
    if special_issue["spis_tn"]&.casecmp("gulf war presumptive 3.320")&.zero?
      return special_issue.keys(&:to_s)["spis_basis_tn"]&.casecmp("particulate matter")&.zero?
    end

    PACT_SPECIAL_ISSUES.include?(special_issue["spis_tn"]&.downcase)
  end

  # cycle contentions tied to the rating issue/decision and return true if there is a match for mst
  def mst_from_contention?
    self.linked_contentions ||= contentions_tied_to_issue
    return false if linked_contentions.blank?

    linked_contentions.each do |contention|
      return true if mst_contention_status?(contention)
    end

    false
  end

  # cycle contentions tied to the rating issue/decision and return true if there is a match for pact
  def pact_from_contention?
    self.linked_contentions ||= contentions_tied_to_issue
    return false if linked_contentions.blank?

    linked_contentions.each do |contention|
      return true if pact_contention_status?(contention)
    end

    false
  end

  # checks single contention special issue status for MST
  def mst_contention_status?(bgs_contention)
    bgs_contention.transform_keys!(&:to_s)
    return false if bgs_contention.nil? || bgs_contention["special_issues"].blank?

    if bgs_contention["special_issues"].is_a?(Hash)
      CONTENTION_MST_ISSUES.include?(bgs_contention["special_issues"][:spis_tc]&.downcase)
    elsif bgs_contention["special_issues"].is_a?(Array)
      bgs_contention["special_issues"].any? { |issue| CONTENTION_MST_ISSUES.include?(issue[:spis_tc]&.downcase) }
    end
  end

  # checks single contention special issue status for PACT
  def pact_contention_status?(bgs_contention)
    bgs_contention.transform_keys!(&:to_s)
    return false if bgs_contention.nil? || bgs_contention["special_issues"].blank?

    if bgs_contention["special_issues"].is_a?(Hash)
      CONTENTION_PACT_ISSUES.include?(bgs_contention["special_issues"][:spis_tc]&.downcase)
    elsif bgs_contention["special_issues"].is_a?(Array)
      bgs_contention["special_issues"].any? { |issue| CONTENTION_PACT_ISSUES.include?(issue[:spis_tc]&.downcase) }
    end
  end

  # get the contentions for the veteran, find the contentions that are tied to the rating issue
  def contentions_tied_to_issue
    # establish veteran contentions
    self.veteran_contentions ||= fetch_contentions_by_participant_id(issue.participant_id)

    return nil if veteran_contentions.blank?

    match_ratings_with_contentions
  end

  def fetch_contentions_by_participant_id(participant_id)
    bgs_client.find_contentions_by_participant_id(participant_id)
  end

  # cycles list of rba_contentions on the rating issue and matches them with
  # contentions tied to the veteran
  def match_ratings_with_contentions
    contention_matches = []

    return [] if issue.rba_contentions_data.blank?

    # cycle contentions tied to rating issue
    issue.rba_contentions_data.each do |rba|
      # grab contention on the rating
      rba_contention = rba.with_indifferent_access
      # cycle through the list of contentions from the BGS call (all contentions tied to veteran)
      veteran_contentions.each do |contention|
        next unless contention.is_a?(Hash)

        # store any matches that are found
        link_contention_to_rating(contention, rba_contention, contention_matches)
      end
    end
    contention_matches&.compact
  end

  # takes the contention given and tries to match it to the current rating issue (issue)
  def link_contention_to_rating(contention, rba_contention, contention_matches)
    # if only one contention, check the contention info
    if contention.dig(:contentions).is_a?(Hash)
      # get the single contention from the response
      single_contention_info = contention.dig(:contentions)

      return if single_contention_info.blank?

      # see if the contention ties to the rating. if it does, add it to the matches list
      contention_matches << single_contention_info if single_contention_info.dig(:cntntn_id) == rba_contention.dig(:cntntn_id)

    # if the response contains an array of contentions, unpack each one and compare
    elsif contention.dig(:contentions).is_a?(Array)

      # cycle the contentions within the array to make the comparison to the rba_contention
      contention.dig(:contentions).each do |contention_info|
        next if contention_info.dig(:cntntn_id).blank?

        # see if the contention ties to the rating. if it does, add it to the matches list
        contention_matches << contention_info if contention_info.dig(:cntntn_id) == rba_contention.dig(:cntntn_id)
      end
    end
    contention_matches
  end
end
