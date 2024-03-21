import React from 'react';
import { shallow } from 'enzyme';
import { documents } from '../data/documents';
import { PdfPage } from '../../app/reader/PdfPage';

export const pageMetricData = [
  'test',
  { data: {
    documentId: documents[0].id,
    file: documents[0].content_url,
    numPagesInDoc: 1,
    pageIndex: 1
  },
  message: 'Storing PDF page 2',
  product: 'reader',
  type: 'performance',
  eventId: '123456'
  },
  true
];

export const textMetricData = [
  'test',
  { data: {
    documentId: documents[0].id,
    file: documents[0].content_url
  },
  message: 'Storing PDF page text',
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
  { data: {
    documentId: documents[0].id,
    documentType: 'Test',
    file: documents[0].content_url,
    numPagesInDoc: 1,
    pageIndex: 1
  },
  message: 'Rendering PDF page 2 text',
  product: 'reader',
  type: 'performance',
  uuid: '1234',
  eventId: '123456'
  },
  true
];

export const pdfPageRenderTimeInMsEnabled = () => {
  return shallow(
    <PdfPage
      documentId={documents[0].id}
      metricsIdentifier="123456"
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
        pdfPageRenderTimeInMs: true,
        metricsReaderRenderText: true
      }}
      page={{
        cleanup: jest.fn(),
        getViewport: jest.fn().mockImplementation(() => Promise.resolve({ data: {} }))
      }}
      documentType="Test"
      windowingOverscan=""
    />
  );
};

export const pdfPageRenderTimeInMsDisabled = () => {
  return shallow(
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
  );
};

export const metricsPdfStorePagesDisabled = () => {
  return shallow(
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
  );
};
