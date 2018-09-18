// @flow
import * as React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { withRouter } from 'react-router-dom';
import { sprintf } from 'sprintf-js';

import SearchableDropdown from '../../components/SearchableDropdown';

import {
  getTasksForAppeal,
  appealWithDetailSelector
} from '../selectors';
import {
  taskIsOnHold,
  taskHasNewDocuments
} from '../utils';
import { stageAppeal } from '../QueueActions';

import {
  dropdownStyling,
  SEND_TO_LOCATION_MODAL_TYPES
} from '../constants';
import CO_LOCATED_ACTIONS from '../../../constants/CO_LOCATED_ACTIONS.json';
import CO_LOCATED_ADMIN_ACTIONS from '../../../constants/CO_LOCATED_ADMIN_ACTIONS.json';
import COPY from '../../../COPY.json';

import type { State, NewDocsForAppeal } from '../types/state';
import type { Task, Appeal } from '../types/models';

type Params = {|
  appealId: string
|};

type Props = Params & {|
  // state
  task: Task,
  appeal: Appeal,
  newDocsForAppeal: NewDocsForAppeal,
  // dispatch
  stageAppeal: typeof stageAppeal,
  // withrouter
  history: Object
|};

class ColocatedActionsDropdown extends React.PureComponent<Props> {
  onChange = (option) => {
    if (!option) {
      return;
    }
    const {
      appealId,
      history
    } = this.props;
    const actionType = option.value;

    this.props.stageAppeal(appealId);

    switch (actionType) {
    case CO_LOCATED_ACTIONS.SEND_BACK_TO_ATTORNEY:
      history.push(`/queue/modal/${SEND_TO_LOCATION_MODAL_TYPES.attorney}`);
      break;
    case CO_LOCATED_ACTIONS.SEND_TO_TEAM:
      history.push(`/queue/modal/${SEND_TO_LOCATION_MODAL_TYPES.team}`);
      break;
    case CO_LOCATED_ACTIONS.PLACE_HOLD:
      history.push(`/queue/appeals/${appealId}/place_hold`);
      break;
    default:
      break;
    }
  }

  getOptions = () => {
    const {
      task,
      appeal,
      newDocsForAppeal
    } = this.props;
    const options = [];

    if (['translation', 'schedule_hearing'].includes(task.action) && appeal.docketName === 'legacy') {
      options.push({
        label: sprintf(COPY.COLOCATED_ACTION_SEND_TO_TEAM, CO_LOCATED_ADMIN_ACTIONS[task.action]),
        value: CO_LOCATED_ACTIONS.SEND_TO_TEAM
      });
    } else {
      options.push({
        label: COPY.COLOCATED_ACTION_SEND_BACK_TO_ATTORNEY,
        value: CO_LOCATED_ACTIONS.SEND_BACK_TO_ATTORNEY
      });
    }

    // todo: better encapsulation of task on hold / pending logic
    if (!taskIsOnHold(task) || taskHasNewDocuments(task, newDocsForAppeal)) {
      options.push({
        label: COPY.COLOCATED_ACTION_PLACE_HOLD,
        value: CO_LOCATED_ACTIONS.PLACE_HOLD
      });
    }

    return options;
  }

  render = () => <SearchableDropdown
    name={`start-colocated-action-flow-${this.props.appealId}`}
    placeholder="Select an action&hellip;"
    options={this.getOptions()}
    onChange={this.onChange}
    hideLabel
    dropdownStyling={dropdownStyling} />;
}

const mapStateToProps = (state: State, ownProps: Params) => ({
  task: getTasksForAppeal(state, ownProps)[0],
  appeal: appealWithDetailSelector(state, ownProps),
  newDocsForAppeal: state.queue.newDocsForAppeal
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  stageAppeal
}, dispatch);

export default (withRouter(
  connect(mapStateToProps, mapDispatchToProps)(ColocatedActionsDropdown)
): React.ComponentType<Params>);
