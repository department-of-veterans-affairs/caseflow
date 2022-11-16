import React from 'react';
import PropTypes from 'prop-types';
import moment from 'moment';
import { css } from 'glamor';
import COPY from '../../../COPY';

const attorneyAssignedStyling = css({ width: '30%' });

const dateString = (date) => moment(date).format('MM/DD/YYYY');

const calculateDaysWorked = (tasks, daysAssigned) => {
  // Reduce down to all unique date ranges for the case when tasks are worked in parallel
  const uniqueDateRanges = [
    ...new Map(tasks.map((task) => [dateString(task.createdAt) + dateString(task.closedAt), task])).values(),
  ];

  let sumOfDays = 0;

  uniqueDateRanges.forEach((task) => {
    const startTaskWork = moment(task.createdAt);
    let endTaskWork = moment();

    if (task.closedAt) {
      endTaskWork = moment(task.closedAt);
    }
    sumOfDays += Math.max(1, endTaskWork.startOf('day').diff(startTaskWork, 'days'));
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
