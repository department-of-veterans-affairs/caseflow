import { act, render, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import DocumentViewer from 'app/readerprototype/DocumentViewer';
import ApiUtil from 'app/util/ApiUtil';
import { def, get, set } from 'bdd-lazy-var/getter';
import React, { useState } from 'react';
import { Provider } from 'react-redux';
import { MemoryRouter } from 'react-router-dom';
import { documentFactory } from '../factories';
import getStore from '../mockReaderStore';

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
def('document1', () => documentFactory({ id: 1, type: 'VA 8 Certification of Appeal' }));
def('document2', () => documentFactory({ id: 2, type: 'Supplemental Statement of the Case' }));
def('document3', () => documentFactory({ id: 3, type: 'CAPRI' }));
def('document4', () => documentFactory({ id: 4, type: 'Notice of Disagreement' }));
def('document5', () => documentFactory({ id: 5, type: 'Rating Decision - Codesheet' }));
def('props', () => ({
  allDocuments: [
    get.document1,
    get.document2,
    get.document3,
    get.document4,
    get.document5,
  ],
  showPdf: (docId) => () => {
    get.history.push(`/3575931/documents/${docId}`);
    get.match.params = { docId, vacolsId: '3575931' };
  },
  history: get.history,
  match: get.match,
  documentPathBase: '/3575931/documents',
  fetchAppealDetails: jest.fn(() => Promise.resolve(true)),
  onZoomChange: jest.fn()
}));
def('storeProps', () => ({
  filteredDocIds: [1, 2],
}));

const docIdProp = (docId) => {
  return {
    match: {
      params: { docId, vacolsId: '3575931' },
    },
  };
};

const Component = (props = {}) => {
  const [zoomLevel, setZoomLevel] = useState(100);

  return (
    <Provider store={getStore({ ...get.storeProps })}>
      <MemoryRouter history={get.history}>
        <DocumentViewer
          {...get.props}
          onZoomChange={(newZoomLevel) => setZoomLevel(newZoomLevel)}
          zoomLevel={zoomLevel}
          {...props}
        />
      </MemoryRouter>
    </Provider>
  );
};

describe('Marked as Read', () => {
  it('marks document with docId 1 as read', () => {
    jest.clearAllMocks();
    const spy = jest.spyOn(ApiUtil, 'patch');

    render(<Component />);
    expect(spy).
      toHaveBeenCalledWith(
        '/document/1/mark-as-read',
        { start: '2020-07-06T06:00:00-04:00', t0: 'RUNNING_IN_NODE' },
        'mark-doc-as-read');
  });
});

describe('Sidebar Section', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    jest.spyOn(ApiUtil, 'patch').mockResolvedValue();
  });

  it('closes the Issue Tags section and verify it stays closed on next document', async () => {
    const { container, getByText } = render(<Component />);

    expect(container).toHaveTextContent('Document 1 of 2');
    expect(document.title).toBe(`${get.document1.type} | Document Viewer | Caseflow Reader`);
    // there are 3 open sections in the sidebar
    expect(container.querySelectorAll('div.rc-collapse-item-active').length).toEqual(3);
    userEvent.click(getByText('Issue tags'));
    // we closed a section in the sidebar, so now there are 2 open
    expect(container.querySelectorAll('div.rc-collapse-item-active').length).toEqual(2);

    userEvent.click(getByText('Next'));
    // we make sure we are on the next document
    await waitFor(() => expect(container).toHaveTextContent('Document 2 of 2'));
    expect(document.title).toBe(`${get.document2.type} | Document Viewer | Caseflow Reader`);
    // there are still only 2 open sections in the sidebar
    expect(container.querySelectorAll('div.rc-collapse-item-active').length).toEqual(2);
  });

  it('closes Sidebar and verify it stays closed on the next document', async () => {
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
});

describe('Zoom', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    jest.spyOn(ApiUtil, 'patch').mockResolvedValue();
  });

  it('zooms out and verify zoom level persists on next document', async () => {
    const { container, getByText } = render(<Component />);

    await waitFor(() => expect(container).toHaveTextContent('Document 1 of 2'));
    expect(container).toHaveTextContent('100%');
    userEvent.click(document.querySelector('#button-zoomOut'));
    await waitFor(() => expect(container).toHaveTextContent('90%'));

    userEvent.click(getByText('Next'));
    // await waitFor(() => expect(container).toHaveTextContent('Document 2 of 2'));
    await waitFor(() => expect(container).toHaveTextContent('90%'));
  });

  it('zooms in and verify zoom level persists on previous document', async () => {
    const { container, getByText } = render(<Component {...docIdProp('2')} />);

    await waitFor(() => expect(container).toHaveTextContent('Document 2 of 2'));
    expect(container).toHaveTextContent('100%');
    userEvent.click(document.querySelector('#button-zoomIn'));
    await waitFor(() => expect(container).toHaveTextContent('110%'));

    userEvent.click(getByText('Previous'));
    // await waitFor(() => expect(container).toHaveTextContent('Document 1 of 2'));
    await waitFor(() => expect(container).toHaveTextContent('110%'));
  });
});
