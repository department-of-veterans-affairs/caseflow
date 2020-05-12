import * as React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { css } from 'glamor';
import PropTypes from 'prop-types';

import QueueTableBuilder from './QueueTableBuilder';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';

import {
  newTasksByAssigneeCssIdSelector,
  onHoldTasksByAssigneeCssIdSelector,
  completeTasksByAssigneeCssIdSelector
} from './selectors';
import { hideSuccessMessage } from './uiReducer/uiActions';
import { clearCaseSelectSearch } from '../reader/CaseSelect/CaseSelectActions';
import {
  marginBottom
} from './constants';

import Alert from '../components/Alert';

const containerStyles = css({
  position: 'relative'
});

class ColocatedTaskListView extends React.PureComponent {
  componentDidMount = () => {
    this.props.clearCaseSelectSearch();
  };

  componentWillUnmount = () => this.props.hideSuccessMessage();

  render = () => {
    const { success } = this.props;

    return <AppSegment filledBackground styling={containerStyles}>
      {success && <Alert type="success" title={success.title} message={success.detail} styling={marginBottom(1)} />}
      <QueueTableBuilder
        assignedTasks={this.props.assignedTasks}
        onHoldTasks={this.props.onHoldTasks}
        completedTasks={this.props.completedTasks}
      />
    </AppSegment>;
  };
}

const mapStateToProps = (state) => {
  const { success } = state.ui.messages;

  return {
    success,
    assignedTasks: newTasksByAssigneeCssIdSelector(state),
    onHoldTasks: onHoldTasksByAssigneeCssIdSelector(state),
    completedTasks: completeTasksByAssigneeCssIdSelector(state)
  };
};

const mapDispatchToProps = (dispatch) => bindActionCreators({
  clearCaseSelectSearch,
  hideSuccessMessage
}, dispatch);

export default (connect(mapStateToProps, mapDispatchToProps)(ColocatedTaskListView));

ColocatedTaskListView.propTypes = {
  assignedTasks: PropTypes.array,
  clearCaseSelectSearch: PropTypes.func,
  completedTasks: PropTypes.array,
  hideSuccessMessage: PropTypes.func,
  onHoldTasks: PropTypes.array,
  success: PropTypes.object
};
