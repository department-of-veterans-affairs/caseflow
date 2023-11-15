import React from 'react';
import { useController, useForm, FormProvider } from 'react-hook-form';
import { css } from 'glamor';
import PropTypes from 'prop-types';
import Button from 'app/components/Button';
import NonCompLayout from '../components/NonCompLayout';
import { conditionsSchema, ReportPageConditions } from '../components/ReportPage/ReportPageConditions';

import { yupResolver } from '@hookform/resolvers/yup';
import * as yup from 'yup';

import RHFControlledDropdownContainer from 'app/nonComp/components/ReportPage/RHFControlledDropdown';
import { timingSchema, TimingSpecification } from 'app/nonComp/components/ReportPage/TimingSpecification';

import Checkbox from 'app/components/Checkbox';
import RadioField from 'app/components/RadioField';

import {
  REPORT_TYPE_OPTIONS,
  RADIO_EVENT_TYPE_OPTIONS,
  SPECTIFIC_EVENT_OPTIONS
} from 'constants/REPORT_TYPE_CONSTANTS';

const buttonInnerContainerStyle = css({
  display: 'flex',
  gap: '32px',
});

const buttonOuterContainerStyling = css({
  display: 'flex',
  justifyContent: 'space-between',
  marginTop: '4rem',
});

const schema = yup.object().shape({
  conditions: conditionsSchema,
  timing: timingSchema
});

const ReportPageButtons = ({
  history,
  isGenerateButtonDisabled,
  handleClearFilters,
  handleSubmit }) => {

  // eslint-disable-next-line no-console
  const onSubmit = (data) => console.log(data);

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
          onClick={handleClearFilters}
          disabled={isGenerateButtonDisabled}
        >
          Clear filters
        </Button>
        <Button
          classNames={['usa-button']}
          label="generate-report"
          name="generate-report"
          onClick={handleSubmit(onSubmit)}
          disabled={isGenerateButtonDisabled}
        >
          Generate task report
        </Button>
      </div>
    </div>
  );
};

const RHFCheckboxGroup = ({ options, name, control }) => {
  const { field } = useController({
    control,
    name,
  });
  const [value, setValue] = React.useState({});

  return (
    <fieldset className="checkbox" style={{ paddingLeft: '30px' }}>
      {options.map((option) => (
        <div key={option.id}>
          <Checkbox
            name={`specificEventType.${option.id}`}
            key={`specificEventType.${option.id}`}
            label={option.label}
            stronglabel
            onChange={(val) => {
              value[option.id] = val;
              field.onChange(value);
              setValue(value);
            }}
            unpadded
            style={{ outline: 'none' }}
          />
        </div>
      ))}
    </fieldset>
  );
};

const RHFRadioButton = ({ options, name, control }) => {
  const { field } = useController({
    control,
    name,
  });

  return (
    <div style={{ marginTop: '20px' }}>
      <RadioField
        name=""
        label=""
        vertical
        options={options}
        stronglabel
        value={field.value}
        onChange={(val) => {
          field.onChange(val);
        }}
      />
    </div>
  );
};

const ReportPage = ({ history }) => {
  const defaultFormValues = {
    reportType: '',
    conditions: [],
    timing: {
      range: null,
      startDate: '',
      endDate: '',
    },
    radioEventAction: 'all_events_action',
    specificEventType: {
      added_decision_date: '',
      added_issue: '',
      added_issue_no_decision_date: '',
      claim_created: '',
      claim_closed: '',
      claim_status_incomplete: '',
      claim_status_inprogress: '',
      completed_disposition: '',
      removed_issue: '',
      withdrew_issue: '',
    }
  };

  const methods = useForm({
    defaultValues: { ...defaultFormValues },
    resolver: yupResolver(schema),
    mode: 'onSubmit',
    reValidateMode: 'onSubmit'
  });

  const { reset, watch, formState, control, handleSubmit } = methods;

  const watchReportType = watch('reportType');
  const watchRadioEventAction = watch('radioEventAction');

  return (
    <NonCompLayout
      buttons={
        <ReportPageButtons
          history={history}
          isGenerateButtonDisabled={!formState.isDirty}
          handleClearFilters={() => reset(defaultFormValues)}
          handleSubmit={handleSubmit}
        />
      }
    >
      <h1>Generate task report</h1>
      <FormProvider {...methods}>
        <form>
          <RHFControlledDropdownContainer
            header="Type of report"
            name="reportType"
            label="Report Type"
            options={REPORT_TYPE_OPTIONS}
          />
          {watchReportType === 'event_type_action' ? (
            <RHFRadioButton
              options={RADIO_EVENT_TYPE_OPTIONS}
              methods={methods}
              name="radioEventAction"
            />
          ) : null
          }
          {watchReportType === 'event_type_action' &&
          watchRadioEventAction === 'specific_events_action' ? (
              <RHFCheckboxGroup
                options={SPECTIFIC_EVENT_OPTIONS}
                control={control}
                name="specificEventType"
              />
            ) : null
          }
          {watchReportType === 'event_type_action' ?
            <TimingSpecification /> :
            null
          }
          {formState.isDirty ? <ReportPageConditions /> : null}
        </form>
      </FormProvider>
    </NonCompLayout>
  );
};

ReportPageButtons.propTypes = {
  history: PropTypes.object,
  isGenerateButtonDisabled: PropTypes.bool,
  handleClearFilters: PropTypes.func,
  handleSubmit: PropTypes.func,
};

ReportPage.propTypes = {
  history: PropTypes.object,
};

RHFCheckboxGroup.propTypes = {
  options: PropTypes.array,
  control: PropTypes.object,
  name: PropTypes.string
};

RHFRadioButton.propTypes = {
  options: PropTypes.array,
  control: PropTypes.object,
  name: PropTypes.string
};

export default ReportPage;
