import React, { useState, useRef } from 'react';
import { css } from 'glamor';
import PropTypes from 'prop-types';
import Button from 'app/components/Button';
import NonCompLayout from '../components/NonCompLayout';
import { Controller, useForm, FormProvider, useFormContext, useFieldArray, useWatch } from "react-hook-form"
import { yupResolver } from '@hookform/resolvers/yup';
import * as yup from 'yup';
import SearchableDropdown from '../../components/SearchableDropdown';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';

const buttonInnerContainerStyle = css({
  display: 'flex',
  gap: '32px'
});

const buttonOuterContainerStyling = css({
  display: 'flex',
  justifyContent: 'space-between',
  marginTop: '4rem'
});

// idk
const schema = yup.object().shape({
  reportType: yup.string().required(),
  conditions: yup.array(
    yup.object().shape({
      condition: yup.string().required(),
      options: yup.object().required(),
    })
  ),
});

const ReportPageButtons = ({ history }) => {
  const { register, handleSubmit } = useFormContext()

  const onSubmit = (data) => console.log(data)

  return (
    <div {...buttonOuterContainerStyling}>
      <Button
        classNames={['cf-modal-link', 'cf-btn-link']}
        label="cancel-report"
        name="cancel-report"
        onClick={() => history.push('/vha')}
      >
        Cancel
      </Button>
      <div {...buttonInnerContainerStyle}>
        <Button
          classNames={['usa-button']}
          label="clear-filters"
          name="clear-filters"
        >
          Clear filters
        </Button>
        <Button
          classNames={['usa-button']}
          label="generate-report"
          name="generate-report"
          onClick={handleSubmit(onSubmit)}
        >
          Generate task report
        </Button>
      </div>
    </div>
  );
};

const ReportPageConditions = () => {
  const {control, watch} = useFormContext()
  const { fields, append, remove } = useFieldArray({
    control,
    name: "conditions",
  });

  // TODO: extract to COPY
  const variableOptions = [
      { label: "Days Waiting",
        value: "daysWaiting" },
        { label: "Decision Review Type",
        value: "decisionReviewType" },
        { label: "Issue Type",
        value: "issueType" },
        { label: "Issue Disposition",
        value: "issueDisposition" },
        { label: "Personnel",
        value: "personnel" },
        { label: "Facility",
        value: "facility" },
  ]

  const determineOptions = () => {
    let conds = watch("conditions")
    let selectedOptions = conds.map((c) => c['condition'] ).filter((c) => c!== null)

    //personnel and facility are mutually exclusive
    if (selectedOptions.includes("facility")) {
      selectedOptions = selectedOptions.concat("personnel")
    }
    else if (selectedOptions.includes("personnel")) {
      selectedOptions = selectedOptions.concat("facility")
    }

    return variableOptions.filter(option => !selectedOptions.some(selectedOption => option.value === selectedOption))
  }

  const watchFieldArray = watch("conditions");
  const controlledFields = fields.map((field, index) => {
    return {
      ...field,
      ...watchFieldArray[index]
    };
  });

  return (
    <div>
      <hr />
      <h2>Conditions</h2>
      {controlledFields.map((field, index) => {
        return <ConditionContainer key={field.id} {... {control, index, field, remove, determineOptions}} />
      })}
      <Button
        disabled={watchFieldArray.length >= 5}
        onClick={() => append({condition: ''})}>
      Add Condition</Button>
    </div>
  )
}

const ConditionContainer = ({control, index, field, remove, determineOptions}) => {
  const name = `conditions.${index}.condition`

  const conditionsLength = useWatch({name: "conditions"}).length
  const shouldShowAnd = (conditionsLength > 1) && (index !== (conditionsLength - 1))

  return <div className="report-page-segment">
          <div className="cf-app-segment cf-app-segment--alt report-page-variable-condition" >
            <div className="report-page-variable-select">
              <ConditionDropdown {...{control, determineOptions, name}} />
            </div>
            <div className="report-page-variable-content">Your cool {useWatch({control, name})} content here!</div>
          </div>
          <Link onClick={() => remove(index)}>Remove condition</Link>
          {shouldShowAnd && <div className="report-page-condition-and">AND</div>}
        </div>
}
const ConditionDropdown = ({ control, determineOptions, name}) => {
  let [disabled, setDisabled] = useState(false);

  const filteredOptions = determineOptions();
  return <Controller
                control={control}
                name={name}
                defaultValue={null}
                render={({ onChange, ...rest }) => (
                  <SearchableDropdown
                    {...rest}
                    label="Variable"
                    options={filteredOptions}
                    readOnly={disabled}
                    onChange={(valObj) => {
                      setDisabled(true);
                      onChange(valObj?.value);
                    }}
                    placeholder="Select a variable"
                  />

              )}
            />
};

const ReportPage = ({ history }) => {
  const methods = useForm({defaultValues: {
    conditions: []
  }});

  return (
    <FormProvider {...methods}>
      <form>
        <NonCompLayout buttons={<ReportPageButtons history={history} />}>
          <h1>Generate task report</h1>
          <ReportPageConditions />
        </NonCompLayout>
      </form>
    </FormProvider>
  );
};

ReportPageButtons.propTypes = {
  history: PropTypes.object,
};

ReportPage.propTypes = {
  history: PropTypes.object,
};

export default ReportPage;
