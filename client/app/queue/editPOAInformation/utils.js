export const mapPOADataToApi = (_poa) => {
  const returnval = {
    unrecognized_appellant: {
      poa_participant_id: null,
      unrecognized_power_of_attorney: {
        address_line_1: _poa.addressLine1,
        address_line_2: _poa.addressLine2,
        address_line_3: _poa.addressLine3,
        party_type: _poa.partyType,
        name: _poa.firstName,
        city: _poa.city,
        country: _poa.country,
        state: _poa.state,
        zip: _poa.zip
      }
    }
  };

  if (_poa.listedAttorney.value !== 'not_listed') {
    returnval.unrecognized_appellant = {
      poa_participant_id: _poa.listedAttorney.value
    };
  }

  return returnval;
};

export const mapPOADataFromApi = (appeal) => {
  let returnval = {
    relationship: 'attorney'
  };

  if (appeal.hasPOA) {
    const poa = appeal.powerOfAttorney;
    const poaAddress = poa.representative_address;

    returnval = { ...returnval,
      addressLine1: poaAddress.address_line_1,
      addressLine2: poaAddress.address_line_2,
      addressLine3: poaAddress.address_line_3,
      city: poaAddress.city,
      country: poaAddress.country,
      emailAddress: poa.representative_email_address,
      name: poa.representative_name,
      state: poaAddress.state,
      type: poa.representative_type,
      zip: poaAddress.zip,
      zone: poa.representative_tz,
    };
  }

  return returnval;
};

