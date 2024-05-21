import React, { useState } from 'react';
import Checkbox from '../components/Checkbox';
import PropTypes from 'prop-types';
import ApiUtil from '../util/ApiUtil';

const OrganizationPermissions = (props) => {
  const [toggledCheckboxes, setToggledCheckboxes] = useState([]);

  const updateToggledCheckBoxes = (userId, permissionName, checked) => {
    const newData = { userId, permissionName, checked };
    const stateCopy = this.state.toggledCheckboxes;

    // check if the id and permission already exist in the state. Returns undefined if it didn't find a match.
    const existsInState = this.state.toggledCheckboxes.findIndex((checkboxData) =>
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

      return (true && <Checkbox
        name={`${user.id}-${permission.permission}`}
        label={permission.description}
        key={`${user.id}-${permission.permission}`}
        styling={checkboxStyle}
        onChange={modifyUserPermission(user.id, permission.permission)}
        defaultValue={(userPermissions(user, permission.permission) ||
        false )}// checkAdminPermission(permission.permission))}
      // disabled={checkAdminPermission(permission.permission)}
      // value={getCheckboxEnabled(permission)}
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
