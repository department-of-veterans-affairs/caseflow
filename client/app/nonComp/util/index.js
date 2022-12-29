import _ from 'lodash';

import { FORM_TYPES } from '../../intake/constants';

export const formatTasks = (serverTasks) => {
  return (serverTasks || []).map((task) => {
    return {
      ...task,
      assignedOn: task.assigned_on,
      closedAt: task.closed_at,
      veteranParticipantId: task.veteran_participant_id
    };
  });
};

export const longFormNameFromKey = (formNameKey) => {
  return _.find(FORM_TYPES, { key: formNameKey }).name;
};

export const formatDecisionIssuesFromRequestIssues = (requestIssues) => {
  return requestIssues.map((requestIssue) => {
    let formmatedDecisionIssue = {
      request_issue_id: requestIssue.id,
      disposition: requestIssue.decisionIssue.disposition
    };

    if (!_.isEmpty(requestIssue.decisionIssue.description)) {
      formmatedDecisionIssue.description = requestIssue.decisionIssue.description;
    }

    return formmatedDecisionIssue;
  });
};

export const formatRequestIssuesWithDecisionIssues = (requestIssues, decisionIssues) => {
  return requestIssues.map((requestIssue) => {
    const foundDecisionIssue = decisionIssues.find((decisionIssue) =>
      decisionIssue.requestIssueId === requestIssue.id) || {};

    return {
      decisionIssue: foundDecisionIssue,
      ...requestIssue
    };
  });
};

export const buildDispositionSubmission = (decisionIssues, decisionDate) => {
  return { data:
    {
      decision_issues: decisionIssues,
      decision_date: decisionDate
    }
  };
};

const parseDecisionReviewTypeFilterOptions = (taskCounts) =>
  Object.entries(taskCounts).map(([key, taskCount]) => {
    let taskInfo;

    if (key.includes('HigherLevelReview')) {
      taskInfo = {
        value: 'HigherLevelReview',
        displayText: `Higher Level Review (${taskCount})`
      };
    } else if (key.includes('SupplementalClaim')) {
      taskInfo = {
        value: 'SupplementalClaim',
        displayText: `Supplemental Claim (${taskCount})`
      };
    } else if (key.includes('VeteranRecordRequest')) {
      taskInfo = {
        value: 'VeteranRecordRequest',
        displayText: `Record Request (${taskCount})`
      };
    } else if (key.includes('BoardGrantEffectuationTask')) {
      taskInfo = {
        value: 'BoardGrantEffectuationTask',
        displayText: `Board Grant (${taskCount})`
      };
    }

    return { ...taskInfo, checked: false };
  });

export const buildDecisionReviewFilterInformation = (taskCounts) => {
  return {
    searchable: true,
    columnName: 'searchable',
    name: 'decisionReviewType',
    filterOptions: parseDecisionReviewTypeFilterOptions(taskCounts)
  };
};
