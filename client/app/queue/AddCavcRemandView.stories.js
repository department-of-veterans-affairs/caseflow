import React from 'react';

import { queueWrapper as Wrapper } from '../../test/data/stores/queueStore';
import { amaAppeal } from '../../test/data/appeals';

import AddCavcRemandView from './AddCavcRemandView';

export default {
  title: 'Queue/AddCavcRemandView',
  component: AddCavcRemandView
};

const appealId = amaAppeal.externalId;

const Template = (args) => (<Wrapper>
  <AddCavcRemandView appealId={appealId} {...args} />
</Wrapper>);

export const Default = Template.bind({});
