import React from 'react';
import { shallow } from 'enzyme';
import { documents } from '../data/documents';
import { PdfPage } from '../../app/reader/PdfPage';

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
        getPage: jest.fn().mockImplementation(() => Promise.resolve('test')),
        numPages: 1
      }}
      featureToggles={{
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
