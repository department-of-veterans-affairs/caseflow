import React from 'react';
import PropTypes from 'prop-types';
import { useForm, FormProvider } from 'react-hook-form';

export const RequestIssueFormWrapper = (props) => {

  const methods = useForm({ defaultValues: {
    requestReason: '',
    issueType: '',
  },
  mode: 'onSubmit',
  reValidateMode: 'onSubmit' });

  const onSubmit = (data) => console.log(data);

  return (
    <div>
      <FormProvider {...methods}>
        <form>
          {props.children}
        </form>
      </FormProvider>
    </div>
  );
};

RequestIssueFormWrapper.propTypes = {
  onCancel: PropTypes.func,
  currentIssue: PropTypes.object
};

export default RequestIssueFormWrapper;
