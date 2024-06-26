import React from 'react';
import PropTypes from 'prop-types';
import { useFormContext, useController, useForm } from 'react-hook-form';
import Checkbox from 'app/components/Checkbox';
import RadioField from 'app/components/RadioField';
import TextareaField from 'app/components/TextareaField';
import * as yup from 'yup';

const DECISION_APPROVE = [
  {
    displayText: 'Approve request',
    value: 'approved'
  }
];
const DECISION_REJECT = [
  {
    displayText: 'Reject request',
    value: 'denied'
  }
];

export const statusSchema = yup.lazy((value) => {
  // eslint-disable-next-line no-undefined
  if (value !== undefined) {
    return yup.mixed().oneOf(['approved', 'denied']);
  }

  return yup.mixed().notRequired();
});

export const decisionReasonSchema = yup.string().when('status', {
  is: 'denied',
  then: (schema) => schema.required(),
  otherwise: (schema) => schema.notRequired()
});

export const RequestIssueStatus = ({ displayCheckbox = false }) => {
  const { register, methods, watch } = useFormContext();
  const { setValue } = useForm();

  const watchStatus = watch('status');

  return (
    <>
      <RadioField
        name="status"
        key="statusApprove-1"
        label=""
        vertical
        options={DECISION_APPROVE}
        hideLabel
        onChange={(val) => {
          setValue('status', val);
        }}
        inputRef={register}
      />
      {(watchStatus === 'approved' && displayCheckbox) ?
        <RemoveOriginalIssueCheckbox name="removeOriginalIssue" methods={methods} /> :
        null}
      <RadioField
        name="status"
        key="statusReject-1"
        label=""
        vertical
        options={DECISION_REJECT}
        optionsStyling= {{ marginTop: 0 }}
        hideLabel
        onChange={(val) => {
          setValue('status', val);
        }}
        inputRef={register}
      />
      {watchStatus === 'denied' ? <TextareaField
        label="Provide a reason for rejection"
        name="decisionReason"
        inputRef={register}
      /> : null }
    </>
  );
};

const RemoveOriginalIssueCheckbox = ({ name, control }) => {
  const { field } = useController({
    control,
    name
  });

  let fieldClasses = 'checkbox';

  return (
    <div className={fieldClasses} style={{ paddingLeft: '30px' }}>
      <Checkbox
        name={name}
        key={`${name}`}
        label="Remove original issue"
        stronglabel
        onChange={(val) => {
          field.onChange(val);
        }}
        unpadded
      />
    </div>
  );
};

RemoveOriginalIssueCheckbox.propTypes = {
  option: PropTypes.array,
  control: PropTypes.object,
  name: PropTypes.string
};

RequestIssueStatus.propTypes = {
  displayCheckbox: PropTypes.bool,
};

export default RequestIssueStatus;
