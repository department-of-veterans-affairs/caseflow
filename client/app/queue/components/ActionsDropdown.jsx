// @flow
import * as React from 'react';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import _ from 'lodash';
import { withRouter } from 'react-router-dom';

import SearchableDropdown, { type OptionType } from '../../components/SearchableDropdown';

import {
  resetDecisionOptions,
  stageAppeal
} from '../QueueActions';
import {
  dropdownStyling
} from '../constants';
import COPY from '../../../COPY.json';

import type {
  State
} from '../types/state';

import type {
  Task
} from '../types/models';

type Params = {|
  task: Task,
  appealId: string
|};

type Props = Params & {|
  // state
  featureToggles: Object,
  appeal: Object,
  changedAppeals: Array<number>,
  // dispatch
  stageAppeal: typeof stageAppeal,
  resetDecisionOptions: typeof resetDecisionOptions,
  // withrouter
  history: Object
|};

class ActionsDropdown extends React.PureComponent<Props> {
  handleSpecialIssuesRoute = (routeString, reDirect) => {
    if (routeString.includes('special_issues') && reDirect) {
      return reDirect;
    }

    return routeString;
  }

  changeRoute = (option: ?OptionType) => {
    const {
      appealId,
      task,
      history,
      specialIssuesRedirect
    } = this.props;

    if (!option) {
      return;
    }

    this.props.stageAppeal(appealId);
    this.props.resetDecisionOptions();
    const nextRoute = this.handleSpecialIssuesRoute(option.value, specialIssuesRedirect);

    history.push(`/queue/appeals/${appealId}/tasks/${task.uniqueId}/${nextRoute}`);
  };

  render = () => {
    if (!this.props.task) {
      return null;
    }

    return <SearchableDropdown
      name={`start-checkout-flow-${this.props.appealId}-${this.props.task.uniqueId}`}
      placeholder={COPY.TASK_ACTION_DROPDOWN_BOX_LABEL}
      options={this.props.task.availableActions}
      onChange={this.changeRoute}
      hideLabel
      dropdownStyling={dropdownStyling} />;
  }
}

const mapStateToProps = (state: State, ownProps) => ({
  appeal: state.queue.appeals[ownProps.appealId],
  changedAppeals: _.keys(state.queue.stagedChanges.appeals),
  featureToggles: state.ui.featureToggles,
  specialIssuesRedirect: state.queue.appealDetails[ownProps.appealId].specialIssuesRedirect
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  resetDecisionOptions,
  stageAppeal
}, dispatch);

export default (withRouter(
  connect(mapStateToProps, mapDispatchToProps)(ActionsDropdown)
): React.ComponentType<Params>);
