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
    const {
      task
    } = this.props;
    const payload = {
      data: {
        task
      }
    };
    const successMsg = 'WORD';

    // debugger;

    return this.props.requestSave('/assign_to_pulac_cerullo', payload, successMsg).
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
