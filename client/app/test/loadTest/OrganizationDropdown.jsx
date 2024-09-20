/* eslint-disable max-lines, max-len */

import React, { useState } from 'react';
import PropTypes from 'prop-types';

import SearchableDropdown from '../../components/SearchableDropdown';

export default function OrganizationDropdown(props) {
  const [orgSelection, setOrgSelection] = useState('');

  const handleOrgSelection = ({ value }) => {
    setOrgSelection(value);
  };

  const organizations = props.form_values.all_organizations.sort().map((org) => ({
    value: org,
    label: org
  }));

  return (
    <div>
      <SearchableDropdown
        name="Organizations dropdown"
        hideLabel
        onChange={handleOrgSelection}
        options={organizations} searchable
        filterOption={() => true}
        value={orgSelection}
      />
    </div>
  );
}

OrganizationDropdown.propTypes = {
  all_organizations: PropTypes.array,
  form_values: PropTypes.object,
};
