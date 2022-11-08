import React from 'react';
import PropTypes from 'prop-types';
import { useSelector } from 'react-redux';
import { getAllTasksForAppeal } from './selectors';
import moment from 'moment';
import { css } from 'glamor';
import COPY from './../../COPY';

const attorneyAssignedStyling = css({ width: '30%' });

const calculateDaysWorked = (tasks, daysAssigned) => {
  let sumOfDays = 0;
  for (var task in tasks) {
    let startTaskWork = moment(task.assignedOn);
    let endTaskWork = moment(task.closedAt);
    sumOfDays += startTaskWork.diff(endTaskWork, 'days');
    }
    return daysAssigned - sumOfDays; 
}

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
  daysWorked: PropTypes.number
};
