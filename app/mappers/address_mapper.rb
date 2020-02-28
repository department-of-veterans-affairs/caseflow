# frozen_string_literal: true

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
      zip: bgs_address[:zip_prefix_nbr],
      type: bgs_address[:ptcpnt_addrs_type_nm]
    }
  end

  def get_address_from_corres_entry(corres_entry)
    return {} unless corres_entry

    {
      address_line_1: corres_entry.saddrst1,
      address_line_2: corres_entry.saddrst2,
      city: corres_entry.saddrcty,
      state: corres_entry.saddrstt,
      country: corres_entry.saddrcnty,
      zip: corres_entry.saddrzip
    }
  end

  def get_address_from_rep_entry(rep_entry)
    return {} unless rep_entry

    {
      address_line_1: rep_entry.repaddr1,
      address_line_2: rep_entry.repaddr2,
      city: rep_entry.repcity,
      state: rep_entry.repst,
      zip: rep_entry.repzip
    }
  end
end
