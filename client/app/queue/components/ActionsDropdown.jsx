import * as React from 'react';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import _ from 'lodash';
import { withRouter } from 'react-router-dom';
import PropTypes from 'prop-types';
import { setScheduledHearing } from '../../components/common/actions';

import SearchableDropdown from '../../components/SearchableDropdown';
import TASK_ACTIONS from '../../../constants/TASK_ACTIONS';

import {
  resetDecisionOptions,
  stageAppeal
} from '../QueueActions';
import {
  dropdownStyling
} from '../constants';
import COPY from '../../../COPY';

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

    if (option.value === TASK_ACTIONS.SCHEDULE_VETERAN_V2_PAGE.value) {
      this.props.setScheduledHearing({
        taskId: task.uniqueId,
        action: 'schedule'
      });
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
      name="Available actions"
      id={{`start-checkout-flow-${this.props.appealId}-${this.props.task.uniqueId}`}}
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
  history: PropTypes.object,
  resetDecisionOptions: PropTypes.func,
  setScheduledHearing: PropTypes.func,
  stageAppeal: PropTypes.func
};

const mapStateToProps = (state, ownProps) => ({
  appeal: state.queue.appeals[ownProps.appealId],
  changedAppeals: _.keys(state.queue.stagedChanges.appeals)
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  setScheduledHearing,
  resetDecisionOptions,
  stageAppeal
}, dispatch);

export default (withRouter(
  connect(mapStateToProps, mapDispatchToProps)(ActionsDropdown)
));
