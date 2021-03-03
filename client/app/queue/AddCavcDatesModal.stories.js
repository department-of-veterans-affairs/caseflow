import React from 'react';

import { queueWrapper as Wrapper } from '../../test/data/stores/queueStore';
import { amaAppeal } from '../../test/data/appeals';
import AddCavcDatesModal from './AddCavcDatesModal';

export default {
  title: 'Queue/AddCavcDatesModal',
  component: AddCavcDatesModal,
  parameters: { controls: { expanded: true } },
};

const appealId = amaAppeal.externalId;

const Template = ({...componentArgs}) => {
  const storeArgs = {
  };

  return <Wrapper {...storeArgs}>
    <AddCavcDatesModal appealId={appealId} {...componentArgs} />
  </Wrapper>;
};

export const Default = Template.bind({});

