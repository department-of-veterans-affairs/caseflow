import React from 'react';

import faker from 'faker';

import { action } from '@storybook/addon-actions';
import { withKnobs, text, boolean, select } from '@storybook/addon-knobs';

import SearchableDropdown from './SearchableDropdown';

const options = [
  { label: 'Option 1', value: 'value1' },
  { label: 'Option 2', value: 'value2' },
  { label: 'Option 3', value: 'value3' },
  { label: 'Option 4', value: 'value4' }
];

export default {
  title: 'Commons/Components/SearchableDropdown',
  component: SearchableDropdown,
  decorators: [withKnobs]
};

export const basic = () => {
  return (
    <div style={{ minWidth: '300px' }}>
      <SearchableDropdown name="basic" options={options} />
    </div>
  );
};

export const label = () => {
  return (
    <div style={{ minWidth: '300px' }}>
      <SearchableDropdown
        name="label"
        label="Custom Label Text"
        options={options}
      />
    </div>
  );
};

export const defaultValue = () => {
  return (
    <div style={{ minWidth: '300px' }}>
      <SearchableDropdown
        name="defaultValue"
        label="Select an Option"
        options={options}
        value={options[2]}
      />
    </div>
  );
};

export const readOnly = () => {
  return (
    <div style={{ minWidth: '300px' }}>
      <SearchableDropdown
        name="label"
        label="Custom Label Text"
        options={options}
        readOnly
      />
    </div>
  );
};

export const async = () => {
  const wait = (delay) =>
    new Promise((resolve) => setTimeout(() => resolve(), delay));

  const data = Array.from({ length: 250 }, () => ({
    label: faker.name.findName(),
    value: faker.random.number()
  }));

  // Simple string search for mocking
  const fetchFn = async (search = '') => {
    const regex = RegExp(search, 'i');

    return data.filter((item) => regex.test(item.label));
  };

  const asyncFn = async (search = '') => {
    // Mock a delay for fetch
    await wait(750);

    const results = await fetchFn(search);

    return { options: results };
  };

  return (
    <div style={{ minWidth: '300px' }}>
      <SearchableDropdown
        name="async"
        label="Select an Option"
        async={asyncFn}
      />
    </div>
  );
};
