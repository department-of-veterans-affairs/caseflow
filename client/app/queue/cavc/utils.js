import * as yup from 'yup';
import StringUtil from 'app/util/StringUtil';
import { format, isDate, max, parseISO } from 'date-fns';

import { CAVC_ALL_ISSUES_ERROR, CAVC_DECISION_DATE_PAST, CAVC_DECISION_DATE_ERROR,
  CAVC_JUDGEMENT_DATE_ERROR, CAVC_JUDGEMENT_DATE_PAST,
  CAVC_MANDATE_DATE_ERROR, CAVC_MANDATE_DATE_PAST, CAVC_NO_ISSUES_ERROR } from 'app/../COPY';
import CAVC_JUDGE_FULL_NAMES from 'constants/CAVC_JUDGE_FULL_NAMES';
import CAVC_REMAND_SUBTYPES from 'constants/CAVC_REMAND_SUBTYPES';
import CAVC_REMAND_SUBTYPE_NAMES from 'constants/CAVC_REMAND_SUBTYPE_NAMES';
import CAVC_DECISION_TYPES from 'constants/CAVC_DECISION_TYPES';
import { SUBSTITUTE_DATE_ERRORS } from '../../intake/constants';

export const allDecisionTypeOpts = Object.values(CAVC_DECISION_TYPES).map(
  (value) => ({
    displayText: StringUtil.snakeCaseToCapitalized(value),
    value,
  })
);
export const allRemandTypeOpts = Object.entries(CAVC_REMAND_SUBTYPE_NAMES).map(
  ([value, displayText]) => ({
    displayText,
    value,
  })
);

export const generateSchema = ({ maxIssues, nodDate, dateOfDeath }) => {
  const dates = [nodDate, dateOfDeath].filter(Boolean).map((d) => (isDate(d) ? d : parseISO(d)));
  const requireValidDate = yup.
    date().
    min(new Date(2018, 0, 1)).
    max(new Date()).
    required();

  return yup.object().shape({
    docketNumber: yup.
      string().
      // We accept ‐ HYPHEN, - Hyphen-minus, − MINUS SIGN, – EN DASH, — EM DASH
      matches(/^\d{2}[-‐−–—]\d{1,5}$/).
      required(),
    substitutionDate: yup.mixed().when('isAppellantSubstituted', {
      is: 'true',
      then: yup.date().typeError(SUBSTITUTE_DATE_ERRORS.invalid).
        min(
          new Date(max(dates)),
          SUBSTITUTE_DATE_ERRORS.min_date_error +
          ` - ${format(new Date(max(dates)), 'MM/dd/yyyy')}.`
        ).
        max(new Date(), SUBSTITUTE_DATE_ERRORS.in_future).
        required(SUBSTITUTE_DATE_ERRORS.invalid)
    }),
    participantId: yup.mixed().when('isAppellantSubstituted', {
      is: 'true',
      then: yup.
        string().
        required('Please select a substitute claimants.'),
    }),
    attorney: yup.
      string().
      // mixed().
      // oneOf(YesNoOpts.map((opt) => opt.value), 'You must choose either "Yes" or "No"').
      required('This is a required field'),
    judge: yup.
      mixed().
      oneOf(CAVC_JUDGE_FULL_NAMES).
      required(),
    decisionType: yup.
      string().
      oneOf(
        allDecisionTypeOpts.map((opt) => opt.value),
        'You must choose one of the specified types'
      ).
      required(),
    remandType: yup.string().when('decisionType', {
      is: 'remand',
      then: yup.
        string().
        required('Please specify the type of remand').
        oneOf(allRemandTypeOpts.map((opt) => opt.value)),
    }),
    remandDatesProvided: yup.string().when('decisionType', {
      is: (val) => val !== 'remand',
      then: yup.string().required('Choose one'),
    }),
    decisionDate: yup.
      date().
      min(new Date(2018, 0, 1), CAVC_DECISION_DATE_PAST).
      max(new Date(), CAVC_DECISION_DATE_ERROR).
      required(),
    // EditCavcTodo: remove if not needed; see remandDatesProvided
    mandateSame: yup.boolean(),
    judgementDate: yup.mixed().when('remandDatesProvided', {
      is: 'yes',
      then: requireValidDate,
    }),
    mandateDate: yup.mixed().when('remandDatesProvided', {
      is: 'yes',
      then: requireValidDate,
    }),
    issueIds: yup.
      array().
      of(yup.string()).
      when('remandType', {
        is: 'jmr',
        then: yup.array().length(maxIssues, CAVC_ALL_ISSUES_ERROR),
        otherwise: yup.array().min(1, CAVC_NO_ISSUES_ERROR),
      }),
    federalCircuit: yup.boolean(),
    instructions: yup.string().required(),
  });
};

const errorMessages = {
  judgementDate: {
    min: CAVC_JUDGEMENT_DATE_PAST,
    max: CAVC_JUDGEMENT_DATE_ERROR
  },
  mandateDate: {
    min: CAVC_MANDATE_DATE_PAST,
    max: CAVC_MANDATE_DATE_ERROR
  }
};

export const parseDateFieldErrors = (fieldName, errorType) => {
  return errorMessages[fieldName][errorType];
};

export const getSupportedDecisionTypes = (featureToggles) => {
  const toggledDecisionTypes = {
    [CAVC_DECISION_TYPES.remand]: true,
    [CAVC_DECISION_TYPES.straight_reversal]:
      featureToggles.reversal_cavc_remand,
    [CAVC_DECISION_TYPES.death_dismissal]: featureToggles.dismissal_cavc_remand,
  };

  return Object.keys(toggledDecisionTypes).filter(
    (key) => toggledDecisionTypes[key] === true
  );
};

export const getSupportedRemandTypes = (featureToggles) => {
  const toggledRemandTypes = {
    [CAVC_REMAND_SUBTYPES.jmr]: false,
    [CAVC_REMAND_SUBTYPES.jmpr]: false,
    [CAVC_REMAND_SUBTYPES.jmr_jmpr]: true,
    [CAVC_REMAND_SUBTYPES.mdr]: featureToggles.mdr_cavc_remand,
  };

  return Object.keys(toggledRemandTypes).filter(
    (key) => toggledRemandTypes[key] === true
  );
};
