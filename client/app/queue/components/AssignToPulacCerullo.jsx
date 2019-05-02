import * as React from 'react';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { withRouter } from 'react-router-dom';

import {
  taskById
} from '../selectors';
import {
  requestSave
} from '../uiReducer/uiActions';

import QueueFlowModal from './QueueFlowModal';

const pulacCerulloId = 21;

class AssignToPulacCerullo extends React.Component {

  submit = () => {
    const {
      task
    } = this.props;
    const payload = {
      data: {
        tasks: [{
          type: task.type,
          external_id: task.appeal.externalId,
          parent_id: task.taskId,
          assigned_to_id: pulacCerulloId,
          assigned_to_type: 'Organization'
        }]
      }
    };
    const successMsg = 'SAVED TO PULAC CURELLO';

    return this.props.requestSave('/tasks', payload, successMsg).
      then((resp) => {
        console.log('the succesful response', resp);
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
  task: taskById(state, { taskId: ownProps.taskId })
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  requestSave
}, dispatch);

export default (withRouter(connect(mapStateToProps, mapDispatchToProps)(AssignToPulacCerullo)));
