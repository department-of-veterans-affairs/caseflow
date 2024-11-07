/* eslint-disable max-lines */
import React, { useEffect, useState } from 'react';
import { useController, useForm, FormProvider, useFormContext } from 'react-hook-form';
import { useDispatch, useSelector } from 'react-redux';
import { downloadReportCSV } from 'app/nonComp/actions/changeHistorySlice';
import { css } from 'glamor';
import PropTypes from 'prop-types';

import Alert from 'app/components/Alert';
import ErrorAlert from 'app/intake/components/ErrorAlert';
import Button from 'app/components/Button';
import Link from 'app/components/Link';
import NonCompLayout from '../components/NonCompLayout';
import { conditionsSchema, ReportPageConditions } from '../components/ReportPage/ReportPageConditions';

import { yupResolver } from '@hookform/resolvers/yup';
import * as yup from 'yup';
import { fetchUsers } from 'app/nonComp/actions/usersSlice';

import RHFControlledDropdownContainer from 'app/nonComp/components/ReportPage/RHFControlledDropdown';
import SaveSearchModal from 'app/nonComp/components/ReportPage/SaveSearchModal';
import SaveLimitReachedModal from 'app/nonComp/components/ReportPage/SaveLimitReachedModal';
import { timingSchema, TimingSpecification } from 'app/nonComp/components/ReportPage/TimingSpecification';

import Checkbox from 'app/components/Checkbox';
import RadioField from 'app/components/RadioField';
import { saveUserSearch, fetchedSearches } from '../../nonComp/actions/savedSearchSlice';
import { get } from 'lodash';
import COPY from 'app/../COPY';

import {
  REPORT_TYPE_OPTIONS,
  RADIO_EVENT_TYPE_OPTIONS,
  RADIO_STATUS_OPTIONS,
  RADIO_STATUS_REPORT_TYPE_OPTIONS,
  SPECIFIC_STATUS_OPTIONS,
  SPECIFIC_EVENT_OPTIONS
} from 'constants/REPORT_TYPE_CONSTANTS';
import * as ERRORS from 'constants/REPORT_PAGE_VALIDATION_ERRORS';

const buttonInnerContainerStyle = css({
  display: 'flex',
  gap: '32px',
});

const buttonOuterContainerStyling = css({
  display: 'flex',
  justifyContent: 'space-between',
  marginTop: '4rem',
});

const outerContainerStyling = css({
  display: 'flex',
  justifyContent: 'space-between',
  paddingLeft: '30px',
  gap: '3em',
});

const specificEventTypeSchema = yup.lazy((value) => {
  // eslint-disable-next-line no-undefined
  if (value === undefined) {
    return yup.mixed().notRequired();
  }

  return yup.object({
    added_decision_date: yup.boolean(),
    added_issue: yup.boolean(),
    added_issue_no_decision_date: yup.boolean(),
    removed_issue: yup.boolean(),
    withdrew_issue: yup.boolean(),
    completed_disposition: yup.boolean(),
    claim_created: yup.boolean(),
    claim_closed: yup.boolean(),
    claim_status_incomplete: yup.boolean(),
    claim_status_pending: yup.boolean(),
    claim_status_inprogress: yup.boolean(),
    requested_issue_modification: yup.boolean(),
    requested_issue_addition: yup.boolean(),
    requested_issue_removal: yup.boolean(),
    requested_issue_withdrawal: yup.boolean(),
    approval_of_request: yup.boolean(),
    rejection_of_request: yup.boolean(),
    cancellation_of_request: yup.boolean(),
    edit_of_request: yup.boolean(),
  }).test('at-least-one-true', ERRORS.AT_LEAST_ONE_OPTION, (obj) => {
    return Object.values(obj).some((val) => val === true);
  });
});

const specificStatusSchema = yup.lazy((value) => {
  // eslint-disable-next-line no-undefined
  if (value === undefined) {
    return yup.mixed().notRequired();
  }

  return yup.object({
    incomplete: yup.boolean(),
    in_progress: yup.boolean(),
    completed: yup.boolean(),
  }).test('at-least-one-true', ERRORS.AT_LEAST_ONE_OPTION, (obj) => {
    return Object.values(obj).some((val) => val === true);
  });
});

const schema = yup.object().shape({
  conditions: conditionsSchema,
  timing: timingSchema,
  specificEventType: specificEventTypeSchema,
  specificStatus: specificStatusSchema
});

const ReportPageButtons = ({
  history,
  isGenerateButtonDisabled,
  handleClearFilters,
  handleSubmit,
  handleSaveSearch,
  loading,
  loadingText }) => {
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
          classNames={['usa-button-secondary']}
          label="save-search"
          name="save_search"
          onClick={handleSaveSearch}
          disabled={isGenerateButtonDisabled}
        >
          Save search
        </Button>
        <Button
          classNames={['usa-button-secondary']}
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
          loading={loading}
          loadingText={loadingText}
        >
          Generate task report
        </Button>
      </div>
    </div>
  );
};

const EventCheckboxGroup = ({ header, options, name, onChange }) => {

  return (
    <div>
      { header && <h4>{header}</h4> }
      {options.map((option) => (
        <div key={option.id}>
          <Checkbox
            name={`${name}.${option.id}`}
            key={`${name}.${option.id}`}
            label={option.label}
            stronglabel
            unpadded
            onChange={(val) => onChange({ option, val })}
          />
        </div>
      ))}
    </div>
  );
};

const RHFCheckboxGroup = ({ options, name, control }) => {
  const { errors } = useFormContext();

  let fieldClasses = 'checkbox';
  const errorMessage = get(errors, name)?.message;

  const { field } = useController({
    control,
    name
  });

  if (errorMessage) {
    fieldClasses += ' usa-input-error';
    fieldClasses += ' less-error-padding';
  }

  const [value, setValue] = React.useState({});

  const onCheckboxClick = ({ option, val }) => {
    value[option.id] = val;
    field.onChange(value);
    setValue(value);
  };

  const messageStyling = css({
    fontSize: '17px !important',
    paddingTop: '2px !important'
  });

  return (
    <div>
      {name === 'specificEventType' ?
        <fieldset>
          {errorMessage &&
            <Alert
              type="error"
              message={ERRORS.AT_LEAST_ONE_CHECKBOX_OPTION}
              messageStyling={messageStyling}
            />
          }
          <div {...outerContainerStyling} style={{ paddingTop: '30px' }} >
            <EventCheckboxGroup
              header="System"
              options={options[0].system}
              name={name}
              onChange={onCheckboxClick}
            />
            <EventCheckboxGroup
              header="General"
              options={options[0].general}
              name={name}
              onChange={onCheckboxClick}
            />
            <EventCheckboxGroup
              header="Requests"
              options={options[0].requests}
              name={name}
              onChange={onCheckboxClick}
            />
          </div>
        </fieldset> :
        <fieldset className={fieldClasses} style={{ paddingLeft: '30px' }}>
          {errorMessage ? <div className="usa-input-error-message">{ errorMessage }</div> : null}
          <EventCheckboxGroup
            options={options}
            name={name}
            onChange={onCheckboxClick}
          />
        </fieldset>
      }
    </div>
  );
};

const RHFRadioButton = ({ options, name, control, label }) => {
  const { field } = useController({
    control,
    name,
  });

  return (
    <div style={{ marginTop: '20px' }}>
      <RadioField
        name=""
        label={label}
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
    radioStatus: 'all_statuses',
    radioStatusReportType: 'last_action_taken',
    specificStatus: {
      incomplete: '',
      in_progress: '',
      pending: '',
      completed: '',
      cancelled: ''
    },
    specificEventType: {
      claim_created: '',
      claim_closed: '',
      claim_status_incomplete: '',
      claim_status_pending: '',
      claim_status_inprogress: '',
      added_decision_date: '',
      added_issue: '',
      added_issue_no_decision_date: '',
      removed_issue: '',
      withdrew_issue: '',
      completed_disposition: '',
      requested_issue_modification: '',
      requested_issue_addition: '',
      requested_issue_removal: '',
      requested_issue_withdrawal: '',
      approval_of_request: '',
      rejection_of_request: '',
      cancellation_of_request: '',
      edit_of_request: '',
    }
  };

  const methods = useForm({
    defaultValues: { ...defaultFormValues },
    resolver: yupResolver(schema),
    mode: 'onSubmit',
    reValidateMode: 'onSubmit'
  });

  const { reset, watch, formState, control, handleSubmit } = methods;
  const dispatch = useDispatch();
  const businessLineUrl = useSelector((state) => state.nonComp.businessLineUrl);
  const csvGeneration = useSelector((state) => state.changeHistory.status);
  const saveSearchStatus = useSelector((state) => state.savedSearch.status);
  const saveSearchAlertTitle = useSelector((state) => state.savedSearch.message);
  const userSearches = useSelector((state) => state.savedSearch.fetchedSearches?.userSearches);
  const isCSVGenerating = csvGeneration === 'loading';
  const watchReportType = watch('reportType');
  const watchRadioEventAction = watch('radioEventAction');
  const watchRadioStatus = watch('radioStatus');

  const [showModal, setShowModal] = useState(false);

  const saveLimitCount = userSearches.length;

  const processConditionOptions = (condition, options) => {
    let formattedOptions;

    switch (condition) {
    // Multi select conditions
    case 'personnel':
    case 'facility':
    case 'issueDisposition':
    case 'issueType':
    case 'decisionReviewType':
      formattedOptions = Object.values(options)[0].map((item) => item.value);
      break;
    // Else it is probably already an object, so it just pass the existing options
    default:
      formattedOptions = options;
    }

    return formattedOptions;
  };

  const parseFilters = (data) => {
    const filters = {};

    // Add report type to the filter
    filters.reportType = data.reportType;

    // Event specific event types to the filter
    if (data.radioEventAction === 'specific_events_action') {
      filters.events = Object.keys(data.specificEventType).filter((key) => data.specificEventType[key] === true);
    }

    // Add specific status types to the filter
    if (data.radioStatus === 'specific_status') {
      filters.statuses = Object.keys(data.specificStatus).filter((key) => data.specificStatus[key] === true);
    }

    // Add timing to the filter
    filters.timing = data.timing;

    // Add Status report type to the filter
    filters.statusReportType = data.radioStatusReportType;

    // Parse all the Conditions and add them to the filter
    const transformedConditions = data?.conditions?.reduce((result, item) => {
      const { condition, options } = item;

      if (condition && options) {
        // Parse the individual conditions
        const newOptions = processConditionOptions(condition, options);

        result[condition] = newOptions;
      }

      return result;
    }, {});

    // Add the all the parsed conditions into the filters
    Object.assign(filters, transformedConditions);

    return filters;
  };

  const submitForm = (data) => {
    const filterData = parseFilters(data);

    // Generate and trigger the download of the CSV
    dispatch(downloadReportCSV({ organizationUrl: businessLineUrl, filterData: { filters: filterData } }));
  };

  const handleSave = (data) => {
    dispatch(saveUserSearch(data));
    setShowModal(true);
  };

  useEffect(() => {
    dispatch(fetchUsers({ queryType: 'organization', queryParams: { query: 'vha' } }));
  }, []);

  useEffect(() => {
    dispatch(fetchedSearches({ organizationUrl: businessLineUrl }));
  }, []);

  return (<>
    { saveSearchStatus === 'succeeded' ?
      <Alert
        type="success"
        title={saveSearchAlertTitle}
        message={COPY.SEARCH_ALERT_DESCRIPTION}
        scrollOnAlert={false} /> :
      null
    }
    { saveSearchStatus === 'failed' ?
      <Alert title="Something went wrong" type="error">
        If you continue to see this page, please contact the Caseflow team
        via the VA Enterprise Service Desk at 855-673-4357 or by creating a ticket
        via <a href="https://yourit.va.gov" target="_blank" rel="noopener noreferrer">YourIT</a>.
      </Alert> :
      null
    }
    <NonCompLayout
      buttons={
        <ReportPageButtons
          history={history}
          isGenerateButtonDisabled={!formState.isDirty}
          handleClearFilters={() => reset()}
          handleSubmit={handleSubmit(submitForm)}
          handleSaveSearch={handleSubmit(handleSave)}
          loading={isCSVGenerating}
          loadingText="Generating CSV"
        />
      }
    >
      <div className="report-page-header">
        <h1>Generate task report</h1>
        <Link button="secondary" to={`/${businessLineUrl}/searches`}>View saved searches</Link>
      </div>
      <FormProvider {...methods}>
        <form>
          <RHFControlledDropdownContainer
            header="Type of report"
            name="reportType"
            label="Report Type"
            options={REPORT_TYPE_OPTIONS}
          />
          {watchReportType === 'status' ? (<>
            <RHFRadioButton
              options={RADIO_STATUS_OPTIONS}
              methods={methods}
              name="radioStatus"
            />
            {watchRadioStatus === 'specific_status' ? (
              <RHFCheckboxGroup
                options={SPECIFIC_STATUS_OPTIONS}
                control={control}
                name="specificStatus"
              />) :
              null
            }
            <RHFRadioButton
              options={RADIO_STATUS_REPORT_TYPE_OPTIONS}
              methods={methods}
              label="Select type of status report"
              name="radioStatusReportType"
            />
          </>) :
            null
          }
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
                options={SPECIFIC_EVENT_OPTIONS}
                control={control}
                name="specificEventType"
              />
            ) : null
          }
          {watchReportType === 'event_type_action' ?
            <TimingSpecification /> :
            null
          }
          { showModal && saveLimitCount < 10 ?
            <SaveSearchModal setShowModal={setShowModal} /> : null
          }
          { showModal && (saveLimitCount >= 10) ?
            <SaveLimitReachedModal setShowLimitModal={setShowModal} /> : null
          }
          {formState.isDirty ? <ReportPageConditions /> : null}
        </form>
      </FormProvider>
    </NonCompLayout>
  </>
  );
};

ReportPageButtons.propTypes = {
  history: PropTypes.object,
  isGenerateButtonDisabled: PropTypes.bool,
  handleClearFilters: PropTypes.func,
  handleSubmit: PropTypes.func,
  handleSaveSearch: PropTypes.func,
  loading: PropTypes.bool,
  loadingText: PropTypes.string,
};

ReportPage.propTypes = {
  history: PropTypes.object,
};

RHFCheckboxGroup.propTypes = {
  options: PropTypes.array,
  control: PropTypes.object,
  name: PropTypes.string,
  errorMessage: PropTypes.string
};

EventCheckboxGroup.propTypes = {
  options: PropTypes.array,
  onChange: PropTypes.func,
  header: PropTypes.string,
  name: PropTypes.string
};

RHFRadioButton.propTypes = {
  options: PropTypes.array,
  control: PropTypes.object,
  label: PropTypes.string,
  name: PropTypes.string
};

export default ReportPage;
/* eslint-enable max-lines */
