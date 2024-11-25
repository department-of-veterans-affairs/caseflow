import React from 'react';
import SavedSearches from './SavedSearches';
import savedSearchesData from '../../../test/data/nonComp/savedSearchesData';
import ReduxDecorator from 'test/app/nonComp/nonCompReduxDecorator';

export default {
  title: 'Queue/NonComp/SavedSearches',
  component: SavedSearches,
  decorators: [ReduxDecorator],
  parameters: {},
  args: {},
  argTypes: {

  },
};

const Template = (args) => {
  return (
    <SavedSearches
      {...args}
    />
  );
};

export const SavedSearchesTemplate = Template.bind({});

SavedSearchesTemplate.story = {
  name: 'Saved Searches'
};

SavedSearchesTemplate.args = {
  data: { nonComp: { businessLineUrl: 'vha' }, savedSearch: savedSearchesData.savedSearches }
};

