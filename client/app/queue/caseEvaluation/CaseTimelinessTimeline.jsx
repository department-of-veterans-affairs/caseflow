import React from 'react';
import PropTypes from 'prop-types';
import moment from 'moment';
import COPY from '../../../COPY';
import { AttorneyDaysWorked } from './AttorneyDaysWorked';
import { AttorneyTasksTreeTimeline } from './AttorneyTasksTreeTimeline';
import { LegacyCaseTimeline } from './LegacyCaseTimeline';

export const CaseTimelinessTimeline = (props) => {
  const { appeal,
    isLegacy,
    task,
    attorneyChildrenTasks,
    displayCaseTimelinessTimeline,
  } = props;

  let dateAssigned = moment(task.previousTaskAssignedOn);
  const decisionSubmitted = moment(task.assignedOn);

  // If DAS Case Timeline is enabled

  const caseType = task.caseType;
  const aod = task.aod;
  const cavc = caseType === 'Court Remand';
  let daysAssigned = Math.max(0, decisionSubmitted.diff(dateAssigned, 'days'));

  if (isLegacy) {
    if (displayCaseTimelinessTimeline) {
      return <LegacyCaseTimeline
        appeal={appeal}
        attorneyChildrenTasks={attorneyChildrenTasks}
        aod={aod}
        cavc={cavc}
        caseType={caseType}
        daysAssigned={daysAssigned}
        dateAssigned={dateAssigned}
        decisionSubmitted={decisionSubmitted}
      />;
    }

    // When feature toggle das_case_timeline is enabled for all and code cleanup is done remove this variable
    // and this return statement
    const daysWorked = Math.max(0, decisionSubmitted.startOf('day').diff(dateAssigned, 'days'));

    return (
      <>
        <b>{COPY.JUDGE_EVALUATE_DECISION_CASE_TIMELINESS_ASSIGNED_DATE}</b>: {dateAssigned.format('M/D/YY')}
        <br />
        <b>{COPY.JUDGE_EVALUATE_DECISION_CASE_TIMELINESS_SUBMITTED_DATE}</b>: {decisionSubmitted.format('M/D/YY')}
        <br />
        <b>{COPY.JUDGE_EVALUATE_DECISION_CASE_TIMELINESS_DAYS_WORKED}</b>&nbsp; (
        {COPY.JUDGE_EVALUATE_DECISION_CASE_TIMELINESS_DAYS_WORKED_ADDENDUM}): {daysWorked}
      </>
    );

  }

  const oldestAttorneyTask = attorneyChildrenTasks[0]?.attorneyTask;

  // If AMA use oldest attorney task and recalculate total days assigned
  dateAssigned = moment(oldestAttorneyTask?.createdAt);
  daysAssigned = Math.max(0, decisionSubmitted.startOf('day').diff(dateAssigned, 'days'));

  return (
    <div>
      <div className="case-timeline" >
        <AttorneyDaysWorked
          attorneyTasks={attorneyChildrenTasks}
          aod={aod}
          cavc={cavc}
          caseType={caseType}
          daysAssigned={daysAssigned} />
      </div>
      <br />
      {attorneyChildrenTasks.map((attorneyTaskTree, index) =>
        <AttorneyTasksTreeTimeline appeal={appeal} attorneyTaskTree={attorneyTaskTree} index={index} />
      )}
    </div>
  );
};

CaseTimelinessTimeline.propTypes = {
  appeal: PropTypes.object,
  task: PropTypes.object,
  displayCaseTimelinessQuestion: PropTypes.bool,
  attorneyChildrenTasks: PropTypes.array,
  displayCaseTimelinessTimeline: PropTypes.bool,
  isLegacy: PropTypes.bool,
};
