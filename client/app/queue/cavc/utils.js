import * as yup from 'yup';
import StringUtil from 'app/util/StringUtil';

import COPY from 'app/../COPY';
import CAVC_JUDGE_FULL_NAMES from 'constants/CAVC_JUDGE_FULL_NAMES';
import CAVC_REMAND_SUBTYPES from 'constants/CAVC_REMAND_SUBTYPES';
import CAVC_REMAND_SUBTYPE_NAMES from 'constants/CAVC_REMAND_SUBTYPE_NAMES';
import CAVC_DECISION_TYPES from 'constants/CAVC_DECISION_TYPES';

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

export const generateSchema = ({ maxIssues }) => {
  const requireDateBeforeToday = yup.
    date().
    max(new Date()).
    required();

  return yup.object().shape({
    docketNumber: yup.
      string().
      // We accept ‐ HYPHEN, - Hyphen-minus, − MINUS SIGN, – EN DASH, — EM DASH
      matches(/^\d{2}[-‐−–—]\d{1,5}$/).
      required(),
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
      is: 'remand',
      then: yup.string(),
      otherwise: yup.string().required('Choose one'),
    }),
    decisionDate: yup.
      date().
      max(new Date()).
      required(),
    mandateSame: yup.boolean(), // EditCavcTodo: remove if not needed; see remandDatesProvided
    judgementDate: yup.mixed().when('remandDatesProvided', {
      is: 'yes',
      then: requireDateBeforeToday,
    }),
    mandateDate: yup.mixed().when('remandDatesProvided', {
      is: 'yes',
      then: requireDateBeforeToday,
    }),
    issueIds: yup.
      array().
      of(yup.string()).
      when('remandType', {
        is: 'jmr',
        then: yup.array().length(maxIssues, COPY.CAVC_ALL_ISSUES_ERROR),
        otherwise: yup.array().min(1, COPY.CAVC_NO_ISSUES_ERROR),
      }),
    federalCircuit: yup.boolean(),
    instructions: yup.string().required(),
  });
};

export const getSupportedDecisionTypes = (featureToggles) => {
  const toggledDecisionTypes = {
    [CAVC_DECISION_TYPES.remand]: featureToggles.cavc_remand,
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
    [CAVC_REMAND_SUBTYPES.jmr]: featureToggles.cavc_remand,
    [CAVC_REMAND_SUBTYPES.jmpr]: featureToggles.cavc_remand,
    [CAVC_REMAND_SUBTYPES.mdr]: featureToggles.mdr_cavc_remand,
  };

  return Object.keys(toggledRemandTypes).filter(
    (key) => toggledRemandTypes[key] === true
  );
};
