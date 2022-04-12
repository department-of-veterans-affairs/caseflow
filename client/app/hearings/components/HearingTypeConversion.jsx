import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { get } from 'lodash';
import { sprintf } from 'sprintf-js';
import { withRouter } from 'react-router-dom';
import PropTypes from 'prop-types';
import React, { useState } from 'react';

import { HearingTypeConversionForm } from './HearingTypeConversionForm';
import { appealWithDetailSelector, taskById } from '../../queue/selectors';
import { deleteAppeal } from '../../queue/QueueActions';
import {
  showErrorMessage,
  showSuccessMessage
} from '../../queue/uiReducer/uiActions';
import ApiUtil from '../../util/ApiUtil';
import COPY from '../../../COPY';
import TASK_STATUSES from '../../../constants/TASK_STATUSES';
import { formatChangeRequestType } from '../utils';

export const HearingTypeConversion = ({
  appeal,
  history,
  task,
  type,
  ...props
}) => {
  // Create and manage the loading state
  const [loading, setLoading] = useState(false);

  const getSuccessMsg = () => {
    const title = sprintf(
      COPY.CONVERT_HEARING_TYPE_SUCCESS,
      appeal?.appellantIsNotVeteran ? appeal?.appellantFullName : appeal?.veteranFullName,
      type
    );
    const detail = sprintf(
      COPY.CONVERT_HEARING_TYPE_SUCCESS_DETAIL,
      appeal?.closestRegionalOfficeLabel || COPY.CONVERT_HEARING_TYPE_DEFAULT_REGIONAL_OFFICE_TEXT
    );

    return { title, detail };
  };

  const submit = async () => {
    try {
      const changedRequestType = formatChangeRequestType(type);
      const data = {
        task: {
          status: TASK_STATUSES.completed,
          business_payloads: {
            values: {
              changed_hearing_request_type: changedRequestType,
              closest_regional_office: appeal?.closestRegionalOffice || appeal?.regionalOffice?.key
            }
          }
        }
      };

      setLoading(true);

      await ApiUtil.patch(`/tasks/${task.taskId}`, { data });

      props.showSuccessMessage(getSuccessMsg());
      props.deleteAppeal(task.externalAppealId);
    } catch (err) {
      const error = get(
        err,
        'response.body.errors[0]',
        {
          title: COPY.DEFAULT_UPDATE_ERROR_MESSAGE_TITLE,
          detail: COPY.DEFAULT_UPDATE_ERROR_MESSAGE_DETAIL
        }
      );

      props.showErrorMessage(error);
    } finally {
      setLoading(false);

      history.push(`/queue/appeals/${appeal.externalId}`);
    }
  };

  return (
    <HearingTypeConversionForm
      appeal={appeal}
      history={history}
      isLoading={loading}
      onCancel={() => history.goBack()}
      onSubmit={submit}
      task={task}
      type={type}
    />
  );
};

HearingTypeConversion.propTypes = {
  appeal: PropTypes.object,
  appealId: PropTypes.string,
  deleteAppeal: PropTypes.func,
  showErrorMessage: PropTypes.func,
  showSuccessMessage: PropTypes.func,
  task: PropTypes.object,
  taskId: PropTypes.string,
  type: PropTypes.oneOf(['Virtual']),
  // Router inherited props
  history: PropTypes.object
};

const mapStateToProps = (state, ownProps) => ({
  appeal: appealWithDetailSelector(state, ownProps),
  task: taskById(state, { taskId: ownProps.taskId })
});

const mapDispatchToProps = (dispatch) =>
  bindActionCreators(
    {
      deleteAppeal,
      showErrorMessage,
      showSuccessMessage
    },
    dispatch
  );

export default withRouter(
  connect(
    mapStateToProps,
    mapDispatchToProps
  )(HearingTypeConversion)
);
