/* eslint-disable max-lines, max-len */

import React, { useState } from 'react';
import PropTypes from 'prop-types';

import Checkbox from '../../components/Checkbox';

const RoleConfiguration = (props) => {
  const [checked, setChecked] = useState(false);

  const role = props.role;
  const currentState = props.currentState;
  const updateState = props.updateState;

  const handleRoleSelect = (selectedRole) => {
    const currentRoles = currentState.user.roles;

    if (currentRoles.find((selection) => selection === selectedRole)) {
      currentRoles.splice(currentRoles.indexOf(selectedRole), 1);
      setChecked(false);
    } else {
      currentRoles.push(selectedRole);
      setChecked(true);
    }

    updateState({
      ...currentState,
      user: {
        ...currentState.user,
        roles: currentRoles
      }
    }
    );
  };

  return (
    <div className="load-test-container-checkbox">
      <Checkbox
        label={role}
        name={role}
        onChange={(value) => {
          handleRoleSelect(role, value);
        }}
        isChecked={checked}
      />
    </div>
  );
};

RoleConfiguration.propTypes = {
  role: PropTypes.string,
  currentState: PropTypes.object,
  updateState: PropTypes.func
};

export default RoleConfiguration;
