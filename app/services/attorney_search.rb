# frozen_string_literal: true

require "fuzzy_match"

class AttorneySearch
  attr_accessor :first_letters
  attr_reader :query_text

  def initialize(query_text)
    @query_text = query_text
  end

  def fetch_attorneys
    return [] if first_letters.empty?

    candidates_by_name = {}
    first_letter_candidates.each do |atty|
      (candidates_by_name[atty.name] ||= []) << atty
    end
    top_names = top_matched_names(candidates_by_name.keys)
    top_names.map { |name| candidates_by_name[name] }.flatten
  end

  private

  def first_letters
    @first_letters ||= begin
      query_text.split().map { |word| word[0] }.select { |ch| ch.match(/[a-zA-Z]/) }
    end
  end

  # get all attorneys from PG that have first-letter matches against the query text
  def first_letter_candidates
    @first_letter_candidates ||= begin
      regexes = first_letters.map { |ch| "\\m" + ch } # \m is POSIX regex for start-of-word
      where = (["name ~* ?"] * regexes.length).join(" AND ")
      BgsAttorney.where(where, *regexes)
    end
  end

  def top_matched_names(haystack)
    return [] if haystack.empty?

    # maps each name in haystack to [name, Dice's coefficient, Levenshtein distance]
    results = FuzzyMatch.new(haystack).find_all_with_score(query_text)
    results.select { |res| res[1] >= results[0][1] * 0.5 }.map(&:first)
  end
end
