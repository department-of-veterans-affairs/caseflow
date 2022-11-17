import React from 'react';
import PropTypes from 'prop-types';
import Moment from 'moment';
import { extendMoment } from 'moment-range';

import { css } from 'glamor';
import COPY from '../../../COPY';

const moment = extendMoment(Moment);

const attorneyAssignedStyling = css({ width: '30%' });

const isSameRange = (rangeA, rangeB) => {
  return rangeA.start.isSame(rangeB.start, 'day') && rangeA.end.isSame(rangeB.end, 'day');
};

const calculateDaysWorked = (tasks, daysAssigned) => {
  let sumOfDays = 0;

  // Map all tasks' createdAt to closedAt to a moment.range object
  const dateRanges = tasks.map((task) => moment.range(moment(task.createdAt), moment(task.closedAt)));

  const uniqueDateRanges = [];
  const alreadyAccountedForDateRanges = [];

  // For all tasks' date ranges find overlapping date ranges
  dateRanges.forEach((dateRange) => {

    // If a date range was already found to be overlapping do not create another combined overlapping date range
    if (alreadyAccountedForDateRanges.findIndex((range) => isSameRange(dateRange, range)) < 0) {

      // Find all overlapping date ranges
      const overlappingDateRanges = dateRanges.filter((range) => dateRange.overlaps(range, { adjacent: true }));

      // Track used date ranges so they are not used again
      alreadyAccountedForDateRanges.push(...overlappingDateRanges);

      // Add all overlapping date ranges together
      let overlappingDateRange = dateRange.clone();

      overlappingDateRanges.forEach((range) => {
        overlappingDateRange = overlappingDateRange.add(range, { adjacent: true });
      });

      uniqueDateRanges.push(overlappingDateRange);
    }
  });

  uniqueDateRanges.forEach((range) => {
    sumOfDays += Math.max(1, range.diff('days'));
  });

  return daysAssigned - Math.max(1, sumOfDays) - 1;
};

export const AttorneyDaysWorked = ({ attorneyTasks, daysAssigned }) => {
  const daysWorkedUpdated = calculateDaysWorked(attorneyTasks, daysAssigned);

  return (
    <React.Fragment>
      <span {...attorneyAssignedStyling}>
        <b>{COPY.JUDGE_EVALUATE_DECISION_CASE_TIMELINESS_TOTAL_DAYS_ATTORNEY_ASSIGNED}</b>: {daysAssigned}
      </span>
      <span>
        <b>{COPY.JUDGE_EVALUATE_DECISION_CASE_TIMELINESS_DAYS_WORKED}</b>: {daysWorkedUpdated}
      </span>
    </React.Fragment>
  );
};

AttorneyDaysWorked.propTypes = {
  appeal: PropTypes.object,
  daysAssigned: PropTypes.number,
  daysWorked: PropTypes.number,
  attorneyTasks: PropTypes.array
};
