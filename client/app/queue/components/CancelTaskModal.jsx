import * as React from 'react';
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
import editModalBase from './EditModalBase';
import { taskActionData } from '../utils';
import TASK_STATUSES from '../../../constants/TASK_STATUSES.json';

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
        const response = JSON.parse(resp.text);

        this.props.onReceiveAmaTasks(response.tasks.data);
      });
  }

  render = () => {
    const taskData = taskActionData(this.props);

    return <div>{taskData && taskData.modal_body}</div>;
  };
}

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

const propsToText = (props) => {
  const taskData = taskActionData(props);
  const pathAfterSubmit = (taskData && taskData.redirect_after) || '/queue';

  return {
    title: taskData ? taskData.modal_title : '',
    pathAfterSubmit
  };
};

export default (withRouter(
  connect(mapStateToProps, mapDispatchToProps)(editModalBase(
    CancelTaskModal, { propsToText }
  ))
));
