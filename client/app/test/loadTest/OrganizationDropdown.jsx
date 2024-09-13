/* eslint-disable max-lines, max-len */

import React, { useState } from 'react';
import PropTypes from 'prop-types';

// import SearchableDropdown from '../../components/SearchableDropdown';
import Checkbox from '../../components/Checkbox';

export default function OrganizationDropdown(props) {
  const [isChecked, orgIsChecked] = useState(false);
  const [isAdmin, adminIsChecked] = useState(false);

  let orgOption = props.organizationOption;

  const onChangeHandle = () => {
    orgIsChecked(!isChecked);
  };

  const isAdminHandle = () => {
    adminIsChecked(!isAdmin);
  }

  return (
    <div className="load-test-container-checkbox">
      <Checkbox
        name={orgOption}
        label={orgOption}
        onChange={() => {
          onChangeHandle();
        }}
        value={isChecked}
      />
      { isChecked &&
        <Checkbox
          name="Admin?"
          label="Admin?"
          onChange={() => {
            isAdminHandle();
          }}
          value={isAdmin}
        /> }
    </div>
  );
}

OrganizationDropdown.propTypes = {
  organizationOption: PropTypes.string,
  form_values: PropTypes.object,
};
