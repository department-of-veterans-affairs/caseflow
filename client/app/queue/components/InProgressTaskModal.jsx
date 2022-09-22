import React from 'react';
import PropTypes from 'prop-types';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { withRouter } from 'react-router-dom';

import { taskById } from '../selectors';
import { requestPatch } from '../uiReducer/uiActions';
import { taskActionData } from '../utils';
import TASK_STATUSES from '../../../constants/TASK_STATUSES';
import QueueFlowModal from './QueueFlowModal';
import StringUtil from '../../util/StringUtil';

/* eslint-disable camelcase */
const InProgressTaskModal = (props) => {
  const { task } = props;
  const taskData = taskActionData(props);

  const submit = () => {
    const payload = {
      data: {
        task: {
          status: TASK_STATUSES.in_progress,
          ...(taskData?.business_payloads && { business_payloads: taskData?.business_payloads })
        }
      }
    };

    const successMsg = {
      title: taskData.message_title,
      detail: (
        <span>
          <span dangerouslySetInnerHTML={{ __html: taskData.message_detail }} />
        </span>
      )
    };

    return props.requestPatch(`/tasks/${task.taskId}`, payload, successMsg);
  };

  return (
    <QueueFlowModal
      title={taskData?.modal_title ?? ''}
      pathAfterSubmit={taskData?.redirect_after ?? '/queue'}
      submit={submit}
      button={taskData.modal_button_text || 'Submit'}
      submitButtonClassNames={['usa-button']}
    >
      {taskData?.modal_body &&
          <div> { StringUtil.nl2br(taskData.modal_body) } </div>
      }
    </QueueFlowModal>
  );
};
/* eslint-enable camelcase */

InProgressTaskModal.propTypes = {
  requestPatch: PropTypes.func,
  task: PropTypes.shape({
    taskId: PropTypes.string
  }),
  highlightFormItems: PropTypes.bool
};

const mapStateToProps = (state, ownProps) => ({
  task: taskById(state, { taskId: ownProps.taskId }),
  highlightFormItems: state.ui.highlightFormItems
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  requestPatch
}, dispatch);

export default (withRouter(
  connect(mapStateToProps, mapDispatchToProps)(
    InProgressTaskModal
  )
));
