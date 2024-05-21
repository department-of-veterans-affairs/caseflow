import React, { useState } from 'react';
import Checkbox from '../components/Checkbox';
import PropTypes from 'prop-types';
import ApiUtil from '../util/ApiUtil';

const OrganizationPermissions = (props) => {
  const [toggledCheckboxes, setToggledCheckboxes] = useState([]);

  const updateToggledCheckBoxes = (userId, permissionName, checked) => {
    const newData = { userId, permissionName, checked };
    const stateCopy = toggledCheckboxes;

    // check if the id and permission already exist in the state. Returns undefined if it didn't find a match.
    const existsInState = toggledCheckboxes.findIndex((checkboxData) =>
      checkboxData.userId === newData.userId && checkboxData.permissionName === newData.permissionName);

    // add the item to state if it didn't exist, update it otherwise.
    if (existsInState > -1) {
      stateCopy[existsInState].checked = !stateCopy[existsInState].checked;
      setToggledCheckboxes(stateCopy);
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

  const getCheckboxEnabled = (user, orgUserData, permission) => {
    const stateValue = (toggledCheckboxes.find((storedCheckbox) =>
      storedCheckbox.userId === user.id && storedCheckbox.permissionName === permission.permission));

    // prioritize state values
    const orgUserPermissions = props.orgUserData.attributes;

    // console.log(orgUserPermissions.user_permission)

    if(user.attributes.user_permission.find((perm) => perm.permission === permission.permission)) {
      // console.log("true found permission")
      return true;
    }

    // if (orgUserPermissions.user_permission.find((oup) => (Object.values(oup).includes(permission.permission)))) {
    //   return true;
    // }

    // if (orgUserPermissions.user_admin_permission.find((oup) => (Object.values(oup).includes(permission.permission)))) {
    //   return true;
    // }

    // if (typeof stateValue !== 'undefined') {
    //   return stateValue.checked;
    // }

    // // fallback to props if no state
    // const userData = (this.props.orgnizationUserPermissions.find((oup) => oup.user_id === Number(user.id)));

    // if (userData.organization_user_permissions.find((oup) =>
    //   oup.organization_permission.permission === permission.permission && oup.permitted)) {
    //   return true;
    // }

    // // check if user is marked as admin to auto check the checkbox.
    // if (permission.default_for_admin && user.attributes.admin) {
    //   return true;
    // }

    // return false;

  };

  const generateCheckboxes = (permissions, user) => {

    return permissions.map((permission) => {
      const marginL = permission.parent_permission_id ? '25px' : '0px';

      const checkboxStyle = {
        style: {
          marginTop: '0',
          marginLeft: marginL,
          marginBottom: '10px'
        }
      };

      getCheckboxEnabled(user, props.orgUserData, permission)

      return (true && <Checkbox
        name={`${user.id}-${permission.permission}`}
        label={permission.description}
        key={`${user.id}-${permission.permission}`}
        styling={checkboxStyle}
        onChange={modifyUserPermission(user.id, permission.permission)}
        defaultValue={(userPermissions(user, permission.permission) || checkAdminPermission(user, permission.permission))}
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
  organization: PropTypes.string

};
