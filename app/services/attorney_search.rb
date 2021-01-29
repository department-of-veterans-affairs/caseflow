# frozen_string_literal: true

class AttorneySearch
  # only return results scoring at least this fraction of the top score
  RELATIVE_SCORE_THRESHOLD = 0.5

  attr_reader :query_text

  class << self
    # multiplier for near or exact matches, ramp up from 1x (no bonus) to 1.5x (max bonus)
    def similarity_multiplier(one, two)
      lev = FuzzyMatch.score_class.new(one, two).levenshtein_similar
      (lev < 0.75) ? 1 : (lev * 2 - 0.5)
    end
  end

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

  def fuzzy_matched_results
    @fuzzy_matched_results ||= begin
      # find_all_with_score maps each name to [name, Dice's coefficient, Levenshtein distance]
      results = FuzzyMatch.new(candidates_by_name.keys).find_all_with_score(query_text)
      query_words = query_text.split
      results.each do |result|
        result[0].split.product(query_words).each do |pair|
          result[1] *= self.class.similarity_multiplier(*pair)
        end
      end
      results.sort_by { |result| -result[1] }
    end
  end

  def top_matched_names
    return [] if candidates.empty?

    threshold = fuzzy_matched_results[0][1] * RELATIVE_SCORE_THRESHOLD
    fuzzy_matched_results.select { |res| res[1] >= threshold }.map(&:first)
  end
end
