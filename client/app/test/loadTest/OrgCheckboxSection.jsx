/* eslint-disable import/extensions */
/* eslint-disable max-lines, max-len */

import React, { useState } from 'react';
import PropTypes from 'prop-types';
import Checkbox from '../../components/Checkbox';

export default function OrgCheckboxSection(props) {

  const [selectedOrganizations, setSelectedOrganizations] = useState({});

  const allOrganizations = props.form_values.all_organizations;
  const currentState = props.currentState;
  const updateState = props.updateState;

  const handleOrganizationSelect = (org) => {
    setSelectedOrganizations((prev) => {
      const updatedSelections = { ...prev };

      if (updatedSelections[org]) {
        delete updatedSelections[org];
        delete updatedSelections[`${org}-admin`];
      } else {
        updatedSelections[org] = true;
      }
      updateState(
        {
          ...currentState,
          user: {
            ...currentState.user,
            user: {
              ...currentState.user.user,
              organizations: [updatedSelections]
            }
          }
        }
      );

      return updatedSelections;
    });
  };

  const handleAdminChange = (org) => {
    setSelectedOrganizations((prev) => {
      const updatedSelections = { ...prev };

      if (updatedSelections[`${org}-admin`]) {
        delete updatedSelections[`${org}-admin`];
      } else {
        updatedSelections[`${org}-admin`] = true;
      }
      updateState(
        {
          ...currentState,
          user: {
            ...currentState.user,
            user: {
              ...currentState.user.user,
              organizations: updatedSelections
            }
          }
        }
      );

      return updatedSelections;
    });
  };

  return allOrganizations.map((org) => (
    <div className="load-test-container-checkbox test-class-sizing" key={org}>
      <Checkbox
        label={org}
        name={org}
        isChecked={Boolean(selectedOrganizations[org])}
        onChange={() => handleOrganizationSelect(org)}
      />
      {selectedOrganizations[org] && (
        <div style={{ marginLeft: '20px' }}>
          <Checkbox
            label="Admin"
            name={`${org}-admin`}
            isChecked={Boolean(selectedOrganizations[`${org}-admin`])}
            onChange={() => handleAdminChange(org)}
          />
        </div>
      )}
    </div>
  ));
}

OrgCheckboxSection.propTypes = {
  all_organizations: PropTypes.array,
  form_values: PropTypes.object,
  currentState: PropTypes.object,
  updateState: PropTypes.func,
  org: PropTypes.string
};
