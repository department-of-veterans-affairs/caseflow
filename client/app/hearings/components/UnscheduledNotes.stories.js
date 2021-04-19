import React, { useState } from 'react';

import { UnscheduledNotes } from './UnscheduledNotes';

export default {
  title: 'Hearings/Components/UnscheduledNotes',
  component: UnscheduledNotes,
  parameters: {
    docs: {
      inlineStories: false,
      iframeHeight: 760,
    },
  },
};

const Template = (args) => {
  const [notes, setNotes] = useState(args.unscheduledNotes ?? '')
  return (
    <UnscheduledNotes
      {...args}
      onChange={(...params) => {
        args.onChange(...params);
        setNotes(...params);
      }}
      unscheduledNotes={notes}
    />
  )
}

export const Basic = Template.bind({});
Basic.args = {
  updatedByCssId: 'VACOUSER',
  updatedAt: '2020-09-08T10:03:49.210-04:00',
  unscheduledNotes: 'Type notes here',
  onChange: () => {}
}

export const FirstEdit = Template.bind({});
FirstEdit.args = {
  onChange: () => {},
  unscheduledNotes: ''
}
