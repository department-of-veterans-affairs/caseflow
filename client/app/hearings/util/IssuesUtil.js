import _ from 'lodash';

export const filterIssuesOnAppeal = (issues, appealId) =>
  _(issues).
    omitBy('_destroy').
    pickBy({ appeal_id: appealId }).
    value();

export const currentIssues = (issues) => {
  return _.omitBy(issues, (issue) => {
    /* eslint-disable no-underscore-dangle */
    return issue._destroy || (issue.disposition && !issue.disposition.includes('Remand') && issue.from_vacols);
    /* eslint-enable no-underscore-dangle */
  });
};

export const priorIssues = (issues) => (
  _.pickBy(issues, (issue) => (
    /* eslint-disable no-underscore-dangle */
    !issue._destroy && issue.disposition && !issue.disposition.includes('Remand') && issue.from_vacols
    /* eslint-enable no-underscore-dangle */
  ))
);
