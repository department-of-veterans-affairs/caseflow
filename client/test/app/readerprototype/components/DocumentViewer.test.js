// import React from 'react';
// import { render, screen } from '@testing-library/react';
// import userEvent from '@testing-library/user-event';
// import { createMemoryHistory } from 'history';
// import { Router } from 'react-router-dom';
// import { Provider } from 'react-redux';
// import { applyMiddleware, createStore } from 'redux';
// import thunk from 'redux-thunk';
// import DocumentViewer from '../../../../app/readerprototype/DocumentViewer';
// import documentsReducer from '../../../../app/reader/Documents/DocumentsReducer';

// const mockDocuments = [
//   { id: 1, type: 'Form 9' },
//   { id: 2, type: 'NOD' }
// ];

// const mockShowPdf = jest.fn();
// const mockOnZoomChange = jest.fn();

// const getStore = () =>
//   createStore(
//     documentsReducer,
//     {
//       pdfViewer: {
//         openedAccordionSections: [],
//       },
//       annotationLayer: {
//         deleteAnnotationModalIsOpenFor: null,
//         shareAnnotationModalIsOpenFor: null
//       },
//       documentList: {
//         searchCategoryHighlights: {
//           1: {},
//           2: {}
//         }
//       },
//     },
//     applyMiddleware(thunk)
//   );

// const defaultProps = {
//   allDocuments: mockDocuments,
//   match: { params: { docId: '1', vacolsId: '123' } },
//   zoomLevel: 100,
//   onZoomChange: mockOnZoomChange,
//   showPdf: mockShowPdf,
//   documentPathBase: '/123/documents'
// };

// const updatedProps = {
//   allDocuments: mockDocuments,
//   match: { params: { docId: '1', vacolsId: '123' } },
//   zoomLevel: 100,
//   onZoomChange: mockOnZoomChange,
//   showPdf: mockShowPdf,
//   documentPathBase: '/123/documents'
// };

// const history = createMemoryHistory();

// const Component = (props) => (
//   <Provider store={getStore()}>
//     <Router history={history}>
//       <DocumentViewer {...props} />
//     </Router>
//   </Provider>
// );

// test('should change zoom level to 20%, navigate back, and verify zoom is retained', async () => {

//   render(<Component {...defaultProps} />);
//   expect(screen.getByText(/100%/i)).toBeInTheDocument();

//   const zoomOutButton = screen.getByRole('button', { name: /zoom out/i });

//   // Click zoom to makes zoom go to 80%
//   userEvent.click(zoomOutButton);
//   expect(mockOnZoomChange).toHaveBeenNthCalledWith(1, 80);

//   // render(<Component {...updatedProps} />);
//   // const toolbar = document.querySelector('#prototype-toolbar');
//   // screen.debug(toolbar)
//   // expect(screen.getByText(/Zoom%/i)).toBeInTheDocument();
//   // expect(toolbar).toHaveTextContent('80%');

//   // userEvent.click(zoomOutButton) // Assume this goes to 60%
//   // await user.click(zoomOutButton); // Assume this goes to 40%
//   // await user.click(zoomOutButton); // This should set zoom level to 20%

//   // Verify zoom level has been updated to 20%
//   // expect(mockOnZoomChange).toHaveBeenNthCalledWith(2, 60);

//   // Find and click the back button (assume it's the back-to-claims-folder navigation)
//   // const backButton = screen.getByRole('button', { name: /back/i });
//   // const backButton = screen.getByRole('link', { name: /Back/i });

//   // userEvent.click(backButton);

//   // Mock navigation to another document (by finding "Form 9")
//   // const form9Link = screen.getByText('Form 9');
//   // const form9Link = screen.getByRole('link', { name: /Form 9/i });

//   // userEvent.click(form9Link);

//   // Verify zoom level is still 20% in the new document
//   // expect(mockOnZoomChange).toHaveBeenLastCalledWith(80);
//   // expect(mockOnZoomChange).toHaveBeenCalledTimes(5); // 4 clicks for zoom out and 1 for retaining
//   // expect(screen.getByText(/80%/i)).toBeInTheDocument(); // Verify the text "20%" is present
// });

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
