import React, { useState } from 'react';

import faker from 'faker';

import { action } from '@storybook/addon-actions';

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
  decorators: [
    (storyFn) => (
      <div style={{ minWidth: '300px', maxWidth: '400px' }}>{storyFn()}</div>
    )
  ]
};

export const basic = () => {
  return <SearchableDropdown name="basic" options={options} />;
};

export const label = () => {
  return (
    <SearchableDropdown
      name="label"
      label="Custom Label Text"
      options={options}
    />
  );
};

export const defaultValue = () => {
  return (
    <SearchableDropdown
      name="defaultValue"
      label="Select an Option"
      options={options}
      value={options[2]}
    />
  );
};

export const readOnly = () => {
  return (
    <SearchableDropdown
      name="label"
      label="Custom Label Text"
      options={options}
      readOnly
    />
  );
};

export const controlled = () => {
  const [value, setValue] = useState(options[1]);
  const handleChange = (val) => setValue(val);

  return (
    <SearchableDropdown
      name="controlled"
      label="Value Controlled Externally"
      options={options}
      value={value}
      onChange={handleChange}
    />
  );
};

export const clearOnSelect = () => {
  const [value, setValue] = useState(options[1]);
  const handleChange = (val) => {
    action('onChange')(val);
    // setValue(null);
  };

  return (
    <SearchableDropdown
      name="controlled"
      label="Clears Control upon Selection"
      options={options}
      value={value}
      onChange={handleChange}
      clearOnSelect
    />
  );
};

export const multiple = () => {
  return (
    <SearchableDropdown
      name="multiple"
      label="Select Multiple"
      options={options}
      multi
    />
  );
};

export const creatable = () => {
  return (
    <SearchableDropdown
      name="creatable"
      label="Supports Adding Custom Option"
      options={options}
      creatable
    />
  );
};

export const creatableMultiple = () => {
  return (
    <SearchableDropdown
      name="creatableMultiple"
      label="Supports Adding Custom Options"
      options={options}
      creatable
      multi
    />
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

    return await fetchFn(search);
  };

  return (
    <SearchableDropdown name="async" label="Select an Option" async={asyncFn} />
  );
};
