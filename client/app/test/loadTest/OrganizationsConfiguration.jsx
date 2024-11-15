/* eslint-disable import/extensions */
/* eslint-disable max-lines, max-len */

import React, { useState } from 'react';
import PropTypes from 'prop-types';
import Checkbox from '../../components/Checkbox';

export default function OrganizationsConfiguration(props) {
  const [organizationChecked, setOrganizationChecked] = useState(false);
  const [adminChecked, setAdminChecked] = useState(false);

  const org = props.org;
  const currentState = props.currentState;
  const updateState = props.updateState;
  const orgArray = currentState.user.organizations.map((selection) =>
    selection.url
  );

  const handleOrganizationSelect = (selectedOrganization) => {
    const currentOrgs = currentState.user.organizations;

    if (orgArray.find((selection) => selection === selectedOrganization)) {
      currentOrgs.splice(orgArray.indexOf(selectedOrganization), 1);
      setOrganizationChecked(false);
    } else {
      currentOrgs.push({ url: selectedOrganization, admin: false });
      setOrganizationChecked(true);
    }

    updateState(
      {
        ...currentState,
        user: {
          ...currentState.user,
          organizations: currentOrgs
        }
      }
    );
  };

  const handleAdminChange = (associatedOrg) => {
    let currentOrgs = currentState.user.organizations;

    if (adminChecked === false) {
      currentOrgs[orgArray.indexOf(associatedOrg)].admin = true;
    } else {
      currentOrgs[orgArray.indexOf(associatedOrg)].admin = false;
    }

    setAdminChecked(!adminChecked);

    updateState(
      {
        ...currentState,
        user: {
          ...currentState.user,
          organizations: currentOrgs
        }
      }
    );
  };

  return (
    <div className="load-test-container-checkbox test-class-sizing">
      <Checkbox
        label={org}
        name={org}
        isChecked={organizationChecked}
        onChange={() => handleOrganizationSelect(org)}
      />
      {organizationChecked &&
      (<div style={{ marginLeft: '20px' }}>
        <Checkbox
          label="Admin"
          name={`${org} admin`}
          isChecked={adminChecked}
          onChange={() => handleAdminChange(org)}
        />
      </div>
      )}
    </div>
  );
}

OrganizationsConfiguration.propTypes = {
  currentState: PropTypes.object,
  updateState: PropTypes.func,
  org: PropTypes.string
};
