import React from 'react';
import PropTypes from 'prop-types';
import { useForm, FormProvider } from 'react-hook-form';
import { yupResolver } from '@hookform/resolvers/yup';
import Modal from 'app/components/Modal';
import _ from 'lodash';

export const RequestIssueFormWrapper = (props) => {

  const methods = useForm({
    defaultValues: {
      requestReason: '',
      nonratingIssueCategory: '',
    },
    mode: 'onChange',
    resolver: yupResolver(props.schema),
    reValidateMode: 'onSubmit' });

  const { handleSubmit, formState } = methods;

  const onSubmit = (data) => {
    const enhancedData = {
      ...(props.currentIssue) && { requestIssueId: props.currentIssue.id },
      requestType: _.capitalize(props.type),
      ...data };

    console.log(enhancedData); // add to state later once Sean is done

    props.onCancel();
  };

  return (
    <div>
      <FormProvider {...methods}>
        <form>
          <Modal
            title={`Request issue ${props.type}`}
            buttons={[
              { classNames: ['cf-modal-link', 'cf-btn-link', 'close-modal'],
                name: 'Cancel',
                onClick: props.onCancel
              },
              {
                classNames: ['usa-button', 'usa-button-primary'],
                name: 'Submit request',
                onClick: handleSubmit(onSubmit),
                disabled: !formState.isValid
              }
            ]}
            closeHandler={props.onCancel}
          >
            {props.children}
          </Modal>
        </form>
      </FormProvider>
    </div>
  );
};

RequestIssueFormWrapper.propTypes = {
  onCancel: PropTypes.func,
  currentIssue: PropTypes.object,
  schema: PropTypes.object,
  type: PropTypes.string
};

export default RequestIssueFormWrapper;
