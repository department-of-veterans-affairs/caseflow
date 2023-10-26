import React from 'react';
import { css } from 'glamor';
import PropTypes from 'prop-types';
import Button from 'app/components/Button';
import NonCompLayout from '../components/NonCompLayout';
import { useForm, FormProvider, useFormContext } from 'react-hook-form';
import { ReportPageConditions } from '../components/ReportPage/ReportPageConditions';

const buttonInnerContainerStyle = css({
  display: 'flex',
  gap: '32px'
});

const buttonOuterContainerStyling = css({
  display: 'flex',
  justifyContent: 'space-between',
  marginTop: '4rem'
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

const ReportPageButtons = ({ history }) => {
  const { handleSubmit } = useFormContext();

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

const ReportPage = ({ history }) => {
  const methods = useForm({ defaultValues: {
    conditions: []
  } });

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
