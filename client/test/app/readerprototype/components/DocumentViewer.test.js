import React from 'react';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { createMemoryHistory } from 'history';
import { Router } from 'react-router-dom';
import { Provider } from 'react-redux';
import { applyMiddleware, createStore } from 'redux';
import thunk from 'redux-thunk';
import DocumentViewer from '../../../../app/readerprototype/DocumentViewer';
import documentsReducer from '../../../../app/reader/Documents/DocumentsReducer';

const mockDocuments = [
  { id: 1, type: 'Form 9' },
  { id: 2, type: 'NOD' }
];

const mockShowPdf = jest.fn();
const mockOnZoomChange = jest.fn();

const getStore = () =>
  createStore(
    documentsReducer,
    {
      pdfViewer: {
        openedAccordionSections: [],
      },
      annotationLayer: {
        deleteAnnotationModalIsOpenFor: null,
        shareAnnotationModalIsOpenFor: null
      },
      documentList: {
        searchCategoryHighlights: {
          1: {},
          2: {}
        }
      },
    },
    applyMiddleware(thunk)
  );

const defaultProps = {
  allDocuments: mockDocuments,
  match: { params: { docId: '1', vacolsId: '123' } },
  zoomLevel: 100,
  onZoomChange: mockOnZoomChange,
  showPdf: mockShowPdf,
  documentPathBase: '/123/documents'
};

const updatedProps = {
  allDocuments: mockDocuments,
  match: { params: { docId: '1', vacolsId: '123' } },
  zoomLevel: 80,
  onZoomChange: mockOnZoomChange,
  showPdf: mockShowPdf,
  documentPathBase: '/123/documents'
};

const history = createMemoryHistory();

const Component = (props) => (
  <Provider store={getStore()}>
    <Router history={history}>
      <DocumentViewer {...props} />
    </Router>
  </Provider>
);

test('should change zoom level to 80%, then to 60% to simulate parent states update', () => {
  // Initial render with zoomLevel 100%
  const { rerender } = render(<Component {...defaultProps} />);

  expect(screen.getByText(/100%/i)).toBeInTheDocument();

  const zoomOutButton = screen.getByRole('button', { name: /zoom out/i });

  // Simulate clicking zoom-out button to go to 80%
  userEvent.click(zoomOutButton);
  expect(mockOnZoomChange).toHaveBeenNthCalledWith(1, 80);

  // Now re-render the component with zoomLevel 80 to simulate parent state update
  rerender(<Component {...updatedProps} />);

  // Verify that component now displays zoom level 80%
  expect(screen.getByText(/80%/i)).toBeInTheDocument();
  // Click zoom-out button again and confirm correct new zoomLevel value
  userEvent.click(zoomOutButton);
  expect(mockOnZoomChange).toHaveBeenNthCalledWith(2, 60);
});
