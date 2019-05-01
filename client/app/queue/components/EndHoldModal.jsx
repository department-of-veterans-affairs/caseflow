import * as React from 'react';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { withRouter } from 'react-router-dom';

import { taskById } from '../selectors';
import { onReceiveAmaTasks } from '../QueueActions';
import { requestSave } from '../uiReducer/uiActions';
import QueueFlowModal from './QueueFlowModal';

class EndHoldModal extends React.Component {
  submit = () => {
    const { task } = this.props;

    // TODO: Where do these fields come from?
    const successMsg = {
      title: 'success',
      detail: 'Ended hold early successfully'
    };

    return this.props.requestSave(`/tasks/${task.taskId}/end_hold`, successMsg).
      then((resp) => {
        const response = JSON.parse(resp.text);

        this.props.onReceiveAmaTasks(response.tasks.data);
      });
  }

  render = () => <QueueFlowModal
    title="End hold early"
    // TODO: Set this to the case details page.
    pathAfterSubmit="/queue"
    submit={this.submit}
  >
    <div>Do you want to end the hold early?</div>
  </QueueFlowModal>;
}

const mapStateToProps = (state, ownProps) => ({
  task: taskById(state, { taskId: ownProps.taskId })
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  requestSave,
  onReceiveAmaTasks
}, dispatch);

export default (withRouter(connect(mapStateToProps, mapDispatchToProps)(EndHoldModal)));
