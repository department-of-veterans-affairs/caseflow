/* eslint-disable max-lines, max-len */

import React, { useState } from 'react';
import PropTypes from 'prop-types';

// import SearchableDropdown from '../../components/SearchableDropdown';
import Checkbox from '../../components/Checkbox';
import { css } from 'glamor';

export default function OrganizationCheckbox(props) {
  const [isChecked, orgIsChecked] = useState(false);
  const [isAdmin, adminIsChecked] = useState(false);

  let orgOption = props.organizationOption;

  // Handles the checking of the Primary checkbox
  const onChangeHandle = () => {
    orgIsChecked(!isChecked);
  };

  // Handles the checking of the Secondary checkbox
  const isAdminHandle = () => {
    adminIsChecked(!isAdmin);
  };

  const subCheckboxStyling = css({
    marginLeft: '20px'
  });

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
      { isChecked && (
        <Checkbox
          name={`${orgOption}-admin`}
          label="Admin"
          onChange={() => {
            isAdminHandle();
          }}
          value={isAdmin}
          styling={subCheckboxStyling}
        />
      )}
    </div>
  );
}

OrganizationCheckbox.propTypes = {
  organizationOption: PropTypes.string
};
