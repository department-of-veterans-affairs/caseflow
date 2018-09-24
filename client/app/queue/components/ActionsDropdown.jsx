// @flow
import * as React from 'react';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import _ from 'lodash';
import { withRouter } from 'react-router-dom';

import SearchableDropdown from '../../components/SearchableDropdown';

import {
  setCaseReviewActionType,
  resetDecisionOptions,
  stageAppeal
} from '../QueueActions';
import COPY from '../../../COPY.json';
import {
  dropdownStyling,
  DRAFT_DECISION_OPTIONS,
  DRAFT_DECISION_LEGACY_OPTIONS
} from '../constants';

import type {
  State
} from '../types/state';

type Params = {|
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
  setCaseReviewActionType: typeof setCaseReviewActionType,
  // withrouter
  history: Object
|};

class ActionsDropdown extends React.PureComponent<Props> {
  changeRoute = (option) => {
    const {
      appealId,
      history,
      appeal
    } = this.props;

    this.props.stageAppeal(appealId);
    this.props.resetDecisionOptions();

    history.push('');
    history.replace(`/queue/appeals/${appealId}/${option.value}`);
  };

  render = () => <SearchableDropdown
    name={`start-checkout-flow-${this.props.appealId}`}
    placeholder="Select an action&hellip;"
    options={this.props.task.availableActions}
    onChange={this.changeRoute}
    hideLabel
    dropdownStyling={dropdownStyling} />;
}

const mapStateToProps = (state: State, ownProps) => ({
  appeal: state.queue.appeals[ownProps.appealId],
  changedAppeals: _.keys(state.queue.stagedChanges.appeals),
  featureToggles: state.ui.featureToggles
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  setCaseReviewActionType,
  resetDecisionOptions,
  stageAppeal
}, dispatch);

export default (withRouter(
  connect(mapStateToProps, mapDispatchToProps)(ActionsDropdown)
): React.ComponentType<Params>);
