import React, { useMemo } from 'react';
import PropTypes from 'prop-types';
import styled from 'styled-components';
import { Controller } from 'react-hook-form';
import { STATES } from '../constants/AppConstants';
import TextField from 'app/components/TextField';
import SearchableDropdown from 'app/components/SearchableDropdown';
import { createFilter } from 'react-select';

export const AddressForm = ({ control, register, watch }) => {
  const watchPartyType = watch('partyType');
  const watchState = watch('state');
  const defaultState = useMemo(
    () => STATES.find((state) => state.label === watchState),
    [STATES, watchState]
  );

  return (
    <React.Fragment>
      <FormField
        name="addressLine1"
        label="Street address 1"
        inputRef={register}
        strongLabel
      />
      <FormField
        name="addressLine2"
        label="Street address 2"
        inputRef={register}
        optional
        strongLabel
      />
      {watchPartyType === 'organization' && (
        <FormField
          name="addressLine3"
          label="Street address 3"
          inputRef={register}
          optional
          strongLabel
        />
      )}
      <CityState>
        <FormField name="city" label="City" inputRef={register} strongLabel />
        <StateDropdown>
          <Controller
            control={control}
            name="state"
            render={({ onChange, ...rest }) => (
              <SearchableDropdown
                {...rest}
                label="State"
                options={STATES}
                filterOption={createFilter({ matchFrom: 'start' })}
                onChange={(valObj) => onChange(valObj?.value)}
                defaultValue={defaultState}
                strongLabel
                isClearable
              />
            )}
          />
        </StateDropdown>
      </CityState>
      <ZipCountry>
        <FormField
          name="zip"
          label="Zip"
          inputRef={register}
          optional
          strongLabel
        />
        <FormField
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
  control: PropTypes.object,
  register: PropTypes.func,
  watch: PropTypes.func,
  setValue: PropTypes.func,
};

const CityState = styled.div`
  display: grid;
  grid-gap: 15px;
  grid-template-columns: 300px 1fr;
  align-items: end;
`;

const FormField = styled(TextField)`
  max-width: 51rem;
  margin-bottom: 1em;
`;

const StateDropdown = styled.div`
  margin-bottom: 2em;
`;

const ZipCountry = styled.div`
  display: grid;
  grid-gap: 15px;
  grid-template-columns: 140px 1fr;
`;

export default AddressForm;
