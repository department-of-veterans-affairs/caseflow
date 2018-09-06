class ProperName < String
  delegate :first, to: :split

  delegate :last, to: :split
end
