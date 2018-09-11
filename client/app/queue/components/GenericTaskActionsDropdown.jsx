// @flow
import * as React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { withRouter } from 'react-router-dom';

import SearchableDropdown from '../../components/SearchableDropdown';

import {
  getTasksForAppeal,
  appealWithDetailSelector
} from '../selectors';
import { stageAppeal } from '../QueueActions';
import { showModal } from '../uiReducer/uiActions';

import { dropdownStyling } from '../constants';

import type { State } from '../types/state';
import type { Task, Appeal } from '../types/models';

type Params = {|
  appealId: string
|};

type Props = Params & {|
  // state
  task: Task,
  appeal: Appeal,
  // dispatch
  showModal: typeof showModal,
  stageAppeal: typeof stageAppeal,
  // withrouter
  history: Object
|};

class GenericTaskActionsDropdown extends React.PureComponent<Props> {
  onChange = (props) => {
    const {
      appealId,
      history
    } = this.props;

    this.props.stageAppeal(appealId);

    switch (props.value) {
    case 'mark-task-complete':
      history.push(`/queue/appeals/${appealId}/mark_task_complete`);
      break;
    // case "assign-to-team":
    //   history.push(`/queue/appeals/${appealId}/assign_to_team`);
    //   break;
    // case "assign-to-person":
    //   history.push(`/queue/appeals/${appealId}/assign_to_person`);
    //   break;
    default:
      break;
    }
  }

  getOptions = () => {
    return [
      // {
      //   label: "Assign to team",
      //   value: "assign-to-team"
      // },
      // {
      //   label: "Assign to person",
      //   value: "assign-to-person"
      // },
      {
        label: 'Mark task complete',
        value: 'mark-task-complete'
      }
    ];
  }

  render = () => <SearchableDropdown
    name={`start-generic-task-action-flow-${this.props.appealId}`}
    placeholder="Select an action&hellip;"
    options={this.getOptions()}
    onChange={this.onChange}
    hideLabel
    dropdownStyling={dropdownStyling} />;
}

const mapStateToProps = (state: State, ownProps: Params) => ({
  task: getTasksForAppeal(state, ownProps)[0],
  appeal: appealWithDetailSelector(state, ownProps)
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  showModal,
  stageAppeal
}, dispatch);

export default (withRouter(
  connect(mapStateToProps, mapDispatchToProps)(GenericTaskActionsDropdown)
): React.ComponentType<Params>);
