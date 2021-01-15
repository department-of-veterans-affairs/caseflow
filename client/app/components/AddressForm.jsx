import React from 'react';
import PropTypes from 'prop-types';

import {STATES} from '../constants/AppConstants'
import RadioField from 'app/components/RadioField';
import TextField from 'app/components/TextField';
import SearchableDropdown from 'app/components/SearchableDropdown';

export const AddressForm = () => {

  return (
    <form>
      <br />
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
      <TextField
        name="Street address 3"
        label="Street address 3"
        optional
        strongLabel
      />
      <div className="cf-progress-bar">
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
      </div>
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
    </form>
  );
};

export default AddressForm;
