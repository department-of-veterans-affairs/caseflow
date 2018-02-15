import _ from 'lodash';

export const filterIssuesOnAppeal = (issues, appealId) =>
  _(issues).
    omitBy('_destroy').
    pickBy({ appeal_id: appealId }).
    value();

export const currentIssues = (issues) => {
  return _.omitBy(issues, (issue) => {
    return issue._destroy || (issue.disposition && !issue.disposition.includes('Remand'));
  });
};

export const priorIssues = (issues) => {
  return _.pickBy(issues, (issue) => {
    return !issue._destroy && issue.disposition && !issue.disposition.includes('Remand');
  });
};
