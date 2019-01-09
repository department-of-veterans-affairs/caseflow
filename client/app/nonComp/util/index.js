import { FORM_TYPES } from '../../intake/constants';
import _ from 'lodash';

export const formatTasks = (serverTasks) => {
  return (serverTasks || []).map((task) => {
    return {
      ...task,
      assignedOn: task.assigned_on,
      veteranParticipantId: task.veteran_participant_id
    };
  });
};

export const longFormNameFromShort = (shortFormName) => {
  return _.find(FORM_TYPES, { shortName: shortFormName }).name;
};

export const formatDecisionIssuesFromRequestIssues = (requestIssues) => {
  const decisionIssues = requestIssues.map((requestIssue) => {
    let formmatedDecisionIssue =  {
      request_issue_id: requestIssue.id,
      disposition: requestIssue.decisionIssue.disposition,
    }

    if (requestIssue.decisionIssue.description) {
      formmatedDecisionIssue.description = requestIssue.decisionIssue.description;
    }

    return formmatedDecisionIssue;
  });

  return {decision_issues: decisionIssues};
}

export const formatRequestIssuesWithDecisionIssues = (requestIssues, decisionIssues) => {
  return requestIssues.map((requestIssue) => {
    const foundDecisionIssue = decisionIssues.find((decisionIssue) => decisionIssue.requestIssueId === requestIssue.id) || {};
    return {
      decisionIssue: foundDecisionIssue,
      ...requestIssue
    }
  });
}
