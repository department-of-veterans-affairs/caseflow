import * as React from 'react';
import PropTypes from 'prop-types';
import { boldText } from './constants';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { onReceiveAmaTasks } from './QueueActions';
import QueueFlowModal from './components/QueueFlowModal';
import { requestSave } from './uiReducer/uiActions';
import TASK_ACTIONS from '../../constants/TASK_ACTIONS';
import { taskById } from './selectors';
import { withRouter } from 'react-router-dom';
import RadioField from '../components/RadioField';
import HEARING_POSTPONEMENT_REASONS from '../../constants/HEARING_POSTPONEMENT_REASONS';

const POSTPONEMENT_OPTIONS = [
  { displayText: 'VBMS',
    value: HEARING_POSTPONEMENT_REASONS.technical },
  { displayText: 'VACOLS',
    value: HEARING_POSTPONEMENT_REASONS.requested },
  { displayText: 'None of the above',
    value: HEARING_POSTPONEMENT_REASONS.board_action }
];

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
    <div>
      <span {...boldText}>Reasons for postponing:</span>
      <RadioField name="hearingChangeQuestion"
        label="Reasons for postponing:"
        required
        options={POSTPONEMENT_OPTIONS}
        value={postponementOption}
        errorMessage={"no"}
        onChange={} />
    </div>
  </QueueFlowModal>;
}

PostponeHearingTaskModal.propTypes = {
  onReceiveAmaTasks: PropTypes.func,
  requestSave: PropTypes.func,
  postponementOption: PropTypes.string,
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
