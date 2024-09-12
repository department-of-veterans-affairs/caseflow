/* eslint-disable max-lines, max-len */

import React, { useState } from 'react';
import PropTypes from 'prop-types';

// import SearchableDropdown from '../../components/SearchableDropdown';
import Checkbox from '../../components/Checkbox';

export default function OrganizationDropdown(props) {
  const [isChecked, orgIsChecked] = useState(false);

  let orgOption = props.organizationOption;

  const onChangeHandle = () => {
    orgIsChecked(!isChecked);
  };

  // const organizations = props.form_values.all_organizations.sort().map((org) => ({
  //   value: org,
  //   label: org
  // }));

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
    </div>
  );
}

OrganizationDropdown.propTypes = {
  organizationOption: PropTypes.string,
  form_values: PropTypes.object,
};
