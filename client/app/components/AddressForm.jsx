import React from 'react';
import styled from 'styled-components';

import { STATES } from '../constants/AppConstants'
import TextField from 'app/components/TextField';
import SearchableDropdown from 'app/components/SearchableDropdown';

export const AddressForm = () => {

  return (
    <>
      <TextField
        name="address1"
        label="Street address 1"
        strongLabel
      />
      <TextField
        name="address2"
        label="Street address 2"
        optional
        strongLabel
      />
      <StreetAddress>
        <TextField
          name="address3"
          label="Street address 3"
          optional
          strongLabel
        />
      </StreetAddress>
      <CityState>
        <TextField
          name="city"
          label="City"
          strongLabel
        />
        <SearchableDropdown
          name="state"
          label="State"
          options={STATES}
          strongLabel
        />
      </CityState>
      <ZipCountry>
        <TextField
          name="zip"
          label="Zip"
          strongLabel
        />
        <TextField
          name="country"
          label="Country"
          strongLabel
        />
      </ZipCountry>
    </>
  );
};


const CityState = styled.div`
  display: grid;
  grid-gap: 10px;
  grid-template-columns: 320px 130px;
  margin-bottom: 1em;
  align-items: center;
  input {
    margin-bottom: 0;
  }
`;

const ZipCountry = styled.div`
  display: grid;
  grid-gap: 10px;
  grid-template-columns: 140px 310px;
`;

const StreetAddress = styled.div`
  margin-bottom:0;
`;

export default AddressForm;
