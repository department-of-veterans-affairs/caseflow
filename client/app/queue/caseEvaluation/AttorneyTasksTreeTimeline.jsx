import React from 'react';
import moment from 'moment';
import COPY from '../../../COPY';
import PropTypes from 'prop-types';
import { AttorneyTaskTimeline } from './AttorneyTaskTimeline';

export const AttorneyTasksTreeTimeline = (props) => {
  const { appeal, attorneyTaskTree, index } = props;
  const { attorneyTask, childrenTasks } = attorneyTaskTree;
  const dateAssigned = moment(attorneyTask.createdAt);
  const dateClosed = moment(attorneyTask.closedAt);

  let displayString = COPY.JUDGE_EVALUATE_DECISION_CASE_TIMELINESS_ASSIGNED_DATE;

  if (attorneyTask.type === 'AttorneyRewriteTask') {
    displayString = COPY.JUDGE_EVALUATE_DECISION_CASE_TIMELINESS_REASSIGNED_DATE;
  }

  return (
    <div>
      {index > 0 && (<br />)}
      <span>{dateAssigned.format('M/D/YY')} - {displayString}</span>
      <AttorneyTaskTimeline title="Attorney Task Timeline"
        appeal={appeal}
        attorneyChildrenTasks={childrenTasks} />
      <span>
        {dateClosed.format('M/D/YY')} - {COPY.JUDGE_EVALUATE_DECISION_CASE_TIMELINESS_SUBMITTED_DATE}
      </span>
    </div>
  );
};

AttorneyTasksTreeTimeline.propTypes = {
  appeal: PropTypes.object,
  attorneyTaskTree: PropTypes.object,
  index: PropTypes.number,
};
