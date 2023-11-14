import React from 'react';
import { useController, useForm, FormProvider } from 'react-hook-form';
import { useDispatch, useSelector } from 'react-redux';
import { downloadReportCSV } from 'app/nonComp/actions/changeHistorySlice';
import { css } from 'glamor';
import PropTypes from 'prop-types';
import Button from 'app/components/Button';
import NonCompLayout from 'app/nonComp/components/NonCompLayout';
import { ReportPageConditions } from '../components/ReportPage/ReportPageConditions';

import Checkbox from 'app/components/Checkbox';
import RadioField from 'app/components/RadioField';
import NonCompReportFilterContainer from 'app/nonComp/components/NonCompReportFilter';

import REPORT_TYPE_CONSTANTS from 'constants/REPORT_TYPE_CONSTANTS';
import LoadingMessage from '../../components/LoadingMessage';
import { LoadingIcon } from '../../components/icons/LoadingIcon';

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
  isGenerateButtonDisabled,
  handleClearFilters,
  handleSubmit
}) => {
// for later
// const schema = yup.object().shape({
//   conditions: yup.array(
//     yup.object().shape({
//       condition: yup.string().required(),
//       options: yup.object().required(),
//     })
//   ),
  // });

  // eslint-disable-next-line no-console
  // const onSubmit = (data) => {
  //   console.log(data);

  //   return data;
  // };

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
          onClick={handleSubmit}
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
    conditions: []
  };

  const methods = useForm({ defaultValues: { ...defaultFormValues } });
  const { reset, watch, formState, control, handleSubmit } = methods;
  const dispatch = useDispatch();
  const businessLineUrl = useSelector((state) => state.nonComp.businessLineUrl);
  const csvGeneration = useSelector((state) => state.changeHistory.status);

  const isCSVGenerating = csvGeneration === 'loading';

  const submitForm = (data) => {
    // eslint-disable-next-line no-console
    console.log(data);

    // Don't know how acceptable this is for compliance.
    // Could also do something like a modal that grabs focus while it is generating
    window.scrollTo(0, 0);

    // Example csv generation code:
    dispatch(downloadReportCSV({ organizationUrl: businessLineUrl, filterData: { filters: { report: 'true' } } }));
  };

  const watchReportType = watch('reportType');
  const watchRadioEventAction = watch('radioEventAction');

  return (
    <NonCompLayout
      buttons={
        <ReportPageButtons
          history={history}
          isGenerateButtonDisabled={!formState.isDirty || isCSVGenerating}
          handleClearFilters={() => reset(defaultFormValues)}
          handleSubmit={handleSubmit(submitForm)}
        />
      }
    >
      { isCSVGenerating && <LoadingMessage message=<h3>Generating CSV... <LoadingIcon /></h3> />}
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
          ) : null
          }
          {watchReportType === 'event_type_action' &&
          watchRadioEventAction === 'specific_events_action' ? (
              <RHFCheckboxGroup
                options={REPORT_TYPE_CONSTANTS.SPECTIFIC_EVENT_OPTIONS}
                control={control}
                name="specificEventType"
              />
            ) : null
          }
          <ReportPageConditions />
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
