import * as React from 'react';
import PropTypes from 'prop-types';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { withRouter } from 'react-router-dom';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';

import {
  taskById,
  appealWithDetailSelector
} from '../selectors';
import { onReceiveAmaTasks } from '../QueueActions';
import {
  requestPatch
} from '../uiReducer/uiActions';
import { taskActionData } from '../utils';
import TASK_STATUSES from '../../../constants/TASK_STATUSES';
import QueueFlowModal from './QueueFlowModal';

class CancelTaskModal extends React.Component {
  submit = () => {
    const {
      task,
      hearingDay
    } = this.props;
    const payload = {
      data: {
        task: {
          status: TASK_STATUSES.cancelled
        }
      }
    };

    const hearingScheduleLink = taskActionData(this.props).back_to_hearing_schedule ?
      <p>
        <Link href={`/hearings/schedule/assign?roValue=${hearingDay.regionalOffice}`}>Back to Hearing Schedule </Link>
      </p> : null;
    const successMsg = {
      title: taskActionData(this.props).message_title,
      detail: <span><span>{taskActionData(this.props).message_detail}</span>{hearingScheduleLink}</span>
    };

    return this.props.requestPatch(`/tasks/${task.taskId}`, payload, successMsg).
      then((resp) => {
        this.props.onReceiveAmaTasks(resp.body.tasks.data);
      });
  }

  render = () => {
    const taskData = taskActionData(this.props);

    return <QueueFlowModal
      title={taskData ? taskData.modal_title : ''}
      pathAfterSubmit={(taskData && taskData.redirect_after) || '/queue'}
      submit={this.submit}
    >
      <div>{taskData && taskData.modal_body}</div>
    </QueueFlowModal>;
  };
}

CancelTaskModal.propTypes = {
  hearingDay: PropTypes.shape({
    regionalOffice: PropTypes.string
  }),
  onReceiveAmaTasks: PropTypes.func,
  requestPatch: PropTypes.func,
  task: PropTypes.shape({
    taskId: PropTypes.string
  })
};

const mapStateToProps = (state, ownProps) => ({
  task: taskById(state, { taskId: ownProps.taskId }),
  appeal: appealWithDetailSelector(state, ownProps),
  saveState: state.ui.saveState.savePending,
  hearingDay: state.ui.hearingDay
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  requestPatch,
  onReceiveAmaTasks
}, dispatch);

export default (withRouter(
  connect(mapStateToProps, mapDispatchToProps)(
    CancelTaskModal
  )
));
