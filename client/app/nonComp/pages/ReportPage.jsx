import React from 'react';
import { useForm, FormProvider } from 'react-hook-form';
import { css } from 'glamor';
import PropTypes from 'prop-types';
import Button from 'app/components/Button';
import NonCompLayout from '../components/NonCompLayout';
import { ReportPageConditions } from '../components/ReportPage/ReportPageConditions';

import NonCompReportFilterContainer from '../components/NonCompReportFilter';

const buttonInnerContainerStyle = css({
  display: 'flex',
  gap: '32px',
});

const buttonOuterContainerStyling = css({
  display: 'flex',
  justifyContent: 'space-between',
  marginTop: '4rem',
});

// for later
// const schema = yup.object().shape({
//   conditions: yup.array(
//     yup.object().shape({
//       condition: yup.string().required(),
//       options: yup.object().required(),
//     })
//   ),
// });

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

  const methods = useForm({ defaultValues: { ...defaultFormValues } });

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
