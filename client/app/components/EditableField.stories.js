import React from 'react';

import EditableField from './EditableField';

const Template = (args) => {
  const [value, setValue] = React.useState(args.value || '');

  React.useEffect(() => setValue(args.value), [args.value]);

  return <EditableField {...args} value={value} onChange={setValue} />;
};

export const Default = Template.bind({});
Default.args = {
  label: 'Click "Edit" to change the value below',
};

export const Error = Template.bind({});
Error.args = { errorMessage: 'This is invalid' };

export const Label = Template.bind({});
Label.args = { label: 'This is a new label' };

export const MaxLength = Template.bind({});
MaxLength.args = {
  maxLength: 30,
  label: 'Enter more text below (max 30)',
  value: 'This is exactly 29 characters',
};

export const Placeholder = Template.bind({});
Placeholder.args = {
  placeholder: 'This is a placeholder',
  value: '',
  label: 'Click "Edit" to see placeholder text',
};

export const Title = Template.bind({});
Title.args = {
  label: 'Click "Edit" and hover over the input field',
  title: 'This is the title text',
};

export const Type = Template.bind({});
Type.args = {
  type: 'date',
  value: '2020-12-22',
  label: 'Click "Edit" to select a new date',
};
