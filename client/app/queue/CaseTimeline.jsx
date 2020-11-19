import React from 'react';
import PropTypes from 'prop-types';
import { useDispatch, useSelector } from 'react-redux';
import COPY from '../../COPY';
import TaskRows from './components/TaskRows';
import { showSuccessMessage, resetSuccessMessages } from './uiReducer/uiActions';
import { caseTimelineTasksForAppeal } from './selectors';

export const CaseTimeline = ({ appeal }) => {
  const tasks = useSelector((state) => caseTimelineTasksForAppeal(state, { appealId: appeal.externalId }));
  const featureToggles = useSelector((state) => state.ui.featureToggles);
  const handleEditNodDateChange = () => {
    const dispatch = useDispatch();

    const successMessage = {
      title: COPY.EDIT_NOD_DATE_SUCCESS_ALERT_TITLE,
      detail: COPY.EDIT_NOD_DATE_SUCCESS_ALERT_MESSAGE,
    };

    dispatch(showSuccessMessage(successMessage));
    setTimeout(() => dispatch(resetSuccessMessages()), 5000);
  };

  return (
    <React.Fragment>
      {COPY.CASE_TIMELINE_HEADER}
      <table id="case-timeline-table" summary="layout table">
        <tbody>
          <TaskRows appeal={appeal}
            taskList={tasks}
            editNodDateEnabled={featureToggles?.editNodDate}
            onEditNodDateChange={handleEditNodDateChange}
            timeline
          />
        </tbody>
      </table>
    </React.Fragment>
  );
};

CaseTimeline.propTypes = {
  appeal: PropTypes.object
};
