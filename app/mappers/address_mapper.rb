module AddressMapper
  def get_address_from_bgs_address(bgs_address)
    return {} unless bgs_address
    {
      address_line_1: bgs_address[:addrs_one_txt],
      address_line_2: bgs_address[:addrs_two_txt],
      address_line_3: bgs_address[:addrs_three_txt],
      city: bgs_address[:city_nm],
      country: bgs_address[:cntry_nm],
      state: bgs_address[:postal_cd],
      zip: bgs_address[:zip_prefix_nbr]
    }
  end

  def get_address_from_corres_entry(corres_entry)
    {
      address_line_1: corres_entry.saddrst1,
      address_line_2: corres_entry.saddrst2,
      city: corres_entry.saddrcty,
      state: corres_entry.saddrstt,
      country: corres_entry.saddrcnty,
      zip_code: corres_entry.saddrzip
    }
  end

  def get_address_from_rep_entry(rep_entry)
    {
      address_line_1: rep_entry.repaddrst1,
      address_line_2: rep_entry.repaddrst2,
      city: rep_entry.repaddrcty,
      state: rep_entry.repaddrstt,
      country: rep_entry.repaddrcnty,
      zip_code: rep_entry.repaddrzip
    }
  end
end
