import _ from 'lodash';

import { formatDateStringForApi } from '../../util/DateUtil';

export const formatTasks = (serverTasks) => {
  return (serverTasks || []).map((task) => {
    return {
      ...task,
      assignedOn: task.assigned_on,
      veteranParticipantId: task.veteran_participant_id
    };
  });
};

const formatDecisionIssuesFromRequestIssues = (requestIssues) => {
  return requestIssues.map((requestIssue) => {
    let formmatedDecisionIssue =  {
      request_issue_id: requestIssue.id,
      disposition: requestIssue.decisionIssue.disposition,
    }

    if (!_.isEmpty(requestIssue.decisionIssue.description)) {
      formmatedDecisionIssue.description = requestIssue.decisionIssue.description;
    }

    return formmatedDecisionIssue;
  });
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

export const buildDispositionSubmission = (dispositionIssues, decisionDate) => {
  return { data:
    {
      decision_issues: decisionIssues,
      decision_date: formatDateStringForApi(decisionDate)
    }
  }
}
