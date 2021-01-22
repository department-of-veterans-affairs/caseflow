import React from 'react';
import PropTypes from 'prop-types';
import styled from 'styled-components';
import { css } from 'glamor';

import { STATES } from '../constants/AppConstants';
import TextField from 'app/components/TextField';
import SearchableDropdown from 'app/components/SearchableDropdown';

export const AddressForm = ({ organization }) => {

  return (
    <>
      <FieldDiv>
        <TextField
          name="address1"
          label="Street address 1"
          strongLabel
        />
      </FieldDiv>
      <FieldDiv>
        <TextField
          name="address2"
          label="Street address 2"
          optional
          strongLabel
        />
      </FieldDiv>
      {
        organization && <StreetAddress>
          <TextField
            name="Street address 3"
            label="Street address 3"
            optional
            strongLabel
          />
        </StreetAddress>
      }
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

AddressForm.propTypes = {
  organization: PropTypes.bool
};

const CityState = styled.div`
  display: grid;
  grid-gap: 10px;
  grid-template-columns: 320px 130px;
  margin-bottom: 0em;
  margin-top: -1em;
  align-items: center;
  input {
    margin-bottom: 0;
  }
`;

const ZipCountry = styled.div`
  display: grid;
  grid-gap: 10px;
  grid-template-columns: 140px 310px;
  margin-bottom: -.65em;
`;

const StreetAddress = styled.div`
  margin-top: -.5em;
  margin-bottom: -.65em;
`;

const FieldDiv = styled.div`
  margin-bottom: 1.5em;
`;

export default AddressForm;
