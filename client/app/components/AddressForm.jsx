import React, { useMemo } from 'react';
import PropTypes from 'prop-types';
import styled from 'styled-components';
import { Controller } from 'react-hook-form';
import { STATES } from '../constants/AppConstants';
import TextField from 'app/components/TextField';
import SearchableDropdown from 'app/components/SearchableDropdown';
import { createFilter } from 'react-select';

export const AddressForm = ({ control, register, watch, isOrgPartyType, isIndividualPartyType, isHLROrSCForm }) => {
  const watchState = watch('state');
  const defaultState = useMemo(
    () => STATES.find((state) => state.label === watchState),
    [STATES, watchState]
  );

  const optionalIndividualHLROrSCField = Boolean(isIndividualPartyType && isHLROrSCForm);

  return (
    <React.Fragment>
      <FieldDiv>
        <TextField
          name="addressLine1"
          label="Street address 1"
          inputRef={register}
          optional={optionalIndividualHLROrSCField}
          strongLabel
        />
      </FieldDiv>
      <FieldDiv>
        <TextField
          name="addressLine2"
          label="Street address 2"
          inputRef={register}
          optional
          strongLabel
        />
      </FieldDiv>
      {isOrgPartyType && (
        <StreetAddress>
          <TextField
            name="addressLine3"
            label="Street address 3"
            inputRef={register}
            optional
            strongLabel
          />
        </StreetAddress>
      )}
      <CityState>
        <TextField name="city" label="City" inputRef={register} strongLabel optional={optionalIndividualHLROrSCField} />
        <Controller
          control={control}
          name="state"
          render={({ onChange, ref, ...rest }) => (
            <SearchableDropdown
              inputRef={ref}
              {...rest}
              label="State"
              optional={!isHLROrSCForm || optionalIndividualHLROrSCField}
              options={STATES}
              filterOption={createFilter({ matchFrom: 'start' })}
              onChange={(valObj) => onChange(valObj?.value)}
              defaultValue={defaultState}
              strongLabel
              isClearable
            />
          )}
        />
      </CityState>
      <ZipCountry>
        <TextField
          name="zip"
          label="Zip"
          inputRef={register}
          optional
          strongLabel
        />
        <TextField
          name="country"
          label="Country"
          optional={optionalIndividualHLROrSCField}
          inputRef={register}
          strongLabel
        />
      </ZipCountry>
    </React.Fragment>
  );
};

AddressForm.propTypes = {
  control: PropTypes.object,
  register: PropTypes.func,
  watch: PropTypes.func,
  isOrgPartyType: PropTypes.bool,
  isIndividualPartyType: PropTypes.bool,
  isHLROrSCForm: PropTypes.bool
};

const CityState = styled.div`
  display: grid;
  grid-gap: 10px;
  grid-template-columns: 300px 150px;
  margin-bottom: 1em;
  margin-top: -0.75em;
  align-items: center;
  input {
    margin-bottom: 0;
  }
`;

const ZipCountry = styled.div`
  display: grid;
  grid-gap: 10px;
  grid-template-columns: 140px 310px;
  margin-bottom: -0.75em;
`;

const StreetAddress = styled.div`
  margin-top: -0.5em;
  margin-bottom: 1.75em;
`;

const FieldDiv = styled.div`
  margin-bottom: 1.5em;
`;

export default AddressForm;
