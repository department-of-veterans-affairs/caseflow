export const mapPOADataFromApi = (appeal) => {
  const poa = appeal.powerOfAttorney;
  const poaAddress = poa.representative_address;
  debugger;
  console.log(appeal.powerOfAttorney);
  return {
    relationship: 'attorney',
    addressLine1: poaAddress.address_line_1,
    addressLine2: poaAddress.address_line_2,
    addressLine3: poaAddress.address_line_3,
    city: poaAddress.city,
    country: poaAddress.country,
  };
};

export const mapPOADataToApi = (_poa) => {
  debugger;
  return {
    // address is nested object in response, should it not be here?
    unrecognized_power_of_attorney: {
      addressLine1: _poa.address_line_1,
      addressLine2: _poa.address_line_2,
      addressLine3: _poa.address_line_3,
      city: _poa.city,
      country: _poa.country,
      state: _poa.state,
      zip: _poa.zip,
      label: _poa.label,
      value: _poa.value
    }
  };
};
