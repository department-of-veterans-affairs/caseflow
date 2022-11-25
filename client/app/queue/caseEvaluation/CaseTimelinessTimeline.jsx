import React from 'react';
import PropTypes from 'prop-types';
import moment from 'moment';
import COPY from '../../../COPY';
import { redText } from '../constants';
import { AttorneyTaskTimeline } from './AttorneyTaskTimeline';
import { AttorneyDaysWorked } from './AttorneyDaysWorked';
import { AttorneyTasksTreeTimeline } from './AttorneyTasksTreeTimeline';

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
  if (displayCaseTimelinessTimeline) {
    const caseType = task.caseType;
    const aod = task.aod;
    const cavc = caseType === 'Court Remand';
    let daysAssigned = decisionSubmitted.startOf('day').diff(dateAssigned, 'days') + 1;

    if (isLegacy) {
      return (
        <>
          <div className="case-timeline" >
            <span className="case-type">
              <b>{COPY.JUDGE_EVALUATE_DECISION_CASE_TIMELINESS_CASE_TYPE}</b>:
              { aod && <span {...redText}> AOD</span> }
              { cavc && <span {...redText}> CAVC</span> }
              { !aod && !cavc && <span> {caseType}</span> }
            </span>
            <AttorneyDaysWorked
              attorneyTasks={attorneyChildrenTasks}
              daysAssigned={daysAssigned} />
          </div>
          <br />
          <span>{dateAssigned.format('M/D/YY')} - {COPY.JUDGE_EVALUATE_DECISION_CASE_TIMELINESS_ASSIGNED_DATE}</span>
          <AttorneyTaskTimeline title="Attorney Task Timeline"
            appeal={appeal}
            attorneyChildrenTasks={attorneyChildrenTasks} />
          <span>
            {decisionSubmitted.format('M/D/YY')} - {COPY.JUDGE_EVALUATE_DECISION_CASE_TIMELINESS_SUBMITTED_DATE}
          </span>
        </>
      );
    }

    const oldestAttorneyTask = attorneyChildrenTasks[0].attorneyTask;

    // If not legacy use oldest attorney task and recalculate total days assigned
    dateAssigned = moment(oldestAttorneyTask.createdAt);
    daysAssigned = decisionSubmitted.startOf('day').diff(dateAssigned, 'days') + 1;
    const allChildrenTasks = [];

    attorneyChildrenTasks.forEach((attorneyTaskTree) => allChildrenTasks.push(...attorneyTaskTree.childrenTasks));

    return (
      <div>
        <div className="case-timeline" >
          <span className="case-type">
            <b>{COPY.JUDGE_EVALUATE_DECISION_CASE_TIMELINESS_CASE_TYPE}</b>:
            { aod && <span {...redText}> AOD</span> }
            { cavc && <span {...redText}> CAVC</span> }
            { !aod && !cavc && <span> {caseType}</span> }
          </span>
          <AttorneyDaysWorked
            attorneyTasks={allChildrenTasks}
            daysAssigned={daysAssigned} />
        </div>
        <br />
        {attorneyChildrenTasks.map((attorneyTaskTree, index) =>
          <AttorneyTasksTreeTimeline appeal={appeal} attorneyTaskTree={attorneyTaskTree} index={index} />
        )}
      </div>
    );

  }

  const daysWorked = decisionSubmitted.startOf('day').diff(dateAssigned, 'days');

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
};

CaseTimelinessTimeline.propTypes = {
  appealId: PropTypes.string.isRequired,
  appeal: PropTypes.object,
  task: PropTypes.object,
  taskId: PropTypes.string,
  displayCaseTimelinessQuestion: PropTypes.bool,
  oldestAttorneyTask: PropTypes.object,
  attorneyChildrenTasks: PropTypes.array,
  displayCaseTimelinessTimeline: PropTypes.bool,
  isLegacy: PropTypes.bool,
};
