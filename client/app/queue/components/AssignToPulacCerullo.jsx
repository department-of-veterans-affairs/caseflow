/* eslint-disable no-debugger */
import * as React from 'react';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { withRouter } from 'react-router-dom';

import {
  taskById,
  appealWithDetailSelector
} from '../selectors';
import { onReceiveAmaTasks } from '../QueueActions';
import {
  requestSave
} from '../uiReducer/uiActions';

import QueueFlowModal from './QueueFlowModal';

class AssignToPulacCerullo extends React.Component {

  submit = () => {
    // event.preventDefault();
    const {
      task,
      appeal
    } = this.props;
    const payload = {
      // TODO: need to assign this task to pulac on the backend
      data: {
        tasks: [{
          type: task.type,
          external_id: appeal.external_id,
          parent_id: task.taskId,
          // the pulac curello org id is 21
          assigned_to_id: 21
        }]
      }
    };
    const successMsg = 'WORD';

    debugger;

    return this.props.requestSave('/tasks', payload, successMsg).
      then((resp) => {
        const response = JSON.parse(resp.text);

        console.log('the succesful response', response);
      }).
      catch((err) => {
        console.log('the error trying to asisgn to pulac', err);
      });
  }

  render = () => {

    return <QueueFlowModal
      title="Assign To Pulac-Cerullo"
      button="Confirm"
      submit={this.submit}
    >
      Are you sure you want to assign this task to Pulac-Cerullo?
    </QueueFlowModal>;
  };
}

const mapStateToProps = (state, ownProps) => ({
  task: taskById(state, { taskId: ownProps.taskId }),
  appeal: appealWithDetailSelector(state, ownProps),
  saveState: state.ui.saveState.savePending
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  requestSave,
  onReceiveAmaTasks
}, dispatch);

export default (withRouter(connect(mapStateToProps, mapDispatchToProps)(AssignToPulacCerullo)));
