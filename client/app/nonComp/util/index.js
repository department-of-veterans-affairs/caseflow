import _ from 'lodash';

import { FORM_TYPES } from '../../intake/constants';

export const formatTasks = (serverTasks) => {
  return (serverTasks || []).map((task) => {
    return {
      ...task,
      assignedOn: task.assigned_on,
      closedAt: task.closed_at,
      veteranParticipantId: task.veteran_participant_id,
      veteranSSN: task.veteran_ssn
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

/**
 * If decisionReviewType column filter is present, extracts the tasks currently selected
 * to be displayed in a decision review queue.
 * @param {Array} filters - All of the filters, for all columns, enabled in the queue
 *   Sample input: 'col=decisionReviewType&val=VeteranRecordRequest|HigherLevelReview'
 * @returns {Array} - Returns an array of strings representing the tasks to display in the DR queue OR an empty array.
 */
export const extractEnabledTaskFilters = (filters) => {
  if (filters) {
    const taskFilters = filters?.find((entry) => entry.includes('decisionReviewType'));

    if (taskFilters) {
      return taskFilters.
        split('val=').
        pop().
        split('|');
    }
  }

  return [];
};

/**
 * Creates the filter options that will be available in the Type column of decision review queues.
 * @param {Object} taskCounts - An object where the keys are the types of tasks in the business line's queue,
 *   and the values are the number of each type.
 * @param {Array} enabledFilters - An array of strings (can be empty) containing tasks selected for filtration.
 * @returns {Array} - Returns an array of objects, one for each type of task in the queue, that contains the
 *   task type's value, the display value for the filter menu that includes the (example: "Higher-Level Review (123)")
 *   quantities of each task, and whether or not the filter is enabled (checked).
 */
const parseDecisionReviewTypeFilterOptions = (taskCounts, enabledFilters) =>
  Object.entries(taskCounts).map(([key, taskCount]) => {
    let taskInfo;

    if (key.includes('HigherLevelReview')) {
      taskInfo = {
        value: 'HigherLevelReview',
        displayText: `Higher-Level Review (${taskCount})`
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

    return { ...taskInfo, checked: enabledFilters?.includes(taskInfo.value) || false };
  });

/**
 * Generates the filtration information, such as tasks available to filter by, and column metadata
 *   that pertains to the decisionReviewType column in decision review queues.
 * @param {Object} taskCounts - An object where the keys are the types of tasks in the business line's queue,
 *   and the values are the number of each type.
 *   Example:
 *     ["BoardGrantEffectuationTask", "Appeal"]: 6,
 *     ["DecisionReviewTask", "HigherLevelReview"]: 330,
 *     ["DecisionReviewTask", "SupplementalClaim"]: 1,
 *     ["VeteranRecordRequest", "Appeal"]: 51
 * @returns {Object} - Returns an object containing the filter information for the decisionReviewType column.
 */
export const buildDecisionReviewFilterInformation = (taskCounts) => {
  return {
    type: true,
    columnName: 'type',
    name: 'decisionReviewType',
    filterOptions: parseDecisionReviewTypeFilterOptions(taskCounts)
  };
};
