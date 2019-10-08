# frozen_string_literal: true

# An EP modifier is a BGS requirement - it helps delineate EPs with the same claim_type_code
# from one another. e.g. if you have multiple HLRs.
class EndProductModifierFinder
  CORRECTION_END_PRODUCT_MODIFIERS = %w[930 931 932 933 934 935 936 937 938 939].freeze

  class NoAvailableModifiers < StandardError; end

  def initialize(end_product_establishment, veteran)
    @end_product_establishment = end_product_establishment
    @veteran = veteran
  end

  attr_reader :end_product_establishment, :veteran

  def find
    return valid_modifiers.first if valid_modifiers.count == 1

    valid_modifiers.each do |modifier|
      if !(taken_modifiers + invalid_modifiers).include?(modifier)
        return modifier
      end
    end

    fail NoAvailableModifiers
  end

  private

  # In decision reviews, we may create 2 end products at the same time. To avoid using
  # the same modifier, we add used modifiers to the invalid_modifiers array.
  def invalid_modifiers
    @invalid_modifiers = end_product_establishment_source.invalid_modifiers
  end

  def valid_modifiers
    @valid_modifiers ||= if correction_end_product?
                           CORRECTION_END_PRODUCT_MODIFIERS
                         else
                           end_product_establishment_source.valid_modifiers
                         end
  end

  def end_product_establishment_source
    @end_product_establishment_source ||= end_product_establishment.source
  end

  def taken_modifiers
    @taken_modifiers ||= veteran.end_products.select { |ep| ep.active? || ep.recent? }.map(&:modifier)
  end

  def correction_end_product?
    end_product_establishment.code =~ /^930/
  end
end
