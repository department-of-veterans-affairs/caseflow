import { applyMiddleware, createStore } from 'redux';
import pdfSearchReducer from '../../../../app/reader/PdfSearch/PdfSearchReducer';
import thunk from 'redux-thunk';
import { Provider } from 'react-redux';
import React from 'react';
import ReaderFooter from 'app/readerprototype/components/ReaderFooter';
import {render} from '@testing-library/react';

const getStore = () =>
  createStore(
    pdfSearchReducer,
    {
      documents: {
      },
      documentList: {
        filteredDocIds: [
          4,
          2,
        ],
      }
    },
    applyMiddleware(thunk)
  );

const Component = (props) => (
  <Provider store={getStore()}>
    <ReaderFooter {...props} />
  </Provider>
);

const doc = {
  id: 4,
};

describe('Filtered', () => {
  it('shows the correct document count', () => {
    const { container } = render(<Component currentPage={1} docId={doc.id} numPages={2} showPdf={() => {}} />);

    expect(container).toHaveTextContent('1 of 2');
  });

  it('shows the filtered icon', () => {
    const { getByTitle} = render(<Component currentPage={1} docId={doc.id} numPages={2} showPdf={() => {}} />);

    expect(getByTitle('filtered indicator')).toBeTruthy();
  });
});
