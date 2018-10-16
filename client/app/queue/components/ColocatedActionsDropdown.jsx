// @flow
import * as React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { withRouter } from 'react-router-dom';
import { sprintf } from 'sprintf-js';

import SearchableDropdown from '../../components/SearchableDropdown';

import {
  tasksForAppealAssignedToUserSelector,
  appealWithDetailSelector
} from '../selectors';
import { stageAppeal } from '../QueueActions';

import {
  dropdownStyling,
  SEND_TO_LOCATION_MODAL_TYPES
} from '../constants';
import CO_LOCATED_ACTIONS from '../../../constants/CO_LOCATED_ACTIONS.json';
import CO_LOCATED_ADMIN_ACTIONS from '../../../constants/CO_LOCATED_ADMIN_ACTIONS.json';
import COPY from '../../../COPY.json';

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
      appeal
    } = this.props;
    const options = [{
      label: COPY.COLOCATED_ACTION_SEND_BACK_TO_ATTORNEY,
      value: CO_LOCATED_ACTIONS.SEND_BACK_TO_ATTORNEY
    }, {
      label: COPY.COLOCATED_ACTION_PLACE_HOLD,
      value: CO_LOCATED_ACTIONS.PLACE_HOLD
    }];

    if (['translation', 'schedule_hearing'].includes(task.action) && appeal.isLegacyAppeal) {
      options.unshift({
        label: sprintf(COPY.COLOCATED_ACTION_SEND_TO_TEAM, CO_LOCATED_ADMIN_ACTIONS[task.action]),
        value: CO_LOCATED_ACTIONS.SEND_TO_TEAM
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
  task: tasksForAppealAssignedToUserSelector(state, ownProps)[0],
  appeal: appealWithDetailSelector(state, ownProps)
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  stageAppeal
}, dispatch);

export default (withRouter(
  connect(mapStateToProps, mapDispatchToProps)(ColocatedActionsDropdown)
): React.ComponentType<Params>);
