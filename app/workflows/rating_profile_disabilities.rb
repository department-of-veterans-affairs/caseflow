# frozen_string_literal: true

# thin layer on top of a BGS rating profile disabilities array

# the initializer transforms a disabilities array to a map with dis_sn keys
#
# example:
#
#  given:
#   [
#     { dis_sn: 1, dis_dt: 9 days ago, ... },
#     { dis_sn: 2, dis_dt: 26 days ago, ... },
#     { dis_sn: 3, dis_dt: 55 days ago, ... },
#     { dis_sn: 1, dis_dt: 12 days ago, ... },
#     { dis_sn: 1, dis_dt: 4 days ago, ... },
#     { dis_sn: 3, dis_dt: 60 days ago, ... },
#   ]
#
#  self will be a hash:
#   {
#     1 => [
#       { dis_sn: 1, dis_dt: 9 days ago, ... },
#       { dis_sn: 1, dis_dt: 12 days ago, ... },
#       { dis_sn: 1, dis_dt: 4 days ago, ... }
#     ],
#     2 => [
#       { dis_sn: 2, dis_dt: 26 days ago, ... }
#     ],
#     3 => [
#       { dis_sn: 3, dis_dt: 55 days ago, ... },
#       { dis_sn: 3, dis_dt: 60 days ago, ... }
#     ]
#   }

class RatingProfileDisabilities < SimpleDelegator
  class << self
    def map_disabilities_by_dis_sn(disabilities)
      disabilities.each_with_object({}) do |disability, map|
        dis_sn = disability[:dis_sn]
        map[dis_sn] = [] unless map[dis_sn]
        map[dis_sn] << disability
      end
    end
  end

  def initialize(disabilities)
    super(
      self.class.map_disabilities_by_dis_sn(
        disabilities.map { |hash| RatingProfileDisability.new(hash) }
      )
    )
  end

  #  takes self:
  #   {
  #     1 => [
  #       { dis_sn: 1, dis_dt: 9 days ago, ... },
  #       { dis_sn: 1, dis_dt: 12 days ago, ... },
  #       { dis_sn: 1, dis_dt: 4 days ago, ... }
  #     ],
  #     2 => [
  #       { dis_sn: 2, dis_dt: 26 days ago, ... }
  #     ],
  #     3 => [
  #       { dis_sn: 3, dis_dt: 55 days ago, ... },
  #       { dis_sn: 3, dis_dt: 60 days ago, ... }
  #     ]
  #   }
  #
  #  and returns the most recent disability for each dis_sn:
  #   {
  #     1 => { dis_sn: 1, dis_dt: 4 days ago, ... },
  #     2 => { dis_sn: 2, dis_dt: 26 days ago, ... },
  #     3 => { dis_sn: 3, dis_dt: 55 days ago, ... }
  #   }
  def most_recent
    reduce({}) do |acc, (dis_sn, disabilities)|
      acc.merge(dis_sn => disabilities.max_by { |disability| disability[:dis_dt] || Time.zone.local(0) })
    end
  end
end
