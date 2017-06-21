import React from 'react';
import PropTypes from 'prop-types';

import Button from '../components/Button';
import { connect } from 'react-redux';
import * as Constants from './constants/index';
import ApiUtil from '../util/ApiUtil';
import { lockIcon } from '../components/RenderFunctions';

const UserQuotaControls = ({
  userQuota,
  handleBeginEditTaskCount,
  handleSaveTaskCount,
  handleUnlockTaskCount,
  cancelEditTaskCount
}) => {
  if (!userQuota.isAssigned) {
    return null;
  }

  return <div>
    {!userQuota.isEditingTaskCount && userQuota.isLocked &&
      <Button
        name={`unlock-quota-${userQuota.id}`}
        classNames={['cf-btn-link cf-no-padding cf-no-vertical-margin']}
        onClick={handleUnlockTaskCount}
        ariaLabel="Unlock"
      >
        { lockIcon() }
      </Button>
    }

    {!userQuota.isEditingTaskCount &&
      <Button
        name={`edit-quota-${userQuota.id}`}
        classNames={['cf-btn-link cf-no-padding cf-no-vertical-margin']}
        onClick={handleBeginEditTaskCount}
      >
        Edit
      </Button>
    }

    {userQuota.isEditingTaskCount && <div>
      <Button
        name={`save-quota-${userQuota.id}`}
        classNames={['cf-btn-link cf-no-padding cf-no-vertical-margin']}
        onClick={handleSaveTaskCount}
      >
        Save
      </Button>

      <Button
        name={`cancel-quota-${userQuota.id}`}
        classNames={['cf-btn-link cf-no-padding cf-no-vertical-margin']}
        onClick={cancelEditTaskCount}
      >
        Cancel
      </Button>
    </div>
    }
  </div>;
};

UserQuotaControls.propTypes = {
  userQuota: PropTypes.object.isRequired,
  handleBeginEditTaskCount: PropTypes.func.isRequired,
  handleSaveTaskCount: PropTypes.func.isRequired,
  handleUnlockTaskCount: PropTypes.func.isRequired
};

const dispatchUserQuotaAlert = (dispatch) => {
  dispatch({
    type: Constants.SET_ALERT,
    payload: {
      alert: {
        type: 'error',
        title: 'Error',
        message: 'There was an error while updating the user\'s quota. Please try again later.'
      }
    }
  });
};

const mapDispatchToProps = (dispatch, ownProps) => ({
  handleBeginEditTaskCount: () => {
    dispatch({
      type: Constants.BEGIN_EDIT_TASK_COUNT,
      payload: { userQuotaIndex: ownProps.userQuota.index }
    });
  },
  cancelEditTaskCount: () => {
    dispatch({
      type: Constants.CANCEL_EDIT_TASK_COUNT,
      payload: { userQuotaIndex: ownProps.userQuota.index }
    });
  },
  handleSaveTaskCount: () => {
    return ApiUtil.patch(`/dispatch/user-quotas/${ownProps.userQuota.id}`,
      { data: { locked_task_count: ownProps.userQuota.newTaskCount } }
    ).then(({ body }) => {
      dispatch({
        type: Constants.REQUEST_USER_QUOTAS_SUCCESS,
        payload: { userQuotas: body }
      });
    }, () => {
      dispatchUserQuotaAlert(dispatch);
    });
  },
  handleUnlockTaskCount: () => {
    return ApiUtil.patch(`/dispatch/user-quotas/${ownProps.userQuota.id}`,
      { data: { locked_task_count: null } }
    ).then(({ body }) => {
      dispatch({
        type: Constants.REQUEST_USER_QUOTAS_SUCCESS,
        payload: { userQuotas: body }
      });
    }, () => {
      dispatchUserQuotaAlert(dispatch);
    });
  }
});

export default connect(
  null,
  mapDispatchToProps
)(UserQuotaControls);
