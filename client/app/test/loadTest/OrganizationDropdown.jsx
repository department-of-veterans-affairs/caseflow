/* eslint-disable max-lines, max-len */

import React, { useState } from 'react';
import PropTypes from 'prop-types';

// import SearchableDropdown from '../../components/SearchableDropdown';
import Checkbox from '../../components/Checkbox';

export default function OrganizationDropdown(props) {
  const [isChecked, orgIsChecked] = useState(false);

  let orgOption = props.orgOption;

  const onChangeHandle = () => {
    orgIsChecked(!isChecked);
  };

  // const organizations = props.form_values.all_organizations.sort().map((org) => ({
  //   value: org,
  //   label: org
  // }));

  return (
    <div>
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
  orgOption: PropTypes.string,
  form_values: PropTypes.object,
};
