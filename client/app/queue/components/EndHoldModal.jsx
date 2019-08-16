import * as React from 'react';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { onReceiveAmaTasks } from '../QueueActions';
import QueueFlowModal from './QueueFlowModal';
import { requestSave } from '../uiReducer/uiActions';
import COPY from '../../../COPY.json';
import { taskById } from '../selectors';
import { withRouter } from 'react-router-dom';

class EndHoldModal extends React.Component {
  submit = () => {
    const { task } = this.props;

    const successMsg = {
      title: COPY.END_HOLD_SUCCESS_MESSAGE_TITLE
    };

    return this.props.requestSave(`/tasks/${task.taskId}/end_hold`, {}, successMsg).
      then((resp) => {
        this.props.onReceiveAmaTasks(resp.body.tasks.data);
      });
  }

  render = () => <QueueFlowModal
    title={COPY.END_HOLD_MODAL_TITLE}
    pathAfterSubmit={`/queue/appeals/${this.props.appealId}`}
    submit={this.submit}
  >
    <p>{COPY.END_HOLD_MODAL_BODY}</p>
  </QueueFlowModal>;
}

const mapStateToProps = (state, ownProps) => ({
  task: taskById(state, { taskId: ownProps.taskId })
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  requestSave,
  onReceiveAmaTasks
}, dispatch);

export default withRouter(connect(mapStateToProps, mapDispatchToProps)(EndHoldModal));
