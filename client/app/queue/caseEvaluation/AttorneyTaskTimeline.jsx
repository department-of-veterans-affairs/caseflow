import React from 'react';
import PropTypes from 'prop-types';
import AttorneyTaskRows from './AttorneyTaskRows';
import { css } from 'glamor';

export const AttorneyTaskTimeline = ({ appeal, attorneyChildrenTasks }) => {
  const TimelineStyling = css({ margin: '1rem 0' });

  return (
    <React.Fragment>
      <table {...TimelineStyling} id="attorney-task-timeline-table" summary="attorney timeline table">
        <tbody>
          <AttorneyTaskRows appeal={appeal}
            taskList={attorneyChildrenTasks}
            timeline
          />
        </tbody>
      </table>
    </React.Fragment>
  );
};

AttorneyTaskTimeline.propTypes = {
  appeal: PropTypes.object,
  attorneyChildrenTasks: PropTypes.array,
};
