module AddressMapper
  def get_address_from_bgs_address(bgs_address = {})
    {
      address_line_1: bgs_address[:addrs_one_txt],
      address_line_2: bgs_address[:addrs_two_txt],
      address_line_3: bgs_address[:addrs_three_txt],
      city: bgs_address[:city_nm],
      country: bgs_address[:cntry_nm],
      # is this an odd name for state?
      state: bgs_address[:postal_cd],
      zip: bgs_address[:zip_prefix_nbr]
    }
  end
end
