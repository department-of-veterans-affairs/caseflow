import React from 'react';
import PropTypes from 'prop-types';
import { connect, useDispatch } from 'react-redux';
import { caseTimelineTasksForAppeal } from './selectors';
import COPY from '../../COPY';
import TaskRows from './components/TaskRows';
import { showSuccessMessage, resetSuccessMessages } from './uiReducer/uiActions';

function CaseTimeline (props) {
  const handleEditNodDateChange = () => {
    const {
      appeal,
      tasks
    } = props;

    const dispatch = useDispatch();

    const successMessage = {
      title: COPY.EDIT_NOD_DATE_SUCCESS_ALERT_TITLE,
      detail: COPY.EDIT_NOD_DATE_SUCCESS_ALERT_MESSAGE,
    };

    dispatch(showSuccessMessage(successMessage));
    setTimeout(() => dispatch(resetSuccessMessages()), 5000);
  }

  return (
    <React.Fragment>
      {COPY.CASE_TIMELINE_HEADER}
      <table id="case-timeline-table" summary="layout table">
        <tbody>
          <TaskRows appeal={appeal}
            taskList={tasks}
            editNodDateEnabled={this.props.featureToggles?.editNodDate}
            onEditNodDateChange={this.handleEditNodDateChange}
            timeline
          />
        </tbody>
      </table>
    </React.Fragment>
  );
}

CaseTimeline.propTypes = {
  appeal: PropTypes.object,
  tasks: PropTypes.array,
  featureToggles: PropTypes.object
};

const mapStateToProps = (state, ownProps) => {
  return {
    tasks: caseTimelineTasksForAppeal(state, { appealId: ownProps.appeal.externalId }),
    featureToggles: state.ui.featureToggles
  };
};

export default connect(mapStateToProps)(CaseTimeline);
