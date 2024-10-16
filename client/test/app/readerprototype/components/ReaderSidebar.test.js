/* eslint-disable react/prop-types */
import { render } from '@testing-library/react';
import React from 'react';
import { Provider } from 'react-redux';
import { applyMiddleware, createStore } from 'redux';
import thunk from 'redux-thunk';
import pdfViewerReducer from '../../../../app/reader/PdfViewer/PdfViewerReducer';
import ReaderSidebar from '../../../../app/readerprototype/components/ReaderSidebar';

afterEach(() => jest.clearAllMocks());

const doc = {
  id: 1,
  tags: [],
  category_procedural: true,
  category_other: false,
  category_medical: false,
  category_case_summary: false,
};
const getStore = () =>
  createStore(
    pdfViewerReducer,
    {
      documents: { 1: doc },
      pdfViewer: {
        pdfSideBarError: {
          category: {
            visible: false
          }
        },
        tagOptions: [],
        openedAccordionSections: [
          'Issue tags',
          'Comments',
          'Categories',
        ]
      },
      annotationLayer: {
        annotations: 1
      }
    },
    applyMiddleware(thunk)
  );
const Component = (props) => (
  <Provider store={getStore()}>
    <ReaderSidebar
      doc={props.doc}
      documents={[props.doc]}
      error={{ category: { visible: false } }}
    />
  </Provider>
);

describe('Open Accordion Sections based on Redux', () => {
  it('succeeds', () => {
    const { container } = render(<Component doc={doc} document={doc} errorVisible={false} />);

    expect(container).toHaveTextContent('Select or tag issues');
    expect(container).toHaveTextContent('Add a comment');
    expect(container).toHaveTextContent('Procedural');
  });
});
