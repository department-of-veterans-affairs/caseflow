class Fakes::Vets360Service < ExternalApi::Vets360Service

  def self.geocode(address)
    [0.0,0.0]
  end

end
