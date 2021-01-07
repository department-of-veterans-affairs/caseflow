import React from 'react';
import { FormProvider } from 'react-hook-form';

import { AddClaimantForm } from './AddClaimantForm';
import { useAddClaimantForm } from './utils';

const FormWrapper = ({ children }) => {
  const methods = useAddClaimantForm();

  return <FormProvider {...methods}>{children}</FormProvider>;
};

export default {
  title: 'Intake/Add Claimant/AddClaimantForm',
  component: AddClaimantForm,
  decorators: [
    (Story) => {
      return (
        <FormWrapper>
          <Story />
        </FormWrapper>
      );
    },
  ],
  parameters: {},
  argTypes: {
    onCancel: { action: 'cancel' },
    onSubmit: { action: 'submit' },
  },
};

const Template = (args) => <AddClaimantForm {...args} />;

export const Basic = Template.bind({});

Basic.parameters = {
  docs: {
    storyDescription:
      'This is used to add claimants not already associated with the appeal',
  },
};
