import React from 'react';
import Checkbox from '../components/Checkbox';
import PropTypes from 'prop-types';

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
    // onChange={this.modifyUserPermission(user.id, permission.permission)}
    // defaultValue={(userPermissions(permission.permission) || checkAdminPermission(permission.permission))}
    // disabled={checkAdminPermission(permission.permission)}
    // value={getCheckboxEnabled(permission)}
    />);
  });
};

const OrganizationPermissions = (props) => {
  return (<>
    <p className={['user-permissions-text']}>User permissions:</p>
    {generateCheckboxes(props.permissions, props.user)}
  </>);

};

export default OrganizationPermissions;

OrganizationPermissions.propTypes = {
  permissions: PropTypes.array,
  user: PropTypes.object

};
