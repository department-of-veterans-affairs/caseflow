import _ from 'lodash';

const IssuesUtil = {
  filterIssuesOnAppeal(issues, appealId) {
    return _.pickBy(issues, (issue) => {
      // eslint-disable-next-line no-underscore-dangle
      return !issue._destroy && issue.appeal_id === appealId;
    });
  }
};

export default IssuesUtil;
