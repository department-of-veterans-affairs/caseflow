import React from 'react';
import { Provider } from 'react-redux';
import { createStore } from 'redux';

import PdfUIPageNumInput from './PdfUIPageNumInput';
import rootReducer from './reducers';

export default {
  title: 'Reader/Components/PdfUIPageNumInput',
  component: PdfUIPageNumInput,
  parameters: {
    controls: { expanded: true },
  },
  args: {
    jumpToPage: { action: 'jump to page' },
    numPages: 10,
    docId: 42
  },
};

const store = createStore(rootReducer);

const Template = (args) => (
  <Provider store={store}>
    <PdfUIPageNumInput {...args} />
  </Provider>
);

export const PdfPageNumInput = Template.bind({});
