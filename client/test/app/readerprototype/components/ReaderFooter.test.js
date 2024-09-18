import { applyMiddleware, createStore } from 'redux';
import pdfSearchReducer from '../../../../app/reader/PdfSearch/PdfSearchReducer';
import thunk from 'redux-thunk';
import { Provider } from 'react-redux';
import React from 'react';
import ReaderFooter from 'app/readerprototype/components/ReaderFooter';
import { render } from '@testing-library/react';

const getUnFilteredStore = () =>
  createStore(
    pdfSearchReducer,
    {
      documents: {
        1: {
        },
        2: {
        },
        3: {
        },
        4: {
        },
        5: {
        },
      },
      documentList: {
        filteredDocIds: [
          1,
          2,
          3,
          4,
          5,
        ],
        docFilterCriteria: {},
      },
    },
    applyMiddleware(thunk)
  );

const getFilteredStore = () =>
  createStore(
    pdfSearchReducer,
    {
      documents: {
        5: {
        },
        6: {
        },
        7: {
        },
        8: {
        },
        9: {
        }
      },
      documentList: {
        filteredDocIds: [
          9,
          7,
        ],
      }
    },
    applyMiddleware(thunk)
  );

const UnFilteredComponent = (props) => (
  <Provider store={getUnFilteredStore()}>
    <ReaderFooter {...props} />
  </Provider>
);

const FilteredComponent = (props) => (
  <Provider store={getFilteredStore()}>
    <ReaderFooter {...props} />
  </Provider>
);

const filteredDoc = {
  id: 9,
};

const unFilteredDoc = {
  id: 4,
};

describe('Unfiltered', () => {
  it('shows the correct document count', () => {
    const { container } = render(<UnFilteredComponent docId={unFilteredDoc.id} showPdf={() => { }} />);

    expect(container).toHaveTextContent('4 of 5');
    expect(container).not.toHaveTextContent('filtered indicator');
  });
});

describe('Filtered', () => {
  it('shows the correct document count', () => {
    const { container } = render(<FilteredComponent
      currentPage={1} docId={filteredDoc.id}
      numPages={2}
      showPdf={() => { }} />);

    expect(container).toHaveTextContent('1 of 2');
  });

  it('shows the filtered icon', () => {
    const { getByTitle } = render(
      <FilteredComponent currentPage={1} docId={filteredDoc.id} numPages={2} showPdf={() => { }} />)
      ;

    expect(getByTitle('filtered indicator')).toBeTruthy();
  });
});
