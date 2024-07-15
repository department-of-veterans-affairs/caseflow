import React from 'react';
import PropTypes from 'prop-types';
import TextareaField from 'app/components/TextareaField';
import { capitalize } from 'lodash';
import { useFormContext } from 'react-hook-form';

export const RequestReason = ({ label }) => {
  const { register } = useFormContext();

  return (
    <div>
      <h3 style={{ marginBottom: '0px' }}>{capitalize(label)} request reason</h3>
      <TextareaField
        name="requestReason"
        label={`Please provide a reason for the issue ${label} request`}
        inputRef={register}
      />
    </div>

  );
};

RequestReason.propTypes = {
  label: PropTypes.string,
};

export default RequestReason;
