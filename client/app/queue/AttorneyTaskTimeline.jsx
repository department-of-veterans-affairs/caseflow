import React from 'react';
import PropTypes from 'prop-types';
import { useSelector } from 'react-redux';
import AttorneyTaskRows from './components/AttorneyTaskRows';
import { getAllTasksForAppeal } from './selectors';


export const AttorneyTaskTimeline = ({ appeal }) => {
  const tasks = useSelector((state) => getAllTasksForAppeal(state, { appealId: appeal.externalId }));
  const canEditNodDate = useSelector((state) => state.ui.canEditNodDate);

  return (
    <React.Fragment>
      <table id="attorney-task-timeline-table" summary="attorney timeline table">
        <tbody>
          <AttorneyTaskRows appeal={appeal}
            taskList={tasks}
            timeline
          />
        </tbody>
      </table>
    </React.Fragment>
  );
};

AttorneyTaskTimeline.propTypes = {
  appeal: PropTypes.object
};
