import React from 'react';
import { render } from '@testing-library/react';
import { documents } from '../data/documents';
import { PdfPage } from '../../app/reader/PdfPage';
import rootReducer from '../../app/reader/reducers';
import thunk from 'redux-thunk';
import { Provider } from 'react-redux';
import { createStore, applyMiddleware } from 'redux';

// Mocking the Metrics functions at the top of the file
jest.mock('../../../app/util/Metrics', () => ({
  storeMetrics: jest.fn().mockReturnThis(),
  recordMetrics: jest.fn().mockReturnThis(),
  recordAsyncMetrics: jest.fn().mockImplementation(() => Promise.resolve())
}));

// Store setup for tests
const getStore = () => createStore(rootReducer, applyMiddleware(thunk));

// Mock data
export const pageMetricData = [
  'test',
  {
    message: 'Getting PDF page 2 from PDFJS document',
    product: 'reader',
    type: 'performance',
    eventId: '123456'
  },
  true
];

export const textMetricData = [
  'test',
  {
    message: 'Storing PDF page text text in Redux',
    product: 'reader',
    type: 'performance'
  },
  true
];

export const storeMetricsData = [
  documents[0].id,
  {
    documentType: 'Test',
    overscan: '',
    pageCount: 1
  },
  {
    duration: 0,
    message: 'pdf_page_render_time_in_ms',
    product: 'reader',
    type: 'performance'
  },
  '123456'
];

export const storeMetricsBrowserError = [
  '1234',
  {
    documentId: documents[0].id,
    documentType: 'Test',
    file: documents[0].content_url
  },
  {
    message: '1234 : setUpPage /document/1/pdf : Error',
    product: 'browser',
    type: 'error',
  },
  '123456',
];

export const recordMetricsArgs = [
  'Test',
  {
    message: 'Rendering PDF page 2 text',
    product: 'reader',
    type: 'performance',
    uuid: '1234',
    eventId: '123456'
  },
  true
];

// Test helpers that render the component with feature toggles
export const pdfPageRenderTimeInMsEnabled = (props) => {
  const store = getStore();

  return render(
    <Provider store={store}>
      <PdfPage
        documentId={documents[0].id}
        metricsIdentifier="123456"
        file={documents[0].content_url}
        isPageVisible=""
        pageIndex={1}
        scale={1}
        pdfDocument={{
          _pdfInfo: { numPages: 1 },
          _transport: { destroyed: false, pagePromises: { _numPages: 1 } },
          getPage: jest.fn().mockReturnValue('test'),
          numPages: 1
        }}
        featureToggles={{ metricsPdfStorePages: true, pdfPageRenderTimeInMs: true, metricsReaderRenderText: true }}
        page={{ cleanup: jest.fn(), getViewport: jest.fn().mockImplementation(() => Promise.resolve({ data: {} })) }}
        documentType="Test"
        windowingOverscan=""
        {...props}
      />
    </Provider>
  );
};

export const pdfPageRenderTimeInMsDisabled = () => {
  const store = getStore();

  return render(
    <Provider store={store}>
      <PdfPage
        documentId={documents[0].id}
        file={documents[0].content_url}
        isPageVisible=""
        pageIndex={1}
        scale={1}
        pdfDocument={{
          _pdfInfo: {
            numPages: 1
          },
          _transport: {
            destroyed: false,
            pagePromises: {
              _numPages: 1
            }
          },
          getPage: jest.fn().mockReturnValue('test'),
          numPages: 1
        }}
        featureToggles={{
          metricsPdfStorePages: true,
          pdfPageRenderTimeInMs: false,
          metricsReaderRenderText: true
        }}
        page={{
          cleanup: jest.fn(),
          getViewport: jest.fn().mockImplementation(() => Promise.resolve({ data: {} }))
        }}
        documentType="Test"
        windowingOverscan=""
      />
    </Provider>
  );
};

export const metricsPdfStorePagesDisabled = () => {
  const store = getStore();

  return render(
    <Provider store={store}>
      <PdfPage
        documentId={documents[0].id}
        file={documents[0].content_url}
        isPageVisible=""
        pageIndex={1}
        scale={1}
        pdfDocument={{
          _pdfInfo: {
            numPages: 1
          },
          _transport: {
            destroyed: false,
            pagePromises: {
              _numPages: 1
            }
          },
          getPage: jest.fn().mockReturnValue('test'),
          numPages: 1
        }}
        featureToggles={{
          metricsPdfStorePages: false,
          pdfPageRenderTimeInMs: false,
          metricsReaderRenderText: true
        }}
        page={{
          cleanup: jest.fn(),
          getViewport: jest.fn().mockImplementation(() => Promise.resolve({ data: {} }))
        }}
        documentType="Test"
        windowingOverscan=""
      />
    </Provider>
  );
};
