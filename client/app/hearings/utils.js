import HEARING_DISPOSITION_TYPES from '../../constants/HEARING_DISPOSITION_TYPES.json';
import moment from 'moment';
import _ from 'lodash';

export const isPreviouslyScheduledHearing = (hearing) => (
  hearing.disposition === HEARING_DISPOSITION_TYPES.postponed ||
    hearing.disposition === HEARING_DISPOSITION_TYPES.cancelled
);

export const now = () => {
  return moment().tz(moment.tz.guess()).
    format('h:mm a');
};

export const getWorksheetAppealsAndIssues = (worksheet) => {
  const worksheetAppeals = _.keyBy(worksheet.appeals_ready_for_hearing, 'id');
  let worksheetIssues = _(worksheetAppeals).flatMap('worksheet_issues').
    keyBy('id').
    value();

  if (_.isEmpty(worksheetIssues)) {
    worksheetIssues = _.keyBy(worksheet_issues, 'id');
  }

  const worksheetWithoutAppeals = _.omit(worksheet, ['appeals_ready_for_hearing']);

  return {
    worksheet: worksheetWithoutAppeals,
    worksheetAppeals,
    worksheetIssues
  };
};

export const sortHearings = (hearings) => (
  _.orderBy(Object.values(hearings || {}), (hearing) => hearing.scheduledFor, 'asc')
);

export const filterIssuesOnAppeal = (issues, appealId) => (
  _(issues).omitBy('_destroy').
    pickBy({ appeal_id: appealId }).
    value()
);

export const filterCurrentIssues = (issues) => (
  _.omitBy(issues, (issue) => (
    // Omit if destroyed, or HAS NON-REMAND DISPOSITION FROM VACOLS
    /* eslint-disable no-underscore-dangle */
    issue._destroy || (issue.disposition && !issue.disposition.includes('Remand') && issue.from_vacols)
    /* eslint-enable no-underscore-dangle */
  ))
);

export const filterPriorIssues = (issues) => (
  _.pickBy(issues, (issue) => (
    /* eslint-disable no-underscore-dangle */
    !issue._destroy && issue.disposition && !issue.disposition.includes('Remand') && issue.from_vacols
    /* eslint-enable no-underscore-dangle */
  ))
);
