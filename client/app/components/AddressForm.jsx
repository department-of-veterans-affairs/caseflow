import React from 'react';
import styled from 'styled-components';

import { STATES } from '../constants/AppConstants'
import TextField from 'app/components/TextField';
import SearchableDropdown from 'app/components/SearchableDropdown';

export const AddressForm = () => {

  return (
    <>
      <TextField
        name="Street address 1"
        label="Street address 1"
        strongLabel
      />
      <TextField
        name="Street address 2"
        label="Street address 2"
        optional
        strongLabel
      />
      <StreetAddress>
        <TextField
          name="Street address 3"
          label="Street address 3"
          optional
          strongLabel
        />
      </StreetAddress>
      <CityState>
        <TextField
          name="City"
          label="City"
          strongLabel
        />
        <SearchableDropdown
          name="State"
          label="State"
          options={STATES}
          strongLabel
        />
      </CityState>
      <ZipCountry>
        <TextField
          name="Zip"
          label="Zip"
          strongLabel
        />
        <TextField
          name="Country"
          label="Country"
          strongLabel
        />
      </ZipCountry>
    </>
  );
};

// Styles ----------------------------

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
