import * as React from 'react';
import PropTypes from 'prop-types';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { onReceiveAmaTasks } from './QueueActions';
import QueueFlowModal from './components/QueueFlowModal';
import { requestSave } from './uiReducer/uiActions';
import TASK_ACTIONS from '../../constants/TASK_ACTIONS';
import { taskById } from './selectors';
import { withRouter } from 'react-router-dom';

class PostponeHearingTaskModal extends React.Component {
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
        this.props.onReceiveAmaTasks(resp.body.tasks.data);
      }).
      catch(() => {
        // handle the error from the frontend
      });
  }

  render = () => <QueueFlowModal
    title={TASK_ACTIONS.RESCHEDULE_NO_SHOW_HEARING.label}
    submit={this.submit}
  >
    <p>Postponing this case will make the case available to be scheduled again.</p>
  </QueueFlowModal>;
}

PostponeHearingTaskModal.propTypes = {
  onReceiveAmaTasks: PropTypes.func,
  requestSave: PropTypes.func,
  task: PropTypes.shape({
    taskId: PropTypes.string
  })
};

const mapStateToProps = (state, ownProps) => ({
  task: taskById(state, { taskId: ownProps.taskId })
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  requestSave,
  onReceiveAmaTasks
}, dispatch);

export default withRouter(connect(mapStateToProps, mapDispatchToProps)(PostponeHearingTaskModal));
