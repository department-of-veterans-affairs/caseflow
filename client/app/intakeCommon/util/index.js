import _ from 'lodash';
import { formatDateStringForApi } from '../../util/DateUtil';

export const formatRatings = (ratings, requestIssues = []) => {
  const result = _.keyBy(_.map(ratings, (rating) => {
    return _.assign(rating,
      { issues: _.keyBy(rating.issues, 'reference_id') }
    );
  }), 'profile_date');

  _.forEach(requestIssues, (requestIssue) => {
    result[requestIssue.profile_date].issues[requestIssue.reference_id].isSelected = true;
  });

  return result;
};

export const validateDate = (date) => {
  const datePattern = /^(0[1-9]|1[0-2])[/](0[1-9]|[12][0-9]|3[01])[/](19|20)\d\d$/;

  if (datePattern.test(date)) {
    return date;
  }

  return null;
};

export const validNonRatedIssue = (issue) => {
  const unvalidatedDate = issue.decisionDate;
  const decisionDate = validateDate(unvalidatedDate);

  if (!issue.description) {
    return false;
  }
  // If there isn't any nonRated category, return 0
  if (!issue.category) {
    return false;
  }
  // If category is unknown issue category, no decision date is necessary.
  if (issue.category === 'Unknown issue category') {
    return true;
  }
  // If category isn't unknown or there's no valid decisionDate, return 0
  if (!decisionDate) {
    return false;
  }

  // If we've gotten to here, that means we've got all necessary parts for a nonRatedIssue to count
  return true;
};

export const formatIssues = (state) => {
  const ratingData = {
    request_issues:
      _(state.ratings).
        map((rating) => {
          return _.map(rating.issues, (issue) => {
            return _.merge(issue, { profile_date: rating.profile_date });
          });
        }).
        flatten().
        filter('isSelected')
  };

  const nonRatingData = {
    request_issues:
      _(state.nonRatedIssues).
        filter((issue) => {
          return validNonRatedIssue(issue);
        }).
        map((issue) => {
          return {
            decision_text: issue.description,
            issue_category: issue.category,
            decision_date: formatDateStringForApi(issue.decisionDate)
          };
        })
  };

  const data = {
    request_issues: _.concat(ratingData.request_issues.value(), nonRatingData.request_issues.value())
  };

  return data;
};
