import React from 'react';
import SaveSearchModal from 'app/nonComp/components/ReportPage/SaveSearchModal';
import userSearchParamWithCondition from 'test/data/nonComp/userSearchParamWithConditionData';
import ReduxDecorator from 'test/app/nonComp/nonCompReduxDecorator';

export default {
  title: 'Queue/NonComp/SavedSearches/Save Search Modal',
  component: SaveSearchModal,
  decorators: [ReduxDecorator],
  parameters: {},
  args: {},
  argTypes: {

  },
};

const Template = (args) => {
  return (
    <SaveSearchModal
      {...args}
    />
  );
};

export const SaveSearchModalTemplate = Template.bind({});

SaveSearchModalTemplate.story = {
  name: 'Save Search Modal'
};

SaveSearchModalTemplate.args = {
  data: { nonComp: { businessLineUrl: 'vha' }, savedSearch: userSearchParamWithCondition.savedSearch }
};

