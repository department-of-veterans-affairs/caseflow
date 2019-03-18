import * as React from 'react';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import _ from 'lodash';
import { withRouter } from 'react-router-dom';

import SearchableDropdown from '../../components/SearchableDropdown';

import {
  resetDecisionOptions,
  stageAppeal
} from '../QueueActions';
import {
  dropdownStyling
} from '../constants';
import COPY from '../../../COPY.json';

class ActionsDropdown extends React.PureComponent {
  changeRoute = (option) => {
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

const mapStateToProps = (state, ownProps) => ({
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
));
