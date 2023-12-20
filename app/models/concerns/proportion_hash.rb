# frozen_string_literal: true

# Extends a Hash where the values are intended to represent parts of a whole.
#
# {
#   a: 0.5,
#   b: 0.25,
#   c: 0.25
# }.extend(ProportionHash)
#

module ProportionHash
  def normalize!(to: 1.0)
    return self if all_zero?

    total = values.sum
    transform_values! { |proportion| proportion * (to / total) }
  end

  def all_zero?
    all? { |_, proportion| proportion == 0 }
  end

  # Set one or more proportions to the fixed values, normalizing the remainder
  # among the other proportions, proportionate to their prior values.

  def add_fixed_proportions!(fixed)
    except!(*fixed.keys)
      .normalize!(to: 1.0 - fixed.values.sum)
      .merge!(fixed)
  end

  # Translate the ProportionHash into a Hash where the values are Integers, roughly
  # equal to num * proportion. Any remainders are distributed stochastically, so for
  #
  # {
  #   a: 0.5,
  #   b: 0.25,
  #   c: 0.25
  # }.extend(ProportionHash).stochastic_allocation(3)
  #
  # :a will definitely receieve at least 1 (because 0.5 * 3 = 1.5, greater than 1). Each
  # of the remaining 2 units has a 25% chance or (0.5 * 3 % 1) / 2 of being given to :a
  # and a 37.5% or (0.25 * 3 % 1) / 2 chance of being given to each of :b or :c.
  #
  # {
  #   a: 2,
  #   b: 0,
  #   c: 1
  # }
  #
  # The sum of the values will always equal num, and with multiple repetitions, the
  # cumulative sums should approximate the given proportions.

  def stochastic_allocation(num)
    result = transform_values { |proportion| (num * proportion).floor }
    rem = num - result.values.sum

    return result if rem == 0

    cumulative_probabilities = inject({}) do |hash, (key, proportion)|
      probability = (num * proportion).modulo(1) / rem
      hash[key] = (hash.values.last || 0) + probability
      hash
    end

    rem.times do
      random = rand
      pick = cumulative_probabilities.find { |_, cumprob| cumprob > random }
      key = pick ? pick[0] : cumulative_probabilities.keys.last
      result[key] += 1
    end

    result
  end
end
