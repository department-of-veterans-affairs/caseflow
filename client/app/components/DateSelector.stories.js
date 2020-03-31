import React, { useState } from 'react';

import { action } from '@storybook/addon-actions';
import { withKnobs, text, boolean, select } from '@storybook/addon-knobs';

import DateSelector from './DateSelector';

export default {
  title: 'Commons/Components/DateSelector',
  component: DateSelector,
  decorators: [withKnobs]
};

export const allOptions = () => {
  const [value, setValue] = useState(text('Value', '', 'allOptions'));

  return (
    <DateSelector
      name={text('Name', 'datefield', 'allOptions')}
      errorMessage={text('Error Msg', '', 'allOptions')}
      dateErrorMessage={text('Date Error Msg', '', 'allOptions')}
      invisible={boolean('Invisible', false, 'allOptions')}
      label={text('Label', 'Date Field', 'allOptions')}
      onChange={(newVal) => {
        setValue(newVal);
        action('onChange', 'allOptions');
      }}
      readOnly={boolean('Read Only', false, 'allOptions')}
      required={boolean('Required', false, 'allOptions')}
      type={select('Type', ['date', 'datetime-local', 'text'], 'date', 'allOptions')}
      validationError={text('Validation Error', '', 'allOptions')}
      value={value}
    />
  );
};
