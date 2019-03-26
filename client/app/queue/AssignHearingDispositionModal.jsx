import * as React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { withRouter } from 'react-router-dom';
import { sprintf } from 'sprintf-js';

import COPY from '../../COPY.json';

import {
  taskById,
  appealWithDetailSelector
} from './selectors';

import { onReceiveAmaTasks } from './QueueActions';

import SearchableDropdown from '../components/SearchableDropdown';
import TextareaField from '../components/TextareaField';
import QueueFlowModal from './components/QueueFlowModal';

import {
  requestPatch,
  requestSave
} from './uiReducer/uiActions';

import { taskActionData } from './utils';

const selectedAction = (props) => {
  const actionData = taskActionData(props);

  return actionData.selected ? actionData.options.find((option) => option.value === actionData.selected.id) : null;
};

class AssignHearingDispositionModal extends React.Component {
  submit = () => {
    console.log("submit!");
  }

  tempvalidate = () => {
    console.log("validate!");
  }

  render = () => {
    // const {
    //   assigneeAlreadySelected,
    //   highlightFormItems,
    //   task
    // } = this.props;
    //
    // const action = this.props.task && this.props.task.availableActions.length > 0 ? selectedAction(this.props) : null;
    // const actionData = taskActionData(this.props);
    //
    // if (!task || task.availableActions.length === 0) {
    //   return null;
    // }

    // debugger;
    return <QueueFlowModal
      title="Assign Disposition Title!"
      pathAfterSubmit = "/queue"
      submit={this.submit}
      validateForm={this.tempvalidate}
    />;
  }
}

const mapStateToProps = (state, ownProps) => {
  const {
    highlightFormItems
  } = state.ui;

  return {
    highlightFormItems,
    task: taskById(state, { taskId: ownProps.taskId }),
    appeal: appealWithDetailSelector(state, ownProps)
  };
};

const mapDispatchToProps = (dispatch) => bindActionCreators({
  requestPatch,
  requestSave,
  onReceiveAmaTasks
}, dispatch);

export default (withRouter(connect(mapStateToProps, mapDispatchToProps)(AssignHearingDispositionModal)));
