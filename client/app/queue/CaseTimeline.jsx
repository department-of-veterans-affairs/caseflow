import React from 'react';
import PropTypes from 'prop-types';
import { useSelector } from 'react-redux';
import COPY from '../../COPY';
import TaskRows from './components/TaskRows';
import { caseTimelineTasksForAppeal } from './selectors';

export const CaseTimeline = ({ appeal }) => {
  const tasks = useSelector((state) => caseTimelineTasksForAppeal(state, { appealId: appeal.externalId }));
  const canEditNodDate = useSelector((state) => state.ui.canEditNodDate);

  return (
    <React.Fragment>
      {COPY.CASE_TIMELINE_HEADER}
      <table id="case-timeline-table" summary="layout table">
        <tbody>
          <TaskRows appeal={appeal}
            taskList={tasks}
            editNodDateEnabled={!appeal.isLegacyAppeal && canEditNodDate}
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
