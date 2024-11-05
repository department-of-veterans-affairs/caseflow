import React, { useState } from 'react';
import Checkbox from '../components/Checkbox';
import PropTypes from 'prop-types';
import ApiUtil from '../util/ApiUtil';
import INBOUND_OPS_PERMISSIONS from '../../../client/constants/ORGANIZATION_PERMISSIONS';

const OrganizationPermissions = (props) => {
  const [toggledCheckboxes, setToggledCheckboxes] = useState([]);
  const organization = props.organization;

  const updateToggledCheckBoxes = (userId, permissionName, checked) => {
    const newData = { userId, permissionName, checked };
    const stateCopy = toggledCheckboxes;

    // check if the id and permission already exist in the state. Returns undefined if it didn't find a match.
    const existsInState = toggledCheckboxes.findIndex((checkboxData) =>
      checkboxData.userId === newData.userId && checkboxData.permissionName === newData.permissionName);

    // add the item to state if it didn't exist, update it otherwise.
    if (existsInState > -1) {
      stateCopy[existsInState].checked = !stateCopy[existsInState].checked;
      setToggledCheckboxes([...stateCopy]);
    } else {
      setToggledCheckboxes([...[newData], ...stateCopy]);
    }
  };

  const modifyUserPermission = (userId, permissionName) => () => {
    const payload = { data: { userId, permissionName } };

    ApiUtil.patch(`/organizations/${props.organization}/update_permissions`, payload).
      then((response) => {
        updateToggledCheckBoxes(userId, permissionName, response.body.checked);
      }, (error) => {
        // eslint-disable-next-line no-console
        console.log(error);
      });
  };

  const userPermissions = (user, permission) => {
    if (user.attributes.user_permission === null ||
        typeof user.attributes.user_permission === 'undefined' ||
      user.attributes.user_permission.length === 0) {
      return false;
    }

    if (user.attributes.user_permission.flat().find((userPer) => userPer.permission === permission)) {
      return true;
    }
  };

  const checkAdminPermission = (user, permission) => {
    if (user.attributes.user_admin_permission === null ||
      typeof user.attributes.user_admin_permission === 'undefined') {
      return false;
    }

    if (user.attributes.user_admin_permission.find((adminPer) => adminPer.permission === permission)) {
      return true;
    }
  };

  const parentPermissionChecked = (userId, parentId) => {
    if (typeof parentId !== 'number') {
      return true;
    }

    let result = false;
    const parentPermission = props.permissions.find((permission) => permission.id === parentId);
    const orgUserPermissions = props.organizationUserPermissions.find((x) =>
      x.user_id === Number(userId)).organization_user_permissions;

    const checkboxInState = toggledCheckboxes.find((permission) =>
      permission.userId === userId &&
    permission.permissionName === parentPermission.permission);

    if (typeof checkboxInState !== 'undefined' && checkboxInState.checked) {
      return true;
    }

    orgUserPermissions.forEach((permission) => {
      if (permission.organization_permission.permission === parentPermission.permission &&
        permission.permitted &&
        typeof checkboxInState === 'undefined') {
        result = true;
      }
    });

    return result;
  };

  // Correspondence: Refactor Candidate
  // CodeClimate: Avoid too many return statements within this function.
  const getCheckboxEnabled = (user, orgUserData, permission) => {
    let isEnabled = false;

    // uses the local state over what comes in over props
    const stateValue = toggledCheckboxes.find(
      (storedCheckbox) =>
        storedCheckbox.userId === user.id &&
        storedCheckbox.permissionName === permission.permission
    );

    const isCheckboxEnabledInState = toggledCheckboxes.find(
      (checkboxInState) =>
        checkboxInState.userId === user.id &&
        checkboxInState.permissionName === permission.permission &&
        checkboxInState.checked
    );

    // check if user is marked as admin to auto check the checkbox.
    const isUserAdmin = permission.default_for_admin && user.attributes.admin;

    const isCheckboxDefinedInState = typeof stateValue !== 'undefined';

    // default state that came in when page loads, used as final fallback.
    const isCheckboxPermittedInDefaultState = () => {
      const relevantPermissions = props.organizationUserPermissions.find(
        (oup) => oup.user_id === Number(user.id)
      ).organization_user_permissions;

      return relevantPermissions.find(
        (perm) =>
          perm.organization_permission.permission === permission.permission &&
          perm.permitted
      );
    };

    if (isCheckboxEnabledInState || isUserAdmin) {
      isEnabled = true;
    } else if (isCheckboxDefinedInState) {
      isEnabled = stateValue.checked;
    } else if (isCheckboxPermittedInDefaultState()) {
      isEnabled = true;
    }

    return isEnabled;
  };

  const permissionAdminCheck = (user, permission) => {
    if (user.attributes.admin && permission.default_for_admin) {
      return true;
    }
    if (user.attributes.admin && !permission.default_for_admin) {
      return false;
    }

    return true;
  };

  const orderInboundOpsCheckboxes = (permissions) => {
    const orderedPermissions = [];

    // sort through permissions and order based on constants file
    Object.keys(INBOUND_OPS_PERMISSIONS).map((orgPermission) => {
      return orderedPermissions.push(permissions.find((permission) => permission.permission === orgPermission));
    });

    return orderedPermissions;
  };

  // switch statement to order permissions for the organization
  const orderCheckboxes = (permissions) => {
    switch (organization) {
    case 'inbound-ops-team':
      return orderInboundOpsCheckboxes(permissions);
    default:
      return permissions;
    }
  };

  const generateCheckboxes = (permissions, user) => {
    return orderCheckboxes(permissions).map((permission) => {
      const marginL = permission.parent_permission_id ? '25px' : '0px';

      const checkboxStyle = {
        style: {
          marginTop: '0',
          marginLeft: marginL,
          marginBottom: '10px'
        }
      };

      return (parentPermissionChecked(user.id, permission.parent_permission_id) &&
      permissionAdminCheck(user, permission) &&
        <Checkbox
          name={`${user.id}-${permission.permission}`}
          label={permission.description}
          key={`${user.id}-${permission.permission}`}
          styling={checkboxStyle}
          onChange={modifyUserPermission(user.id, permission.permission)}
          defaultValue={(userPermissions(user, permission.permission) ||
            checkAdminPermission(user, permission.permission))}
          disabled={checkAdminPermission(user, permission.permission)}
          value={getCheckboxEnabled(user, props.orgUserData, permission)}
        />);
    });
  };

  return (<>
    <p className={['user-permissions-text']}>User permissions:</p>
    {generateCheckboxes(props.permissions, props.user)}
  </>);

};

export default OrganizationPermissions;

OrganizationPermissions.propTypes = {
  permissions: PropTypes.array,
  user: PropTypes.object,
  organization: PropTypes.string,
  orgUserData: PropTypes.object,
  organizationUserPermissions: PropTypes.array
};
