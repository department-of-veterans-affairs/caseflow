/* eslint-disable react/prop-types */
import { render } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import React from 'react';
import { Provider } from 'react-redux';
import { applyMiddleware, createStore } from 'redux';
import thunk from 'redux-thunk';
import { addNewTag, removeTag } from '../../../../app/reader/Documents/DocumentsActions';
import pdfViewerReducer from '../../../../app/reader/PdfViewer/PdfViewerReducer';
import IssueTags from '../../../../app/readerprototype/components/IssueTags';

afterEach(() => jest.clearAllMocks());

jest.mock('../../../../app/reader/Documents/DocumentsActions', () => ({
  addNewTag: jest.fn(() => ({ type: 'FakeNewTag' })),
  removeTag: jest.fn(() => ({ type: 'FakeRemoveTag' })),
}));

const getStore = (errorVisible) =>
  createStore(
    pdfViewerReducer,
    {
      pdfViewer: {
        pdfSideBarError: {
          tag: {
            visible: errorVisible,
          },
        },
        tagOptions: [
          {
            id: 2,
            text: 'Service',
          },
          {
            id: 3,
            text: 'Right Knee',
          },
        ],
      },
    },
    applyMiddleware(thunk)
  );

const Component = (props) => (
  <Provider store={getStore(props.errorVisible)}>
    <IssueTags doc={props.doc} />
  </Provider>
);
const doc = {
  id: 1,
  tags: [],
};

describe('Adds and removes tag', () => {
  it('succeeds', () => {
    const { container, getByLabelText, getByText } = render(<Component doc={doc} errorVisible={false} />);

    userEvent.click(getByLabelText('Select or tag issues'));
    userEvent.click(getByText('Service'));

    expect(addNewTag).toHaveBeenCalledWith(doc, [
      {
        label: 'Service',
        tagId: 2,
        value: 'Service',
      },
    ]);

    userEvent.click(container.querySelector('.cf-select__multi-value__remove'));

    expect(removeTag).toHaveBeenCalledWith(doc, {
      label: 'Service',
      tagId: 2,
      value: 'Service',
    });
  });
});

describe('With error display', () => {
  it('shows error', () => {
    // we are testing if the IssueTags component shows an error if one is present in redux, so we add it.
    const { getByText } = render(<Component doc={doc} errorVisible />);

    expect(getByText('Unable to save. Please try again.')).toBeInTheDocument();
  });
});
