class Generators::Random
  class << self
    def whitespace(len = 16)
      from_set([" ", "\n", "\r", "\t"], len)
    end

    def word_characters(len = 256)
      set = ("a".."z").to_a.concat(("A".."Z").to_a).concat(("0".."9").to_a).push("_")
      from_set(set, len)
    end

    # Generate a random combination of elements from set between 1 and len characters long.
    def from_set(set, len)
      (Array.new(Random.rand(len) + 1) { set.sample }).join
    end
  end
end
