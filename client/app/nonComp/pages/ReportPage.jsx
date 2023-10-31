import React from 'react';
import { useController, useForm, FormProvider } from 'react-hook-form';
import { css, left } from 'glamor';
import PropTypes from 'prop-types';
import Button from 'app/components/Button';
import NonCompLayout from '../components/NonCompLayout';

import Checkbox from '../../components/Checkbox';
import RadioField from '../../components/RadioField';
import NonCompReportFilterContainer from '../components/NonCompReportFilter';

import REPORT_TYPE_CONSTANTS from '../../../constants/REPORT_TYPE_CONSTANTS';

const buttonInnerContainerStyle = css({
  display: 'flex',
  gap: '32px',
});

const buttonOuterContainerStyling = css({
  display: 'flex',
  justifyContent: 'space-between',
  marginTop: '4rem',
});

const ReportPageButtons = ({
  history,
  disableGenerateButton,
  handleClearFilters,
  handleSubmit,
}) => {
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
          disabled={disableGenerateButton}
        >
          Clear filters
        </Button>
        <Button
          classNames={['usa-button']}
          label="generate-report"
          name="generate-report"
          onClick={handleSubmit}
          disabled={disableGenerateButton}
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
      {' '}
      {options.map((option) => (
        <div className="checkbox" key={option.id}>
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
    },
  };

  const methods = useForm({ defaultValues: { ...defaultFormValues } });

  const { reset, watch, formState, control } = methods;

  const watchReportType = watch('reportType');
  const watchRadioEventAction = watch('radioEventAction');

  const onSubmit = (data) => console.log(data);

  return (
    <NonCompLayout
      buttons={
        <ReportPageButtons
          history={history}
          disableGenerateButton={!formState.isDirty}
          handleClearFilters={() => reset(defaultFormValues)}
          handleSubmit={methods.handleSubmit(onSubmit)}
        />
      }
    >
      <h1>Generate task report</h1>
      <FormProvider {...methods}>
        <form>
          <NonCompReportFilterContainer />
          {watchReportType === 'event_type_action' ? (
            <RHFRadioButton
              options={REPORT_TYPE_CONSTANTS.RADIO_EVENT_TYPE_OPTIONS}
              methods={methods}
              name="radioEventAction"
            />
          ) : (
            ''
          )}
          {watchReportType === 'event_type_action' &&
          watchRadioEventAction === 'specific_events_action' ? (
              <RHFCheckboxGroup
                options={REPORT_TYPE_CONSTANTS.SPECTIFIC_EVENT_OPTIONS}
                control={control}
                name="specificEventType"
              />
            ) : (
              ''
            )}
        </form>
      </FormProvider>
    </NonCompLayout>
  );
};

ReportPageButtons.propTypes = {
  history: PropTypes.object,
  disableGenerateButton: PropTypes.bool,
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
