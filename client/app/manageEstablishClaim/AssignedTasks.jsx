import React from 'react';
import PropTypes from 'prop-types';

import NumberField from '../components/NumberField';
import { connect } from 'react-redux';
import * as Constants from './constants/index';

const AssignedTasks = ({
  userQuota,
  handleEditTaskCount
}) => {
  return <span>
    {!userQuota.isEditingTaskCount && userQuota.taskCount }

    {userQuota.isEditingTaskCount &&
      <NumberField
        label={false}
        name={`quota-${userQuota.id}`}
        id={`quota-${userQuota.id}`}
        className={['cf-inline-field']}
        onChange={handleEditTaskCount}
        isInteger={true}
        value={userQuota.newTaskCount}
        title={`Update ${userQuota.userName}'s assigned tasks`}
      />
    }
  </span>;
};

AssignedTasks.propTypes = {
  userQuota: PropTypes.object.isRequired,
  handleEditTaskCount: PropTypes.func.isRequired
};

const mapDispatchToProps = (dispatch, ownProps) => ({
  handleEditTaskCount: (taskCount) => {
    dispatch({
      type: Constants.CHANGE_NEW_TASK_COUNT,
      payload: {
        userQuotaIndex: ownProps.userQuota.index,
        taskCount
      }
    });
  }
});

export default connect(
  null,
  mapDispatchToProps
)(AssignedTasks);
