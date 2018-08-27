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
  checkoutStagedAppeal,
  stageAppeal
} from '../QueueActions';
import {
  dropdownStyling,
  DRAFT_DECISION_OPTIONS
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
  changedAppeals: Array<number>,
  // dispatch
  stageAppeal: typeof stageAppeal,
  resetDecisionOptions: typeof resetDecisionOptions,
  checkoutStagedAppeal: typeof checkoutStagedAppeal,
  setCaseReviewActionType: typeof setCaseReviewActionType,
  // withrouter
  history: Object
|};

class AttorneyActionsDropdown extends React.PureComponent<Props> {
  changeRoute = (props) => {
    const {
      appealId,
      history
    } = this.props;
    const decisionType = props.value;
    const routes = {
      omo_request: 'submit',
      draft_decision: 'dispositions',
      colocated_task: 'colocated_task'
    };
    const route = routes[decisionType];

    this.props.stageAppeal(appealId);

    this.props.resetDecisionOptions();
    this.props.setCaseReviewActionType(decisionType);

    history.push('');
    history.replace(`/queue/appeals/${appealId}/${route}`);
  };

  getOptions = () => {
    const { featureToggles } = this.props;

    if (featureToggles.attorney_assignment_to_colocated) {
      return [...DRAFT_DECISION_OPTIONS, {
        label: 'Add Colocated Task',
        value: 'colocated_task'
      }];
    }

    return DRAFT_DECISION_OPTIONS;
  }

  render = () => <SearchableDropdown
    name={`start-checkout-flow-${this.props.appealId}`}
    placeholder="Select an action&hellip;"
    options={this.getOptions()}
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
  checkoutStagedAppeal,
  stageAppeal
}, dispatch);

export default (withRouter(
  connect(mapStateToProps, mapDispatchToProps)(AttorneyActionsDropdown)
): React.ComponentType<Params>);
