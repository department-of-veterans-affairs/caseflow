# frozen_string_literal: true

require "fuzzy_match"

class AttorneySearch
  # only return results scoring at least this fraction of the top score
  RELATIVE_SCORE_THRESHOLD = 0.5

  attr_reader :query_text

  def initialize(query_text)
    @query_text = query_text
  end

  def fetch_attorneys
    candidates_by_name = {}
    first_letter_candidates.each do |atty|
      (candidates_by_name[atty.name] ||= []) << atty
    end
    top_names = top_matched_names(candidates_by_name.keys)
    top_names.map { |name| candidates_by_name[name] }.flatten
  end

  # get all attorneys from PG that have first-letter matches against the query text
  def first_letter_candidates
    return [] if first_letters.empty?

    @first_letter_candidates ||= begin
      regexes = first_letters.map { |ch| "\\m" + ch } # \m is POSIX regex for start-of-word
      where = (["name ~* ?"] * regexes.length).join(" AND ")
      BgsAttorney.where(where, *regexes)
    end
  end

  private

  def first_letters
    @first_letters ||= begin
      query_text.split().map { |word| word[0] }.select { |ch| ch.match(/[a-zA-Z]/) }
    end
  end

  def top_matched_names(haystack)
    return [] if haystack.empty?

    # maps each name in haystack to [name, Dice's coefficient, Levenshtein distance]
    results = FuzzyMatch.new(haystack).find_all_with_score(query_text)
    threshold = results[0][1] * RELATIVE_SCORE_THRESHOLD
    results.select { |res| res[1] >= threshold }.map(&:first)
  end
end
