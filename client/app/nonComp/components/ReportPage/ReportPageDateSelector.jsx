import React from 'react';
import { useController } from 'react-hook-form';
import PropTypes from 'prop-types';

import DateSelector from 'app/components/DateSelector';

const ReportPageDateSelector = ({ name, label, control }) => {
  const { field } = useController({
    control,
    name,
    label
  });

  return (
    <fieldset style={{ marginTop: '35px' }}>
      <div key={`${name}_1`}>
        <DateSelector
          name={`${name}_1`}
          key={`${name}_1`}
          label={label}
          stronglabel
          onChange={(val) => {
            field.onChange(val);
          }}
          type="date"
          noFutureDates
        />
      </div>
    </fieldset>
  );
};

ReportPageDateSelector.propTypes = {
  name: PropTypes.string,
  label: PropTypes.string,
  control: PropTypes.object
};

export default ReportPageDateSelector;
