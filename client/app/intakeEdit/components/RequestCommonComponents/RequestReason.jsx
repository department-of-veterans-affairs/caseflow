import React from 'react';
import PropTypes from 'prop-types';
import TextareaField from 'app/components/TextareaField';
import _ from 'lodash';
import { useFormContext } from 'react-hook-form';

export const RequestReason = (props) => {
  const { register, errors } = useFormContext();

  return (
    <div>
      <h3 style={{ marginBottom: '0px' }}>{_.capitalize(props.label)} request reason</h3>
      <TextareaField
        name="requestReason"
        label={`Please provide a reason for the issue ${props.label} request`}
        inputRef={register}
        errorMessage={errors.requestReason?.message}
      />
    </div>

  );
};

RequestReason.propTypes = {
  label: PropTypes.string,
};

export default RequestReason;
