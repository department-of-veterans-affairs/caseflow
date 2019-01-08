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
    return {
      request_issue_id: requestIssue.id,
      description: requestIssue.decisionIssue.description,
      disposition: requestIssue.decisionIssue.disposition,
    }
  });

  return {decision_issues: decisionIssues};
}
