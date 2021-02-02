import React from 'react';
import { css } from 'glamor';
import PropTypes from 'prop-types';
import { Controller } from 'react-hook-form';

import { STATES } from '../constants/AppConstants';

import TextField from 'app/components/TextField';
import SearchableDropdown from 'app/components/SearchableDropdown';

const city = css({
  marginBottom: '0px'
});

const cityState = css({
  display: 'grid',
  gridGap: '10px',
  gridTemplateColumns: '320px 130px',
  marginBottom: '0em',
  alignItems: 'center',
});

const field = css({
  marginBottom: '1.5em'
});

const address2 = css({
  marginBottom: '0em'
});

const zipCountry = css({
  display: 'grid',
  gridGap: '10px',
  gridTemplateColumns: '140px 310px',
});

export const AddressForm = ({ control, register, watch }) => {
  const watchPartyType = watch('partyType');

  return (
    <React.Fragment>
      <TextField
        name="address1"
        label="Street address 1"
        inputRef={register}
        strongLabel
        inputStyling={field}
      />
      <TextField
        name="address2"
        label="Street address 2"
        inputRef={register}
        optional
        strongLabel
        inputStyling={address2}
      />
      {
        watchPartyType === 'organization' &&
          <TextField
            name="address3"
            label="Street address 3"
            inputRef={register}
            optional
            strongLabel
          />
      }
      <div {...cityState}>
        <TextField
          name="city"
          label="City"
          inputRef={register}
          strongLabel
          inputStyling={city}
        />
        <Controller
          control={control}
          name="state"
          label="State"
          options={STATES}
          strongLabel
          as={SearchableDropdown}
        />
      </div>
      <div {...zipCountry}>
        <TextField
          name="zip"
          label="Zip"
          inputRef={register}
          strongLabel
        />
        <TextField
          name="country"
          label="Country"
          inputRef={register}
          strongLabel
        />
      </div>
    </React.Fragment>
  );
};

AddressForm.propTypes = {
  control: PropTypes.object,
  register: PropTypes.func,
  watch: PropTypes.func,
};

export default AddressForm;
