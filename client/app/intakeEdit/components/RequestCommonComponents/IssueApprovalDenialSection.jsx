import React from 'react';
import PropTypes from 'prop-types';
import { useFormContext, useController } from 'react-hook-form';
import Checkbox from 'app/components/Checkbox';
import RadioField from 'app/components/RadioField';
import TextareaField from 'app/components/TextareaField';

const DECISION_APPROVE = [
  {
    displayText: 'Approve request',
    value: 'approve'
  },
  {
    displayText: 'Reject request',
    value: 'reject'
  }
];

const IssueApprovalDenialSection = (displayCheckbox = false) => {
  const { register, watch, methods } = useFormContext();
  const watchApprove = watch('status');

  return (
    <>
      <DecisionRadio name="status" methods={methods} options={DECISION_APPROVE} />
      {(watchApprove === 'approve' && displayCheckbox) ?
        <RemoveOriginalIssueCheckbox option="removeOriginalIssue" name="removeOriginalIssue" methods={methods} /> : null}
      {watchApprove === 'reject' ? <TextareaField
        label="Provide a reason for rejection"
        name="decisionReason"
        inputRef={register}
      /> : null }
    </>
  );
};

const DecisionRadio = ({ name, control, options }) => {
  const { field } = useController({
    control,
    name,
  });

  return (
    <div style={{ marginTop: '20px' }}>
      <RadioField
        name=""
        label=""
        vertical
        options={options}
        stronglabel
        value={field.value}
        onChange={(val) => {
          field.onChange(val);
        }}
      />
    </div>
  );
};

const RemoveOriginalIssueCheckbox = ({ option, name, control }) => {
  const { field } = useController({
    control,
    name
  });

  const [value, setValue] = React.useState({});

  let fieldClasses = 'checkbox';

  return (
    <fieldset className={fieldClasses} style={{ paddingLeft: '30px' }}>
      <Checkbox
        name={name}
        key={`${name}-${option}`}
        label="Remove original issue"
        stronglabel
        onChange={(val) => {
          setValue(value);
          field.onChange(val);
        }}
        unpadded
      />
    </fieldset>
  );
};

DecisionRadio.propTypes = {
  control: PropTypes.object,
  name: PropTypes.string,
  options: PropTypes.object
};

RemoveOriginalIssueCheckbox.propTypes = {
  option: PropTypes.array,
  control: PropTypes.object,
  name: PropTypes.string
};

export default IssueApprovalDenialSection;
