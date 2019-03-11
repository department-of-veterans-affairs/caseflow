import * as React from 'react';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import editModalBase from './components/EditModalBase';
import { onReceiveAmaTasks } from './QueueActions';
import { requestSave } from './uiReducer/uiActions';
import TASK_ACTIONS from '../../constants/TASK_ACTIONS.json';
import { taskById } from './selectors';
import { withRouter } from 'react-router-dom';

class PostponeHearingModal extends React.Component {
  submit = () => {
    const parentTaskId = this.props.task.taskId;

    const payload = {
      data: {
        tasks: [{
          parent_id: parentTaskId
        }]
      }
    };

    return this.props.requestSave(`/tasks/${parentTaskId}/reschedule`, payload).
      then((resp) => {
        const response = JSON.parse(resp.text);

        this.props.onReceiveAmaTasks(response.tasks.data);
      }).
      catch(() => {
        // handle the error from the frontend
      });
  }

  render = () => <p>Postponing this case will make the case available to be scheduled again.</p>;
}

const mapStateToProps = (state, ownProps) => ({
  task: taskById(state, { taskId: ownProps.taskId })
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  requestSave,
  onReceiveAmaTasks
}, dispatch);

const modalProperties = {
  title: TASK_ACTIONS.RESCHEDULE_NO_SHOW_HEARING.label
};

export default (withRouter(connect(mapStateToProps, mapDispatchToProps)(
  editModalBase(PostponeHearingModal, modalProperties)
)));
