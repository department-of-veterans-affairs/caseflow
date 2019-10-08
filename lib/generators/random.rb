# frozen_string_literal: true

class Generators::Random
  @unique_ssns = {}

  class << self
    def whitespace(len = 16)
      from_set([" ", "\n", "\r", "\t"], len)
    end

    def word_characters(len = 256)
      set = ("a".."z").to_a.concat(("A".."Z").to_a).concat(("0".."9").to_a).push("_")
      from_set(set, len)
    end

    def special_characters(len = 16)
      set = (" ".."/").to_a + (":".."@").to_a + ("[".."`").to_a + ("{".."~").to_a
      from_set(set, len)
    end

    # Generate a random combination of elements from set between 1 and len characters long.
    def from_set(set, len)
      (Array.new(Random.rand(len) + 1) { set.sample }).join
    end

    def ssn
      100_000_000 + SecureRandom.random_number(899_999_999)
    end

    def unique_ssn
      my_ssn = ssn.to_s
      return unique_ssn if @unique_ssns[my_ssn]

      @unique_ssns[my_ssn] = 1
      my_ssn
    end

    def external_id
      Random.rand(1_000_000).to_s
    end
  end
end
