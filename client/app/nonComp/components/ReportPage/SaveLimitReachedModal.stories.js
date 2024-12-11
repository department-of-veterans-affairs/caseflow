import React from 'react';
import SaveLimitReachedModal from 'app/nonComp/components/ReportPage/SaveLimitReachedModal';
import savedSearchesData from 'test/data/nonComp/savedSearchesData';
import ReduxDecorator from 'test/app/nonComp/nonCompReduxDecorator';

export default {
  title: 'Queue/NonComp/SavedSearches/Save Limit Reach Modal',
  component: SaveLimitReachedModal,
  decorators: [ReduxDecorator],
  parameters: { },
  args: { },
  argTypes: {

  },
};

const userSearches = savedSearchesData.savedSearches.fetchedSearches.userSearches;

const Template = (args) => {
  return (
    <SaveLimitReachedModal userSearches={userSearches}
      {...args}
    />
  );
};

export const SaveLimitReachedModalTemplate = Template.bind({});

SaveLimitReachedModalTemplate.story = {
  name: 'Save Limit Reach Modal'
};

SaveLimitReachedModalTemplate.args = {
  data: { nonComp: { businessLineUrl: 'vha' }, savedSearch: savedSearchesData.savedSearches }
};

