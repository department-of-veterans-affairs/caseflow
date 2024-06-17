import React from 'react';
import PropTypes from 'prop-types';
import { useFormContext, useController, useForm } from 'react-hook-form';
import Checkbox from 'app/components/Checkbox';
import RadioField from 'app/components/RadioField';
import TextareaField from 'app/components/TextareaField';

const DECISION_APPROVE = [
  {
    displayText: 'Approve request',
    value: 'approved'
  }
];
const DECISION_REJECT = [
  {
    displayText: 'Reject request',
    value: 'rejected'
  }
];

const RequestIssueStatus = ({ displayCheckbox = false }) => {
  const { register, methods, watch } = useFormContext();
  const { setValue } = useForm();

  const watchStatus = watch('status');
  // const [status, setStatus] = React.useState({});

  return (
    <>
      <RadioField
        name="status"
        key="statusApprove-1"
        label=""
        vertical
        options={DECISION_APPROVE}
        // value={status}
        // value={field.value}
        hideLabel
        onChange={(val) => {
          // setStatus(val);
          setValue('status', val);
        }}
        inputRef={register}
      />
      {(watchStatus === 'approved' && displayCheckbox) ?
        <RemoveOriginalIssueCheckbox option="removeOriginalIssue" name="removeOriginalIssue" methods={methods} /> :
        null}
      <RadioField
        name="status"
        key="statusReject-1"
        label=""
        vertical
        options={DECISION_REJECT}
        hideLabel
        // value={status}
        onChange={(val) => {
          // setStatus(val);
          setValue('status', val);
        }}
        inputRef={register}
      />
      {watchStatus === 'rejected' ? <TextareaField
        label="Provide a reason for rejection"
        name="decisionReason"
        inputRef={register}
      /> : null }
    </>
  );
};

const RemoveOriginalIssueCheckbox = ({ option, name, control }) => {
  const { field } = useController({
    control,
    name
  });

  let fieldClasses = 'checkbox';

  return (
    <fieldset className={fieldClasses} style={{ paddingLeft: '30px' }}>
      <Checkbox
        name={name}
        key={`${name}-${option}`}
        label="Remove original issue"
        stronglabel
        onChange={(val) => {
          field.onChange(val);
        }}
        unpadded
      />
    </fieldset>
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
