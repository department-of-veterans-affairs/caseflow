import * as React from 'react';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import _ from 'lodash';
import { withRouter } from 'react-router-dom';
import PropTypes from 'prop-types';

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

    return <SearchableDropdown
      name={`start-checkout-flow-${this.props.appealId}-${this.props.task.uniqueId}`}
      placeholder={COPY.TASK_ACTION_DROPDOWN_BOX_LABEL}
      options={this.props.task.availableActions}
      onChange={this.changeRoute}
      hideLabel
      dropdownStyling={dropdownStyling} />;
  }
}

ActionsDropdown.propTypes = {
  appealId: PropTypes.string,
  task: PropTypes.object,
  history: PropTypes.func,
  resetDecisionOptions: PropTypes.func,
  stageAppeal: PropTypes.func
};

const mapStateToProps = (state, ownProps) => ({
  appeal: state.queue.appeals[ownProps.appealId],
  changedAppeals: _.keys(state.queue.stagedChanges.appeals)
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  resetDecisionOptions,
  stageAppeal
}, dispatch);

export default (withRouter(
  connect(mapStateToProps, mapDispatchToProps)(ActionsDropdown)
));
