import React from 'react';
import PropTypes from 'prop-types';
import { useForm, FormProvider } from 'react-hook-form';
import { yupResolver } from '@hookform/resolvers/yup';

export const RequestIssueFormWrapper = (props) => {

  const methods = useForm({ defaultValues: {
    requestReason: '',
    nonratingIssueCategory: '',
  },
  mode: 'onChange',
  resolver: yupResolver(props.schema),
  reValidateMode: 'onSubmit' });

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
  currentIssue: PropTypes.object,
  schema: PropTypes.object
};

export default RequestIssueFormWrapper;
