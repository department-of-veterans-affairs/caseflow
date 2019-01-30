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
  history: Object,
  specialIssuesRedirect: string
|};

class ActionsDropdown extends React.PureComponent<Props> {

  changeRoute = (option: ?OptionType) => {
    const {
      appealId,
      task,
      history,
      appeal
    } = this.props;

    if (!option) {
      return;
    }

    this.props.stageAppeal(appealId);
    this.props.resetDecisionOptions();
    const [checkoutFlow] = option.value && option.value.split('/');
    const nextStep = _.get(option, 'data.redirect_to', null) && !appeal.isLegacyAppeal ?
      `${checkoutFlow}${option.data.redirect_to}` : option.value;

    history.push(`/queue/appeals/${appealId}/tasks/${task.uniqueId}/${nextStep}`);
  };

  render = () => {
    if (!this.props.task) {
      return null;
    }

    console.log(this.props.task);

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
  featureToggles: state.ui.featureToggles
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  resetDecisionOptions,
  stageAppeal
}, dispatch);

export default (withRouter(
  connect(mapStateToProps, mapDispatchToProps)(ActionsDropdown)
): React.ComponentType<Params>);
