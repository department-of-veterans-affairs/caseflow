import React from 'react';
import { FormProvider, useForm } from 'react-hook-form';
import { DocketSwitchAddAdminTaskForm } from './DocketSwitchAddAdminTaskForm';

export default {
  title: 'Queue/Docket Switch/DocketSwitchAddAdminTaskForm',
  component: DocketSwitchAddAdminTaskForm,
  decorators: [
    (storyFn) => {
      const methods = useForm();

      return <FormProvider {...methods}>{storyFn()}</FormProvider>;
    },
  ],
  parameters: {},
  args: {
    baseName: 'newTasks[0]',
  },
  argTypes: {
    onRemove: { action: 'onRemove' },
  },
};
const Template = (args) => <DocketSwitchAddAdminTaskForm {...args} />;

export const Basic = Template.bind({});
Basic.parameters = {
  docs: {
    storyDescription:
      'Used by attorney in Clerk of the Board office to complete a grant of a docket switch checkout flow ',
  },
};
