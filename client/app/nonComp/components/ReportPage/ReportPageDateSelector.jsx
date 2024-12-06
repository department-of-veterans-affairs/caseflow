import React from 'react';
import { useController } from 'react-hook-form';
import PropTypes from 'prop-types';

import DateSelector from 'app/components/DateSelector';
import { marginTop } from 'app/hearings/components/details/style';

const ReportPageDateSelector = ({ name, label, control, errorMessage }) => {
  const { field } = useController({
    control,
    name,
    label
  });

  return (
    <fieldset style={{ marginTop: '35px' }}>
      <div key={`date-selector-container-${name}`}>
        <DateSelector
          name={`${name}_1`}
          key={`date-selector-${name}`}
          label={label}
          stronglabel
          value={field.value}
          onChange={(val) => {
            field.onChange(val);
          }}
          type="date"
          noFutureDates
          inputStyling={marginTop('0 !important')}
          errorMessage={errorMessage}
        />
      </div>
    </fieldset>
  );
};

ReportPageDateSelector.propTypes = {
  name: PropTypes.string,
  label: PropTypes.string,
  control: PropTypes.object,
  errorMessage: PropTypes.string
};

export default ReportPageDateSelector;
