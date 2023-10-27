import React from 'react';
import { useForm, FormProvider } from 'react-hook-form';
import { css } from 'glamor';
import PropTypes from 'prop-types';
import Button from 'app/components/Button';
import NonCompLayout from '../components/NonCompLayout';

import NonCompReportFilterContainer from '../components/NonCompReportFilter';
import RadioField from '../../components/RadioField';

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

const ReportPage = ({ history }) => {
  const defaultFormValues = {
    reportType: '',
    radioEventAction: '',
  };

  const methods = useForm({ defaultValues: { ...defaultFormValues } });

  const { register, reset, watch, getValues,setvalues, formState } = methods;

  const watchReportType = watch('reportType');
  const watchEventTypeAction = watch('radioEventAction')

  const onSubmit = (data) => console.log(data);

  const radioEventActionOptions = [
    {
      displayText: <span>All Events / Actions</span>,
      value: 'all_events_action'
    },
    {
      displayText: <span>Specific Events / Actions</span>,
      value: 'specific_events_action'
    }
  ]
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
            <>
              <RadioField
                {...register('radioEventAction')}
                name='radioEventAction'
                label=""
                options={radioEventActionOptions}
                vertical
                // value = {getValues('radioEventAction')}
                onchange={(valObj) => setvalues('radioEventAction',valObj?.value)}
              />
            </>
            : ''}
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

export default ReportPage;
