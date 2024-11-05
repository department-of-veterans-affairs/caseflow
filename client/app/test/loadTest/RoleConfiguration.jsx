/* eslint-disable max-lines, max-len */

import React from 'react';
import PropTypes from 'prop-types';

import Checkbox from '../../components/Checkbox';

const RoleConfiguration = ({ role, currentState, updateState }) => {
  const handleRoleSelect = (selectedRole, value) => {
    const currentRoles = currentState.user.user.roles;
    let roleObjCopy = {};

    if (value) {
      const updatedRoles = {
        ...currentRoles,
        [selectedRole]: value
      };

      roleObjCopy = updatedRoles;
    } else {
      // eslint-disable-next-line no-unused-vars
      const { [selectedRole]: removedValue, ...updatedRoles } = currentRoles;

      roleObjCopy = updatedRoles;
    }

    updateState({
      ...currentState,
      user: {
        ...currentState.user,
        user: {
          ...currentState.user.user,
          roles: roleObjCopy
        }
      }
    });
  };

  return (
    <div className="load-test-container-checkbox">
      <Checkbox
        label={role}
        name={role}
        onChange={(value) => {
          handleRoleSelect(role, value);
        }}
        isChecked={Boolean(currentState.user.user.feature_toggles[role] ?? false)}
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
