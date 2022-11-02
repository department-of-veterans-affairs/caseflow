import React from 'react';
import PropTypes from 'prop-types';
import { useSelector } from 'react-redux';
import AttorneyTaskRows from './components/AttorneyTaskRows';
import { getAllTasksForAppeal } from './selectors';
import { css } from 'glamor';


export const AttorneyTaskTimeline = ({ appeal }) => {
  const tasks = useSelector((state) => getAllTasksForAppeal(state, { appealId: appeal.externalId }));
  const TimelineStyling = css({ margin: '1rem 0' });

  return (
    <React.Fragment>
      <table {...TimelineStyling} id="attorney-task-timeline-table" summary="attorney timeline table">
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
