import React from 'react';
import { useForm, FormProvider } from 'react-hook-form';
import { css, left } from 'glamor';
import PropTypes from 'prop-types';
import Button from 'app/components/Button';
import NonCompLayout from '../components/NonCompLayout';

import Checkbox from '../../components/Checkbox';
import RadioField from '../../components/RadioField';
import NonCompReportFilterContainer from '../components/NonCompReportFilter';

import REPORT_TYPE_CONSTANTS from '../../../constants/REPORT_TYPE_CONSTANTS.json'

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

const RHFCheckboxGroup = ({ options, methods }) => {
  return (
    <fieldset className="checkbox" style={{ paddingLeft: "30px" }}> {
      options.map((option) =>
      <div className="checkbox" key={option.id} >
        <Checkbox
          {...methods.register(`specificEventType.${option.id}`)}
          name={`specificEventType.${option.id}`}
          key={`specificEventType.${option.id}`}
          label={option.label}
          stronglabel
          value={methods.getValues(`specificEventType.${option.id}`)}
          onChange={(value) => methods.setValue(`specificEventType.${option.id}`, value)}
          unpadded
        />
      </div>
      )
    }
    </fieldset>
  );
};

const RHFRadioButton = ({ options, methods}) => {
  return (
    <div style={{marginTop: "20px"}}>
      <RadioField name=""
      {...methods.register('radioEventAction')}
      label=""
      vertical
      options={options}
      value={methods.getValues('radioEventAction')}
      stronglabel
      onChange={(value) => methods.setValue('radioEventAction', value)} />
    </div>
  );
};

const ReportPage = ({ history }) => {
  const defaultFormValues = {
    reportType: '',
    radioEventAction: '',
    specificEventType: [],
  };

  const methods = useForm({ defaultValues: { ...defaultFormValues } });

  const { register, reset, watch, getValues,setValue, formState } = methods;

  const watchReportType = watch('reportType');
  const watchRadioEventAction = watch('radioEventAction');


  const onSubmit = (data) => console.log(data);

  const handleOnChange = (value) => {
    console.log(value);
  }

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
          {watchReportType === 'event_type_action' ?
            <RHFRadioButton options={REPORT_TYPE_CONSTANTS.RADIO_EVENT_TYPE_OPTIONS} methods={methods} />
            : ''
          }
          {(watchReportType === 'event_type_action'  && watchRadioEventAction === 'specific_events_action') ?
              <RHFCheckboxGroup options={REPORT_TYPE_CONSTANTS.SPECTIFIC_EVENT_OPTIONS} methods={methods} />
            : ''
          }
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
  methods: PropTypes.object
};

RHFRadioButton.propTypes = {
  options: PropTypes.array,
  methods: PropTypes.object
};

export default ReportPage;
