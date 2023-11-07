import React from 'react';
import { useForm, FormProvider } from 'react-hook-form';
import { css } from 'glamor';
import PropTypes from 'prop-types';
import Button from 'app/components/Button';
import NonCompLayout from '../components/NonCompLayout';
import { ReportPageConditions } from '../components/ReportPage/ReportPageConditions';

import NonCompReportFilterContainer from '../components/NonCompReportFilter';
import { yupResolver } from '@hookform/resolvers/yup';
import * as yup from 'yup';

const buttonInnerContainerStyle = css({
  display: 'flex',
  gap: '32px',
});

const buttonOuterContainerStyling = css({
  display: 'flex',
  justifyContent: 'space-between',
  marginTop: '4rem',
});

const conditionOptionSchemas = {
  daysWaiting: yup.object({
    comparisonOperator: yup.string().oneOf(['lessThan', 'moreThan', 'equalTo', 'between'], 'Please select a time range.'),
    valueOne: yup.number().typeError('Please enter a number.').
      required('Please enter a number.').
      positive().
      integer(),
    valueTwo: yup.number().label('Max days').
      when('comparisonOperator', {
        is: 'between',
        then: (schema) => schema.typeError('Please enter a number.').moreThan(yup.ref('valueOne')).
          required('Please enter a number.'),
        otherwise: (schema) => schema.notRequired()
      })
  }),
  decisionReviewType: yup.object(),
  facility: yup.object(),
  issueDisposition: yup.object(),
  issueType: yup.object(),
  personnel: yup.object()
};
const schema = yup.object().shape({
  reportType: yup.string().oneOf(['event_type_action', 'status'], 'Please make a selection.'),
  conditions: yup.array().of(
    yup.lazy((value) => {
      return yup.object(
        { condition: yup.string().typeError('You must select a variable.').
          oneOf(['daysWaiting', 'decisionReviewType', 'facility', 'issueDisposition', 'issueType', 'personnel']).
          required(),
        options: conditionOptionSchemas[value.condition]
        });
    })
  )
});

const ReportPageButtons = ({ history,
  disableGenerateButton,
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
          disabled={disableGenerateButton}
        >
          Clear filters
        </Button>
        <Button
          classNames={['usa-button']}
          label="generate-report"
          name="generate-report"
          onClick={handleSubmit(onSubmit)}
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
    conditions: []
  };

  const methods = useForm({ defaultValues: { ...defaultFormValues },
    resolver: yupResolver(schema),
    mode: 'onSubmit',
    reValidateMode: 'onSubmit' });

  const { reset, formState, handleSubmit } = methods;

  return (
    <NonCompLayout
      buttons={
        <ReportPageButtons
          history={history}
          disableGenerateButton={!formState.isDirty}
          handleClearFilters={() => reset(defaultFormValues)}
          handleSubmit={handleSubmit}
        />
      }
    >
      <h1>Generate task report</h1>
      <FormProvider {...methods}>
        <form>
          <NonCompReportFilterContainer />
          <ReportPageConditions />
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
