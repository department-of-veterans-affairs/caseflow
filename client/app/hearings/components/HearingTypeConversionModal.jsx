import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { get } from 'lodash';
import { sprintf } from 'sprintf-js';
import { withRouter } from 'react-router-dom';
import PropTypes from 'prop-types';
import React, { useState } from 'react';

import Modal from '../../components/Modal';
import { appealWithDetailSelector, taskById } from '../../queue/selectors';
import { clearAppealDetails } from '../../queue/QueueActions';
import { showErrorMessage, showSuccessMessage } from '../../queue/uiReducer/uiActions';
import ApiUtil from '../../util/ApiUtil';
import Button from '../../components/Button';
import { formatChangeRequestType } from '../utils';

// Constants
import COPY from '../../../COPY';
import TASK_STATUSES from '../../../constants/TASK_STATUSES';

export const HearingTypeConversionModal = ({
  appeal,
  history,
  task,
  hearingType,
  ...props
}) => {
  // Create and manage the loading state
  const [loading, setLoading] = useState(false);

  const getSuccessMsg = () => {
    // Format the message title adding the veteran info and hearing request type
    const title = sprintf(
      COPY.CONVERT_HEARING_TYPE_SUCCESS,
      appeal?.appellantIsNotVeteran ? appeal?.appellantFullName : appeal?.veteranFullName,
      hearingType
    );

    // Determine whether to use the default ro Label
    const defaultLabel = appeal?.closestRegionalOfficeLabel === 'Central Office' ?
      COPY.CONVERT_HEARING_TYPE_DEFAULT_REGIONAL_OFFICE_TEXT :
      appeal?.closestRegionalOfficeLabel;

    // Determine whether to override the default label if converting to Central Office
    const roLabel = hearingType === 'Central' ? 'Central Office' : defaultLabel;

    // Format the message details adding the appropriate RO label
    const detail = sprintf(COPY.CONVERT_HEARING_TYPE_SUCCESS_DETAIL, roLabel);

    return { title, detail };
  };

  const submit = async () => {
    try {
      // Determine the changed request type
      const changedRequestType = formatChangeRequestType(hearingType);

      // Determine the closest regional office
      const closestRegionalOffice = hearingType === 'Video' ? null : 'C';

      const data = {
        task: {
          status: TASK_STATUSES.completed,
          business_payloads: {
            values: {
              changed_hearing_request_type: changedRequestType,
              closest_regional_office: closestRegionalOffice
            }
          }
        }
      };

      setLoading(true);

      await ApiUtil.patch(`/tasks/${task.taskId}`, { data });

      // Add the google analytics event
      window.analyticsEvent('Hearings', 'Convert hearing request type', hearingType);

      props.clearAppealDetails(task.externalAppealId);
      props.showSuccessMessage(getSuccessMsg());
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

  const cancel = () => history.goBack();

  const convertTitle = sprintf(COPY.CONVERT_HEARING_TYPE_TITLE, hearingType);
  const convertSubtitle = sprintf(
    COPY.CONVERT_HEARING_TYPE_SUBTITLE,
    hearingType === 'Video' ?
      COPY.CONVERT_HEARING_TYPE_DEFAULT_REGIONAL_OFFICE_TEXT :
      '<strong>Central Office</strong>'
  );

  return (
    <Modal
      title={convertTitle}
      closeHandler={cancel}
      confirmButton={<Button disabled={loading} onClick={submit}>Convert Hearing to {hearingType}</Button>}
      cancelButton={<Button linkStyling disabled={loading} onClick={cancel}>Cancel</Button>}
    >
      <p dangerouslySetInnerHTML={{ __html: convertSubtitle }} />
    </Modal>
  );
};

HearingTypeConversionModal.propTypes = {
  appeal: PropTypes.object,
  appealId: PropTypes.string,
  clearAppealDetails: PropTypes.func,
  showErrorMessage: PropTypes.func,
  showSuccessMessage: PropTypes.func,
  task: PropTypes.object,
  taskId: PropTypes.string,
  hearingType: PropTypes.oneOf(['Video', 'Central']),
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
      clearAppealDetails,
      showErrorMessage,
      showSuccessMessage
    },
    dispatch
  );

export default withRouter(
  connect(
    mapStateToProps,
    mapDispatchToProps
  )(HearingTypeConversionModal)
);
