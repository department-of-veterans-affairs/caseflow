import _ from 'lodash';

const IssuesUtil = {
  filterIssuesOnAppeal(issues, appealId) {
    return _(issues).
      omitBy('_destroy').
      pickBy({ appeal_id: appealId }).
      value();
  }
};

export default IssuesUtil;
