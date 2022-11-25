import React from 'react';
import PropTypes from 'prop-types';
import moment from 'moment';
import COPY from '../../../COPY';
import { redText } from '../constants';
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
  if (displayCaseTimelinessTimeline) {
    const caseType = task.caseType;
    const aod = task.aod;
    const cavc = caseType === 'Court Remand';
    let daysAssigned = decisionSubmitted.startOf('day').diff(dateAssigned, 'days');

    if (isLegacy) {
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

    const oldestAttorneyTask = attorneyChildrenTasks[0].attorneyTask;

    // If not legacy use oldest attorney task and recalculate total days assigned
    dateAssigned = moment(oldestAttorneyTask.createdAt);
    daysAssigned = decisionSubmitted.startOf('day').diff(dateAssigned, 'days');

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
            attorneyTasks={attorneyChildrenTasks}
            daysAssigned={daysAssigned} />
        </div>
        <br />
        {attorneyChildrenTasks.map((attorneyTaskTree, index) =>
          <AttorneyTasksTreeTimeline appeal={appeal} attorneyTaskTree={attorneyTaskTree} index={index} />
        )}
      </div>
    );

  }

  // When feature toggle das_case_timeline is enabled for all and code cleanup is done remove this variable
  // and this return statement
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
  appeal: PropTypes.object,
  task: PropTypes.object,
  displayCaseTimelinessQuestion: PropTypes.bool,
  attorneyChildrenTasks: PropTypes.array,
  displayCaseTimelinessTimeline: PropTypes.bool,
  isLegacy: PropTypes.bool,
};
