import { applyMiddleware, createStore } from 'redux';
import pdfSearchReducer from '../../../../app/reader/PdfSearch/PdfSearchReducer';
import thunk from 'redux-thunk';
import { Provider } from 'react-redux';
import React from 'react';
import ReaderFooter from 'app/readerprototype/components/ReaderFooter';
import { fireEvent, render } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { documents } from '../data/documents';

const getUnFilteredStore = () =>
  createStore(
    pdfSearchReducer,
    {
      documents,
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
      annotationLayer: {
        annotations: 1,
      },
    },
    applyMiddleware(thunk)
  );

const getFilteredStore = () =>
  createStore(
    pdfSearchReducer,
    {
      documents,
      documentList: {
        filteredDocIds: [
          4,
          2,
        ],
      },
      annotationLayer: {
        annotations: 1,
      },
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

const doc = {
  id: 4,
};

describe('Unfiltered', () => {
  it('shows the correct document count', () => {
    const { container } = render(<UnFilteredComponent docId={doc.id} showPdf={() => jest.fn()} />);

    expect(container).toHaveTextContent('4 of 5');
    expect(container).not.toHaveTextContent('filtered indicator');
  });
});

describe('Filtered', () => {
  it('shows the correct document count', () => {
    const { container } = render(<FilteredComponent currentPage={1} docId={doc.id} numPages={2} showPdf={() => jest.fn()} />);

    expect(container).toHaveTextContent('1 of 2');
  });

  it('shows the filtered icon', () => {
    const { getByTitle } = render(
      <FilteredComponent currentPage={1} docId={doc.id} numPages={2} showPdf={() => jest.fn()} />)
    ;

    expect(getByTitle('filtered indicator')).toBeTruthy();
  });
});

describe('Document Navigation', () => {
  const showPdf = jest.fn();

  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('calls showPdf() when Next button is clicked', () => {
    const { container, getByText } = render(<UnFilteredComponent docId={1} showPdf={() => showPdf} />);

    expect(container).toHaveTextContent('1 of 5');
    expect(container).not.toHaveTextContent('Previous');
    userEvent.click(getByText('Next'));
    expect(showPdf).toHaveBeenCalledTimes(1);

  });

  it('calls showPdf() when Previous button is clicked', () => {
    const { container, getByText } = render(<UnFilteredComponent docId={5} showPdf={() => showPdf} />);

    expect(container).toHaveTextContent('5 of 5');
    expect(container).not.toHaveTextContent('Next');
    userEvent.click(getByText('Previous'));
    expect(showPdf).toHaveBeenCalledTimes(1);

  });

  it('calls showPdf() when right arrow key is pressed', () => {
    const { container } = render(<UnFilteredComponent docId={1} showPdf={() => showPdf} />);

    fireEvent.keyDown(container, { key: 'ArrowRight', code: 39 });
    expect(showPdf).toHaveBeenCalledTimes(1);
  });

  it('calls showPdf() when left arrow key is pressed', () => {
    const { container } = render(<UnFilteredComponent docId={5} showPdf={() => showPdf} />);

    fireEvent.keyDown(container, { key: 'ArrowLeft', code: 37 });
    expect(showPdf).toHaveBeenCalledTimes(1);
  });
});
