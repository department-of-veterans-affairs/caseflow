/* eslint-disable max-lines */
import PropTypes from 'prop-types';
import React, { useEffect, useMemo, useState } from 'react';
import { Controller, useForm } from 'react-hook-form';
import { yupResolver } from '@hookform/resolvers/yup';
import { isEmpty } from 'lodash';

import { css } from 'glamor';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';

import { ADD_CAVC_PAGE_TITLE, CAVC_ATTORNEY_LABEL, CAVC_COURT_DECISION_DATE,
  CAVC_DOCKET_NUMBER_LABEL, CAVC_DOCKET_NUMBER_ERROR, CAVC_FEDERAL_CIRCUIT_HEADER,
  CAVC_FEDERAL_CIRCUIT_LABEL, CAVC_JUDGE_ERROR, CAVC_JUDGE_LABEL,
  CAVC_JUDGEMENT_DATE, CAVC_INSTRUCTIONS_ERROR, PROVIDE_INSTRUCTIONS_AND_CONTEXT_LABEL, CAVC_ISSUES_LABEL,
  CAVC_MANDATE_DATE, CAVC_REMAND_MANDATE_DATES_LABEL, CAVC_REMAND_MANDATE_QUESTION,
  CAVC_REMAND_MANDATE_DATES_SAME_DESCRIPTION, CAVC_SUB_TYPE_LABEL, CAVC_TYPE_LABEL,
  EDIT_CAVC_PAGE_TITLE, CAVC_SUBSTITUTE_APPELLANT_LABEL, CAVC_SUBSTITUTE_APPELLANT_DATE_LABEL,
  CAVC_SUBSTITUTE_APPELLANT_CLAIMANTS_LABEL } from 'app/../COPY';
import TextField from 'app/components/TextField';
import TextareaField from 'app/components/TextareaField';
import RadioField from 'app/components/RadioField';
import Button from 'app/components/Button';
import SearchableDropdown from 'app/components/SearchableDropdown';
import DateSelector from 'app/components/DateSelector';
import Checkbox from 'app/components/Checkbox';
import CheckboxGroup from 'app/components/CheckboxGroup';

import CAVC_JUDGE_FULL_NAMES from 'constants/CAVC_JUDGE_FULL_NAMES';
import CAVC_REMAND_SUBTYPE_NAMES from 'constants/CAVC_REMAND_SUBTYPE_NAMES';
import CAVC_DECISION_TYPE_NAMES from 'constants/CAVC_DECISION_TYPE_NAMES';

import {
  JmrJmprIssuesBanner,
  MdrBanner,
  MdrIssuesBanner,
  NoMandateBanner,
} from './Alerts';
import {
  allDecisionTypeOpts,
  allRemandTypeOpts,
  generateSchema,
  parseDateFieldErrors
} from './utils';

const YesNoOpts = [
  { displayText: 'Yes', value: 'yes' },
  { displayText: 'No', value: 'no' },
];

const judgeOptions = CAVC_JUDGE_FULL_NAMES.map((value) => ({
  label: value,
  value,
}));

const radioLabelStyling = css({ marginTop: '2.5rem' });
const issueListStyling = css({ marginTop: '0rem' });
const buttonStyling = css({ paddingLeft: '0' });

/**
 * @param {Object} props
 *  - @param {Object[]} decisionIssues   Issues pulled from state to allow the user to select which are being remanded
 *  - @param {Object}   existingValues   Values to pre-populate the form (used when editing)
 *  - @param {string[]} supportedDecisionTypes Which decision types are allowed (usually due to feature toggles)
 *  - @param {string[]} supportedRemandTypes Which remand types are allowed (usually due to feature toggles)
 *  - @param {function} onCancel         Function called when "cancel" button is clicked
 *  - @param {function} onSubmit         Function called when form is submitted and data is validated
 */
export const EditCavcRemandForm = ({
  decisionIssues,
  existingValues = {},
  supportedDecisionTypes = [],
  supportedRemandTypes = [],
  substituteAppellantClaimantOptions,
  nodDate,
  dateOfDeath,
  featureToggles,
  onCancel,
  onSubmit,
}) => {
  const mode = useMemo(() => (isEmpty(existingValues) ? 'add' : 'edit'), [
    existingValues,
  ]);

  const schema = useMemo(
    () => generateSchema({ maxIssues: decisionIssues.length, nodDate, dateOfDeath }),
    [decisionIssues]
  );

  const { control, errors, handleSubmit, register, setValue, watch } = useForm({
    resolver: yupResolver(schema),
    context: { nodDate, dateOfDeath },
    reValidateMode: 'onChange',
    defaultValues: {
      issueIds: decisionIssues.map((issue) => issue.id),
      // EditCavcTodo: remove the following if not needed; see remandDatesProvided
      mandateSame: !existingValues.judgementDate,
      ...existingValues,
    },
  });

  // Ensure dates not set for MDR remand type
  // For MDR, dates will be set after hold expires via AddCavcDatesModal
  useEffect(() => {
    if (existingValues?.remandType?.includes('mdr')) {
      setValue('remandDatesProvided', 'no');
      setValue('judgementDate', '');
      setValue('mandateDate', '');
    }
  }, [existingValues.remandType]);

  const filteredDecisionTypes = useMemo(
    () =>
      allDecisionTypeOpts.filter((item) =>
        supportedDecisionTypes.includes(item.value)
      ),
    [supportedDecisionTypes]
  );

  const filteredRemandTypes = useMemo(
    () =>
      allRemandTypeOpts.filter((item) =>
        supportedRemandTypes.includes(item.value)
      ),
    [supportedRemandTypes]
  );

  const issueOptions = useMemo(
    () =>
      decisionIssues.map((decisionIssue) => ({
        id: decisionIssue.id.toString(),
        label: decisionIssue.description,
      })),
    [decisionIssues]
  );

  // We have to do a bit of manual manipulation for issue IDs due to nature of CheckboxGroup
  const [issueVals, setIssueVals] = useState({});
  const handleIssueSelectionChange = (evt) => {
    const newIssues = { ...issueVals, [evt.target.name]: evt.target.checked };

    setIssueVals(newIssues);

    // Form wants to track only the selected issue IDs
    return Object.keys(newIssues).filter((key) => newIssues[key]);
  };

  const unselectAllIssues = () => {
    const newIssues = { ...issueVals };

    decisionIssues.forEach((issue) => (newIssues[issue.id] = false));
    setIssueVals(newIssues);
    setValue('issueIds', []);
  };

  const selectAllIssues = () => {
    const newIssues = { ...issueVals };
    const allIssueIds = decisionIssues.map((issue) => issue.id);

    // Pre-select all issues
    allIssueIds.forEach((id) => (newIssues[id] = true));
    setIssueVals(newIssues);
    setValue('issueIds', [...allIssueIds]);
  };

  const claimantOptionsExists =
    Array.isArray(substituteAppellantClaimantOptions) && substituteAppellantClaimantOptions.length > 0;
  const isAppellantSubstitutedOptions = [
    { displayText: 'Yes', value: 'true', disabled: !claimantOptionsExists },
    { displayText: 'No', value: 'false' }
  ];

  // Handle prepopulating issue checkboxes if defaultValues are present
  useEffect(() => {
    if (existingValues?.issueIds?.length) {
      const newIssues = { ...issueVals };

      for (const id of existingValues.issueIds) {
        newIssues[id] = true;
      }
      setIssueVals(newIssues);
    } else {
      selectAllIssues();
    }
  }, [decisionIssues, existingValues.issueIds]);

  const watchDecisionType = watch('decisionType');
  const watchRemandType = watch('remandType');
  const watchRemandDatesProvided = watch('remandDatesProvided');
  const watchMandateSame = watch('mandateSame');
  const watchIssueIds = watch('issueIds');

  const isRemandType = (type) =>
    watchDecisionType?.includes('remand') && watchRemandType?.includes(type);

  const mandateDatesAvailable = useMemo(
    () =>
      (watchRemandType && !watchRemandType?.includes('mdr')) ||
      watchRemandDatesProvided === 'yes',
    [watchRemandType, watchRemandDatesProvided]
  );

  const [isAppellantSubstitutedValue, setIsAppellantSubstitutedValue] =
    useState(existingValues?.isAppellantSubstituted);
  const isAppellantSubstitutedYes = isAppellantSubstitutedValue === 'true';

  return (
    <form onSubmit={handleSubmit(onSubmit)}>
      <AppSegment filledBackground>
        <h1>
          {isEmpty(existingValues) ?
            ADD_CAVC_PAGE_TITLE :
            EDIT_CAVC_PAGE_TITLE}
        </h1>
        <TextField
          inputRef={register}
          label={CAVC_DOCKET_NUMBER_LABEL}
          name="docketNumber"
          errorMessage={errors?.docketNumber && CAVC_DOCKET_NUMBER_ERROR}
          strongLabel
        />

        { featureToggles.cavc_remand_granted_substitute_appellant &&
          <RadioField
            errorMessage={errors?.isAppellantSubstituted?.message}
            inputRef={register}
            label={CAVC_SUBSTITUTE_APPELLANT_LABEL}
            name="isAppellantSubstituted"
            options={isAppellantSubstitutedOptions}
            onChange={(val) => setIsAppellantSubstitutedValue(val)}
            strongLabel
          />
        }

        {featureToggles.cavc_remand_granted_substitute_appellant && !claimantOptionsExists &&
          <p>No existing relationships were found.</p>
        }

        { featureToggles.cavc_remand_granted_substitute_appellant && isAppellantSubstitutedYes &&
          <DateSelector
            inputRef={register}
            label={CAVC_SUBSTITUTE_APPELLANT_DATE_LABEL}
            type="date"
            name="substitutionDate"
            errorMessage={errors?.substitutionDate && errors.substitutionDate?.message}
            strongLabel
          />
        }

        { featureToggles.cavc_remand_granted_substitute_appellant &&
          isAppellantSubstitutedYes &&
          substituteAppellantClaimantOptions &&
          <RadioField
            label={CAVC_SUBSTITUTE_APPELLANT_CLAIMANTS_LABEL}
            inputRef={register}
            name="participantId"
            errorMessage={errors?.participantId?.message}
            options={substituteAppellantClaimantOptions}
            strongLabel
          />
        }

        <RadioField
          errorMessage={errors?.attorney?.message}
          inputRef={register}
          label={CAVC_ATTORNEY_LABEL}
          name="attorney"
          options={YesNoOpts}
          strongLabel
        />

        <Controller
          control={control}
          name="judge"
          render={({ onChange, ...rest }) => (
            <SearchableDropdown
              {...rest}
              label={CAVC_JUDGE_LABEL}
              options={judgeOptions}
              onChange={(valObj) => onChange(valObj?.value)}
              errorMessage={errors.judge && CAVC_JUDGE_ERROR}
              searchable
              strongLabel
            />
          )}
        />

        {mode === 'add' ? (
          <RadioField
            errorMessage={errors?.decisionType?.message}
            inputRef={register}
            styling={radioLabelStyling}
            label={CAVC_TYPE_LABEL}
            name="decisionType"
            options={filteredDecisionTypes}
            strongLabel
            vertical
          />
        ) : (
          <>
            <TextField
              name="decisionTypeDisplay"
              value={CAVC_DECISION_TYPE_NAMES[(existingValues?.decisionType)]}
              label={CAVC_TYPE_LABEL}
              readOnly
              strongLabel
            />
            <input type="hidden" ref={register} name="decisionType" />
          </>
        )}

        {watchDecisionType?.includes('remand') &&
          (mode === 'add' ? (
            <RadioField
              inputRef={register}
              errorMessage={errors?.remandType?.message}
              styling={radioLabelStyling}
              label={CAVC_SUB_TYPE_LABEL}
              name="remandType"
              options={filteredRemandTypes}
              strongLabel
              vertical
            />
          ) : (
            <>
              <TextField
                name="remandTypeDisplay"
                value={CAVC_REMAND_SUBTYPE_NAMES[(existingValues?.remandType)]}
                label={CAVC_SUB_TYPE_LABEL}
                readOnly
                strongLabel
              />
              <input type="hidden" ref={register} name="remandType" />
            </>
          ))}

        {watchDecisionType && !watchDecisionType.includes('remand') && (
          <RadioField
            inputRef={register}
            styling={radioLabelStyling}
            label={CAVC_REMAND_MANDATE_QUESTION}
            name="remandDatesProvided"
            options={YesNoOpts}
            strongLabel
            errorMessage={errors?.remandDatesProvided?.message}
          />
        )}

        <DateSelector
          inputRef={register}
          label={CAVC_COURT_DECISION_DATE}
          type="date"
          name="decisionDate"
          errorMessage={errors?.decisionDate?.message}
          strongLabel
        />
        {isRemandType('mdr') && <MdrBanner />}

        {mode === 'add' && mandateDatesAvailable && (
          <>
            <legend>
              <strong>{CAVC_REMAND_MANDATE_DATES_LABEL}</strong>
            </legend>
            <Checkbox
              inputRef={register}
              label={CAVC_REMAND_MANDATE_DATES_SAME_DESCRIPTION}
              name="mandateSame"
            />
          </>
        )}
        {mandateDatesAvailable && !watchMandateSame && (
          <div>
            <DateSelector
              inputRef={register}
              label={CAVC_JUDGEMENT_DATE}
              type="date"
              name="judgementDate"
              errorMessage={parseDateFieldErrors('judgementDate', errors?.judgementDate?.type)}
              strongLabel
            />

            <DateSelector
              inputRef={register}
              label={CAVC_MANDATE_DATE}
              type="date"
              name="mandateDate"
              errorMessage={parseDateFieldErrors('mandateDate', errors?.mandateDate?.type)}
              strongLabel
            />
          </div>
        )}

        {!mandateDatesAvailable && !watchDecisionType?.includes('remand') && (
          <NoMandateBanner />
        )}

        {/* If the following is hidden for death_dismissal, no issues are submitted. */}
        {
          <React.Fragment>
            {!watchDecisionType?.includes('death_dismissal') && (
              <>
                <legend>
                  <strong>{CAVC_ISSUES_LABEL}</strong>
                </legend>
                <Button
                  name={watchIssueIds.length ? 'Unselect all' : 'Select all'}
                  styling={buttonStyling}
                  linkStyling
                  onClick={
                    watchIssueIds?.length ? unselectAllIssues : selectAllIssues
                  }
                />
              </>
            )}

            <Controller
              name="issueIds"
              control={control}
              render={({ name, onChange: onCheckChange }) => {
                return (
                  <CheckboxGroup
                    name={name}
                    label="Please unselect any tasks you would like to remove:"
                    strongLabel
                    options={issueOptions}
                    onChange={(event) =>
                      onCheckChange(handleIssueSelectionChange(event))
                    }
                    styling={issueListStyling}
                    values={issueVals}
                    disableAll={watchDecisionType?.includes('death_dismissal')}
                    errorMessage={errors?.issueIds?.message}
                  />
                );
              }}
            />
          </React.Fragment>
        }

        {(isRemandType('jmr_jmpr') || isRemandType('jmr') || isRemandType('jmpr')) &&
        !watchIssueIds?.length && <JmrJmprIssuesBanner />}
        {isRemandType('mdr') && !watchIssueIds?.length && <MdrIssuesBanner />}
        {isRemandType('mdr') && (
          <React.Fragment>
            <legend>
              <strong>{CAVC_FEDERAL_CIRCUIT_HEADER}</strong>
            </legend>
            <Checkbox
              inputRef={register}
              name="federalCircuit"
              label={CAVC_FEDERAL_CIRCUIT_LABEL}
            />
          </React.Fragment>
        )}

        <TextareaField
          inputRef={register}
          label={PROVIDE_INSTRUCTIONS_AND_CONTEXT_LABEL}
          name="instructions"
          errorMessage={errors.instructions && CAVC_INSTRUCTIONS_ERROR}
          strongLabel
        />
      </AppSegment>
      <div className="controls cf-app-segment">
        <Button
          type="submit"
          name={(featureToggles.cavc_remand_granted_substitute_appellant &&
                 Array.isArray(substituteAppellantClaimantOptions) &&
                substituteAppellantClaimantOptions.length > 0) ? 'continue' : 'submit'}
          classNames={['cf-right-side']}
        >
          {(featureToggles.cavc_remand_granted_substitute_appellant &&
             Array.isArray(substituteAppellantClaimantOptions) &&
            substituteAppellantClaimantOptions.length > 0) ? 'Continue' : 'Submit'}
        </Button>
        {onCancel && (
          <Button
            type="button"
            name="Cancel"
            classNames={['cf-right-side', 'usa-button-secondary']}
            onClick={onCancel}
            styling={{ style: { marginRight: '1rem' } }}
          >
            Cancel
          </Button>
        )}
      </div>
    </form>
  );
};
EditCavcRemandForm.propTypes = {
  decisionIssues: PropTypes.arrayOf(
    PropTypes.shape({
      id: PropTypes.oneOfType([PropTypes.number, PropTypes.string]),
      description: PropTypes.string,
    })
  ),
  existingValues: PropTypes.shape({
    docketNumber: PropTypes.string,
    attorney: PropTypes.string,
    judge: PropTypes.string,
    decisionType: PropTypes.string,
    remandType: PropTypes.string,
    remandDatesProvided: PropTypes.oneOf(['yes', 'no']),
    decisionDate: PropTypes.string,
    judgementDate: PropTypes.string,
    mandateDate: PropTypes.string,
    issueIds: PropTypes.arrayOf(
      PropTypes.oneOfType([PropTypes.string, PropTypes.number])
    ),
    federalCircuit: PropTypes.bool,
    instructions: PropTypes.oneOfType([
      PropTypes.string,
      PropTypes.arrayOf(PropTypes.string),
    ]),
    substitutionDate: PropTypes.string,
    participantId: PropTypes.string,
    isAppellantSubstituted: PropTypes.string
  }),
  onCancel: PropTypes.func,
  onSubmit: PropTypes.func,
  supportedDecisionTypes: PropTypes.arrayOf(PropTypes.string),
  supportedRemandTypes: PropTypes.arrayOf(PropTypes.string),
  readOnly: PropTypes.bool,
  substituteAppellantClaimantOptions: PropTypes.array,
  nodDate: PropTypes.any,
  dateOfDeath: PropTypes.any,
  featureToggles: PropTypes.object
};
/* eslint-enable max-lines */
