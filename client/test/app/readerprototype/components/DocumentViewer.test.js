import { render, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { rootReducer } from 'app/reader/reducers';
import DocumentViewer from 'app/readerprototype/DocumentViewer';
import ApiUtil from 'app/util/ApiUtil';
import { def, get } from 'bdd-lazy-var/getter';
import fs from 'fs';
import React, { useState } from 'react';
import { Provider } from 'react-redux';
import { MemoryRouter } from 'react-router-dom';
import { applyMiddleware, createStore } from 'redux';
import thunk from 'redux-thunk';
import { documentFactory } from '../factories';

beforeEach(() => {
  window.IntersectionObserver = jest.fn(() => ({
    observe: jest.fn(),
    disconnect: jest.fn()
  }));
  window.HTMLElement.prototype.scrollIntoView = jest.fn;
});

afterEach(() => jest.clearAllMocks());

def('history', () => []);
def('match', () => ({
  params: { docId: '1', vacolsId: '3575931' },
}));
def('document1', () => documentFactory({ id: 1 }));
def('document2', () => documentFactory({ id: 2 }));
def('props', () => ({
  allDocuments: [
    get.document1,
    get.document2,
  ],
  showPdf: (docId) => () => {
    get.history.push(`/3575931/documents/${docId}`);
    get.match.params = { docId, vacolsId: '3575931' };
  },
  history: get.history,
  match: get.match,
  documentPathBase: '/3575931/documents',
}));

const getStore = () => (
  createStore(
    rootReducer,
    {
      annotationLayer: {
        annotations: 1,
        deleteAnnotationModalIsOpenFor: null,
        shareAnnotationModalIsOpenFor: null
      },
      documents: { 1: get.document1, 2: get.document2 },
      documentList: {
        pdfList: {
          lastReadDocId: null,
        },
        searchCategoryHighlights: [{ 1: {} }, { 2: {} }],
        filteredDocIds: [
          1,
          2,
        ],
        docFilterCriteria: {},
        pdfViewer: {
          pdfSideBarError: {
            category: {
              visible: false,
            },
          },
          tagOptions: [],
          openedAccordionSections: ['Issue tags', 'Comments', 'Categories'],
        },
      },
    },
    applyMiddleware(thunk)
  )
);

const Component = () => {
  const [zoomLevel, setZoomLevel] = useState(100);

  return (
    <Provider store={getStore()}>
      <MemoryRouter history={get.history}>
        <DocumentViewer {...get.props} zoomLevel={zoomLevel}
          onZoomChange={(newZoomLevel) => setZoomLevel(newZoomLevel)} />
      </MemoryRouter>
    </Provider>
  );
};

describe('user visiting a document', () => {
  it('records the viewing of the document', () => {
    const spy = jest.spyOn(ApiUtil, 'patch');

    render(<Component />);
    expect(spy).
      toHaveBeenCalledWith(
        '/document/1/mark-as-read',
        { start: '2020-07-06T06:00:00-04:00', t0: 'RUNNING_IN_NODE' },
        'mark-doc-as-read');
  });
});

describe('Open Document and Close Issue tags Sidebar Section', () => {
  it('Navigate to next document and verify Issue tags stay closed', async () => {
    jest.spyOn(ApiUtil, 'patch').mockResolvedValue();

    const { container, getByText } = render(<Component />);

    expect(container).toHaveTextContent('Document 1 of 2');
    // there are 3 open sections in the sidebar
    expect(container.querySelectorAll('div.rc-collapse-item-active').length).toEqual(3);
    userEvent.click(getByText('Issue tags'));
    // we closed a section in the sidebar, so now there are 2 open
    expect(container.querySelectorAll('div.rc-collapse-item-active').length).toEqual(2);

    userEvent.click(getByText('Next'));
    // we make sure we are on the next document
    await waitFor(() => expect(container).toHaveTextContent('Document 2 of 2'));
    // there are still only 2 open sections in the sidebar
    expect(container.querySelectorAll('div.rc-collapse-item-active').length).toEqual(2);
  });
});

it('should change zoom level to 90%, then to 80% to simulate parent states update', async () => {
  jest.spyOn(ApiUtil, 'patch').mockResolvedValue();

  const { container, getByRole } = render(<Component />);

  expect(container).toHaveTextContent('100%');
  const zoomOutButton = getByRole('button', { name: /zoom out/i });

  userEvent.click(zoomOutButton);
  await waitFor(() => expect(container).toHaveTextContent('90%'));
  userEvent.click(zoomOutButton);
  await waitFor(() => expect(container).toHaveTextContent('80%'));
});

it('Sidebar remembers its state between document views', async () => {
  jest.spyOn(ApiUtil, 'patch').mockResolvedValue();

  const { container, getByText } = render(<Component />);

  expect(container).toHaveTextContent('Document 1 of 2');
  // Initially, the sidebar should be visible with button to close
  expect(container).toHaveTextContent('Hide menu');

  // Simulate clicking 'Hide menu' to close menu
  userEvent.click(getByText('Hide menu'));

  // Sidebar should have 'Open menu' to reopen sidebar
  expect(container).toHaveTextContent('Open menu');

  // Simulate navigating to another document
  userEvent.click(getByText('Next'));

  // we make sure we are on the next document
  await waitFor(() => expect(container).toHaveTextContent('Document 2 of 2'));
  // Sidebar should remain hidden and have open menu
  expect(container).toHaveTextContent('Open menu');
});

// describe('Open Document and Test Column Layout', () => {
//   it('should change layout from single column to double column at larger width', async () => {
//     const raw = fs.readFileSync('test/fixtures/pdfs/Informal_Form9.pdf');
//     const arrayBuffer = raw.buffer;

//     jest.spyOn(ApiUtil, 'patch').mockResolvedValue();
//     jest.spyOn(ApiUtil, 'get').mockResolvedValueOnce({ body: arrayBuffer });
//     // Initial render at width 1080 (single column)
//     global.innerWidth = 1080;
//     const { container, getByTitle, debug } = render(<Component doc={{}} document={{}} />);

//     // verify initial width
//     expect(global.innerWidth).toBe(1080);
//     await waitFor(() => expect(container).not.toHaveTextContent('Loading document...'));

//     // Simulate typing 2 into the page number text box
//     debug(container, 200000);
//     const pageNumberTextBox = getByTitle('Page');

//     userEvent.type(pageNumberTextBox, '{backspace}2{enter}');

//     // Verify the textbox now holds "2"
//     await waitFor(() =>
//       expect(container.querySelector('#page-progress-indicator-input').value).toBe(2)
//     );

//     // Now simulate increasing the screen width to 2000px (double column layout)
//     global.innerWidth = 2000;
//     global.dispatchEvent(new Event('resize'));
//     expect(global.innerWidth).toBe(2000);

//     // After resizing, the layout should change and the text box should now display 1
//     await waitFor(() =>
//       expect(container).querySelector('#page-progress-indicator-input').value.toBe(1)
//     );

//     // Simulate a smaller width (1100px), where it should still be a single column layout
//     global.innerWidth = 1100;
//     global.dispatchEvent(new Event('resize'));
//     expect(global.innerWidth).toBe(1100);

//     // The page number should still remain 1
//     await waitFor(() =>
//       expect(container).querySelector('#page-progress-indicator-input').value.toBe('1')
//     );
//   });
// });
