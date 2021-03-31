import React, { useEffect, useMemo, useState } from 'react';
import PropTypes from 'prop-types';
import { Controller, useForm } from 'react-hook-form';
import { yupResolver } from '@hookform/resolvers/yup';
import { isEmpty } from 'lodash';

import { css } from 'glamor';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';

import COPY from 'app/../COPY';
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

import {
  JmprIssuesBanner,
  JmrIssuesBanner,
  MdrBanner,
  MdrIssuesBanner,
  NoMandateBanner,
} from './Alerts';
import {
  allDecisionTypeOpts,
  allRemandTypeOpts,
  generateSchema,
} from './utils';

const YesNoOpts = [
  { displayText: 'Yes', value: 'yes' },
  { displayText: 'No', value: 'no' },
];

const judgeOptions = CAVC_JUDGE_FULL_NAMES.map((value) => ({
  label: value,
  value,
}));

const remandSubtype = _.map(_.keys(CAVC_REMAND_SUBTYPE_NAMES), (key) => ({
  displayText: CAVC_REMAND_SUBTYPE_NAMES[key],
  value: key
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
  onCancel,
  onSubmit,
}) => {
  const schema = useMemo(
    () => generateSchema({ maxIssues: decisionIssues.length }),
    [decisionIssues]
  );

  const { control, errors, handleSubmit, register, setValue, watch } = useForm({
    resolver: yupResolver(schema),
    reValidateMode: 'onChange',
    defaultValues: {
      issueIds: decisionIssues.map((issue) => issue.id),
      ...existingValues,
    },
  });

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
  const handleIssueChange = (evt) => {
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
  const watchIssueIds = watch('issueIds');

  const isRemandType = (type) =>
    watchDecisionType?.includes('remand') && watchRemandType?.includes(type);
  const allIssuesSelected = useMemo(
    () => watchIssueIds?.length === decisionIssues?.length,
    [watchIssueIds, decisionIssues]
  );

  const mandateAvailable = useMemo(
    () =>
      (watchRemandType && !watchRemandType?.includes('mdr')) ||
      watchRemandDatesProvided === 'yes',
    [watchRemandType, watchRemandDatesProvided]
  );

  return (
    <form onSubmit={handleSubmit(onSubmit)}>
      <AppSegment filledBackground>
        <h1>
          {isEmpty(existingValues) ?
            COPY.ADD_CAVC_PAGE_TITLE :
            COPY.EDIT_CAVC_PAGE_TITLE}
        </h1>
        <TextField
          inputRef={register}
          label={COPY.CAVC_DOCKET_NUMBER_LABEL}
          name="docketNumber"
          errorMessage={errors?.docketNumber && COPY.CAVC_DOCKET_NUMBER_ERROR}
          strongLabel
        />

        <RadioField
          errorMessage={errors?.attorney?.message}
          inputRef={register}
          label={COPY.CAVC_ATTORNEY_LABEL}
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
              label={COPY.CAVC_JUDGE_LABEL}
              options={judgeOptions}
              onChange={(valObj) => onChange(valObj?.value)}
              errorMessage={errors.judge && COPY.CAVC_JUDGE_ERROR}
              searchable
              strongLabel
            />
          )}
        />
        <br />
        <TextField
          inputRef={register}
          label={COPY.CAVC_TYPE_LABEL}
          name="decisionType"
          readOnly="{readOnly}"
          strongLabel
        />

        {watchDecisionType?.includes('remand') && (
          <TextField
            inputRef={register}
            label={COPY.CAVC_SUB_TYPE_LABEL}
            name="remandType"
            readOnly="{readOnly}"
            strongLabel
            //value={remandSubtype}
          />         
        )}

        {watchDecisionType && !watchDecisionType.includes('remand') && (
          <RadioField
            inputRef={register}
            styling={radioLabelStyling}
            label={COPY.CAVC_REMAND_MANDATE_QUESTION}
            name="remandDatesProvided"
            options={YesNoOpts}
            strongLabel
            errorMessage={errors?.remandDatesProvided?.message}
          />
        )}

        <DateSelector
          inputRef={register}
          label={COPY.CAVC_COURT_DECISION_DATE}
          type="date"
          name="decisionDate"
          errorMessage={errors?.decisionDate && COPY.CAVC_DECISION_DATE_ERROR}
          strongLabel
        />

        {isRemandType('mdr') && <MdrBanner />}

        {mandateAvailable && (
          <>
            <DateSelector
              inputRef={register}
              label={COPY.CAVC_JUDGEMENT_DATE}
              type="date"
              name="judgementDate"
              errorMessage={
                errors?.judgementDate && COPY.CAVC_JUDGEMENT_DATE_ERROR
              }
              strongLabel
            />

            <DateSelector
              inputRef={register}
              label={COPY.CAVC_MANDATE_DATE}
              type="date"
              name="mandateDate"
              errorMessage={errors?.mandateDate && COPY.CAVC_MANDATE_DATE_ERROR}
              strongLabel
            />
          </>
        )}

        {!mandateAvailable && !watchDecisionType?.includes('remand') && (
          <NoMandateBanner />
        )}

        {watchDecisionType && !watchDecisionType?.includes('death_dismissal') && (
          <React.Fragment>
            <legend>
              <strong>{COPY.CAVC_ISSUES_LABEL}</strong>
            </legend>
            <Button
              name={watchIssueIds.length ? 'Unselect all' : 'Select all'}
              styling={buttonStyling}
              linkStyling
              onClick={
                watchIssueIds?.length ? unselectAllIssues : selectAllIssues
              }
            />
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
                      onCheckChange(handleIssueChange(event))
                    }
                    styling={issueListStyling}
                    values={issueVals}
                    errorMessage={errors?.issueIds?.message}
                  />
                );
              }}
            />
          </React.Fragment>
        )}

        {isRemandType('jmr') && !allIssuesSelected && <JmrIssuesBanner />}
        {isRemandType('jmpr') && !watchIssueIds?.length && <JmprIssuesBanner />}
        {isRemandType('mdr') && !watchIssueIds?.length && <MdrIssuesBanner />}
        {isRemandType('mdr') && (
          <React.Fragment>
            <legend>
              <strong>{COPY.CAVC_FEDERAL_CIRCUIT_HEADER}</strong>
            </legend>
            <Checkbox
              inputRef={register}
              name="federalCircuit"
              label={COPY.CAVC_FEDERAL_CIRCUIT_LABEL}
            />
          </React.Fragment>
        )}

        <TextareaField
          inputRef={register}
          label={COPY.CAVC_INSTRUCTIONS_LABEL}
          name="instructions"
          errorMessage={errors.instructions && COPY.CAVC_INSTRUCTIONS_ERROR}
          strongLabel
        />
      </AppSegment>
      <div className="controls cf-app-segment">
        <Button type="submit" name="submit" classNames={['cf-right-side']}>
          Submit
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
  }),
  onCancel: PropTypes.func,
  onSubmit: PropTypes.func,
  supportedDecisionTypes: PropTypes.arrayOf(PropTypes.string),
  supportedRemandTypes: PropTypes.arrayOf(PropTypes.string),
  readOnly: PropTypes.bool
};
