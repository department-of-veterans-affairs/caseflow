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
    top_matched_names.map { |name| candidates_by_name[name] }.flatten
  end

  # get all attorneys from PG that have first-letter matches against the query text
  def candidates
    return [] if first_letters.empty?

    @candidates ||= begin
      regexes = first_letters.map { |ch| "\\m" + ch } # \m is POSIX regex for start-of-word
      where = (["name ~* ?"] * regexes.length).join(" AND ")
      BgsAttorney.where(where, *regexes)
    end
  end

  private

  def first_letters
    @first_letters ||= begin
      query_text.split.map { |word| word[0] }.select { |ch| ch.match(/[a-zA-Z]/) }
    end
  end

  # return a hash mapping candidate attorney names to a list of attorneys with each name
  def candidates_by_name
    @candidates_by_name ||= begin
      mapping = {}
      candidates.each do |atty|
        (mapping[atty.name] ||= []) << atty
      end
      mapping
    end
  end

  # maps each unique candidate name to [name, Dice's coefficient, Levenshtein distance]
  def fuzzy_matched_results
    FuzzyMatch.new(candidates_by_name.keys).find_all_with_score(query_text)
  end

  def top_matched_names
    return [] if candidates.empty?

    threshold = fuzzy_matched_results[0][1] * RELATIVE_SCORE_THRESHOLD
    fuzzy_matched_results.select { |res| res[1] >= threshold }.map(&:first)
  end
end
