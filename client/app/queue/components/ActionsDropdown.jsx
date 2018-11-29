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
  changeRoute = (option: ?OptionType) => {
    const {
      appealId,
      task,
      history
    } = this.props;

    if (!option) {
      return;
    }

    this.props.stageAppeal(appealId);
    this.props.resetDecisionOptions();

    history.push(`/queue/appeals/${appealId}/tasks/${task.uniqueId}/${option.value}`);
  };

  render = () => {
    if (!this.props.task) {
      return null;
    }

    return <SearchableDropdown
      name={`start-checkout-flow-${this.props.appealId}`}
      placeholder="Select an action&hellip;"
      options={this.props.task.availableActions}
      onChange={this.changeRoute}
      hideLabel
      dropdownStyling={dropdownStyling} />;
  }
}

const mapStateToProps = (state: State, ownProps) => ({
  appeal: state.queue.appeals[ownProps.appealId],
  changedAppeals: _.keys(state.queue.stagedChanges.appeals),
  featureToggles: state.ui.featureToggles
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  resetDecisionOptions,
  stageAppeal
}, dispatch);

export default (withRouter(
  connect(mapStateToProps, mapDispatchToProps)(ActionsDropdown)
): React.ComponentType<Params>);
