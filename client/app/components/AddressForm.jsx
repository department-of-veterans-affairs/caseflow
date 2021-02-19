import React from 'react';
import PropTypes from 'prop-types';
import styled from 'styled-components';
import { Controller } from 'react-hook-form';
import { STATES } from '../constants/AppConstants';
import TextField from 'app/components/TextField';
import SearchableDropdown from 'app/components/SearchableDropdown';

export const AddressForm = ({ control, register, watch, setValue }) => {
  const watchPartyType = watch('partyType');

  return (
    <React.Fragment>
      <FieldDiv>
        <TextField
          name="address1"
          label="Street address 1"
          inputRef={register}
          strongLabel
        />
      </FieldDiv>
      <FieldDiv>
        <TextField
          name="address2"
          label="Street address 2"
          inputRef={register}
          optional
          strongLabel
        />
      </FieldDiv>
      {watchPartyType === 'organization' && (
        <StreetAddress>
          <TextField
            name="address3"
            label="Street address 3"
            inputRef={register}
            optional
            strongLabel
          />
        </StreetAddress>
      )}
      <CityState>
        <TextField name="city" label="City" inputRef={register} strongLabel />
        <Controller
          control={control}
          name="state"
          render={({ onChange, ...rest }) => (
            <SearchableDropdown
              {...rest}
              label="State"
              options={STATES}
              onChange={(valObj) => {
                onChange(valObj);
                setValue('state', valObj?.label);
              }}
              strongLabel
            />
          )}
        />
      </CityState>
      <ZipCountry>
        <TextField name="zip" label="Zip" inputRef={register} strongLabel />
        <TextField
          name="country"
          label="Country"
          inputRef={register}
          strongLabel
        />
      </ZipCountry>
    </React.Fragment>
  );
};

AddressForm.propTypes = {
  control: PropTypes.func,
  register: PropTypes.func,
  watch: PropTypes.func,
  setValue: PropTypes.func,
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
  margin-bottom: -0.65em;
`;

const StreetAddress = styled.div`
  margin-top: -0.5em;
  margin-bottom: -0.65em;
`;

const FieldDiv = styled.div`
  margin-bottom: 1.5em;
`;

export default AddressForm;
