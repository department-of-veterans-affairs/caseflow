import React from 'react';

import faker from 'faker';

import { useArgs } from '@storybook/client-api';
import { action } from '@storybook/addon-actions';

import SearchableDropdown from './SearchableDropdown';

const options = [
  { label: 'Option 1', value: 'value1' },
  { label: 'Option 2', value: 'value2' },
  { label: 'Option 3', value: 'value3' },
  { label: 'Option 4', value: 'value4' },
];

export default {
  title: 'Commons/Components/SearchableDropdown',
  component: SearchableDropdown,
  decorators: [
    (storyFn) => (
      <div style={{ minWidth: '300px', maxWidth: '400px' }}>{storyFn()}</div>
    ),
  ],
  args: {
    options,
  },
  argTypes: {
    onChange: { action: 'onChange' },
  }
};

const Template = (args) => <SearchableDropdown {...args} />;

export const Basic = Template.bind({});
Basic.args = { name: 'basic' };

export const Label = Template.bind({});
Label.args = { name: 'label', label: 'Custom Label Text' };

export const DefaultValue = Template.bind({});
DefaultValue.args = {
  name: 'defaultValue',
  label: 'Select an Option',
  value: options[2],
};

export const ReadOnly = Template.bind({});
ReadOnly.args = {
  name: 'readOnly',
  label: 'I am readonly',
  value: options[2],
  readOnly: true,
};

export const ErrorMessage = Template.bind({});
ErrorMessage.args = {
  name: 'error',
  label: 'Custom Label Text',
  errorMessage: 'Something is wrong',
};

export const Controlled = (args) => {
  // eslint-disable-next-line no-unused-vars
  const [_args, updateArgs] = useArgs();

  const handleChange = (val) => {
    updateArgs({ value: val });
    args.onChange(val);
  };

  return <SearchableDropdown {...args} onChange={handleChange} />;
};
Controlled.args = {
  name: 'controlled',
  label: 'Value Controlled Externally',
  value: options[1],
};

export const ClearOnSelect = (args) => {
  const handleChange = (val) => {
    args.onChange(val);
  };

  return <SearchableDropdown {...args} onChange={handleChange} />;
};
ClearOnSelect.args = {
  name: 'clearOnSelect',
  label: 'Clears Control upon Selection',
  value: options[1],
  clearOnSelect: true,
};

export const Multiple = Template.bind({});
Multiple.args = {
  name: 'multiple',
  label: 'Select multiple',
  value: options[2],
  multi: true,
};

export const Creatable = Template.bind({});
Creatable.args = {
  name: 'creatable',
  label: 'Supports Adding Custom Option',
  creatable: true,
};

export const CreatableMultiple = Template.bind({});
CreatableMultiple.args = {
  name: 'creatableMultiple',
  label: 'Supports Adding Custom Options',
  creatable: true,
  multi: true,
};

export const async = () => {
  const wait = (delay) =>
    new Promise((resolve) => setTimeout(() => resolve(), delay));

  const data = Array.from({ length: 250 }, () => ({
    label: faker.name.findName(),
    value: faker.random.number(),
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

export const NoResultsText = Template.bind({});
NoResultsText.args = {
  name: 'noResultsText',
  options: [],
  noResults: 'Your results are in another castle'
};
