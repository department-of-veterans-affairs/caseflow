import _ from 'lodash';
import { formatDateStringForApi } from '../../util/DateUtil';

export const formatRatings = (ratings, requestIssues = []) => {
  const result = _.keyBy(_.map(ratings, (rating) => {
    return _.assign(rating,
      { issues: _.keyBy(rating.issues, 'reference_id') }
    );
  }), 'profile_date');

  _.forEach(requestIssues, (requestIssue) => {
    // filter out nil dates (request issues that are not yet rated)
    if (requestIssue.reference_id) {
      _.forEach(result, (rating) => {
        if (rating.issues[requestIssue.reference_id]) {
          rating.issues[requestIssue.reference_id].isSelected = true;
        }
      });
    }
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

const formatRatedIssues = (state) => {
  if (state.addedIssues && state.addedIssues.length > 0) {
    // we're using the new add issues page
    return state.addedIssues.
      filter((issue) => issue.isRated).
      map((issue) => {
        let originalIssue = state.ratings[issue.profileDate].issues[issue.id];

        return _.merge(originalIssue, { profile_date: issue.profileDate,
          notes: issue.notes });
      });
  }

  // default to original ratings format
  return _(state.ratings).
    map((rating) => {
      return _.map(rating.issues, (issue) => {
        return _.merge(issue, { profile_date: rating.profile_date });
      });
    }).
    flatten().
    filter('isSelected').
    value();
};

const formatNonRatedIssues = (state) => {
  if (state.addedIssues && state.addedIssues.length > 0) {
    // we're using the new add issues page
    console.log(state.addedIssues)
    // return state.addedIssues.
    //   filter((issue)) => !issue.isRated).
    //   map((issue) => {
    //     console.log(issue)
    //   })
    // return state.addedIssues.
    //   filter((issue) => !issue.isRated).
    //   map((issue) => {
    //     return {
    //       category: issue.category,
    //       description: issue.description,
    //       decisionDate: issue.decisionDate
    //      });
    //    }
  };

  // default to original format
  // return _(state.nonRatedIssues).
  //   filter((issue) => {
  //     return validNonRatedIssue(issue);
  //   }).
  //   map((issue) => {
  //     return {
  //       decision_text: issue.description,
  //       issue_category: issue.category,
  //       decision_date: formatDateStringForApi(issue.decisionDate)
  //     };
  //   }).value()
};

export const formatIssues = (state) => {
  const ratingData = formatRatedIssues(state);
  const nonRatingData = formatNonRatedIssues(state);

  const data = {
    request_issues: _.concat(ratingData, nonRatingData)
  };

  return data;
};

// Returns a list of selected issues in the form of date:issueId
// Useful for dirty checking, rather than deeply comparing two state objects
export const getSelection = (ratings) => {
  const dates = Object.keys(ratings);

  return dates.reduce((selectedIssues, date) => {
    const issueIds = Object.keys(ratings[date].issues);

    issueIds.forEach((issueId) => {
      if (ratings[date].issues[issueId].isSelected) {
        selectedIssues.push(`${date}:${issueId}`);
      }
    });

    return selectedIssues;
  }, []);
};
