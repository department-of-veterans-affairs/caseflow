import React from 'react';
import { shallow } from 'enzyme';
import { PdfFile } from '../../../app/reader/PdfFile';
import { documents } from '../../data/documents';
import ApiUtil from '../../../app/util/ApiUtil';
import { storeMetrics, recordAsyncMetrics } from '../../../app/util/Metrics';

ApiUtil.get = jest.fn().mockResolvedValue(() => new Promise((resolve) => resolve({ body: {}, header: { 'x-document-source': 'VBMS' } })));

jest.mock('../../../app/util/ApiUtil');
jest.mock('../../../app/util/Metrics', () => ({
  storeMetrics: jest.fn().mockResolvedValue(),
  recordAsyncMetrics: jest.fn().mockResolvedValue(),
}));
jest.mock('pdfjs-dist', () => ({
  getDocument: jest.fn().mockResolvedValue(),
  GlobalWorkerOptions: jest.fn().mockResolvedValue(),
}));

const metricArgs = (featureValue) => {
  return [
    // eslint-disable-next-line no-undefined
    undefined,
    {
      data:
      {
        documentId: 1,
        documentType: 'test',
        file: '/document/1/pdf'
      },
      // eslint-disable-next-line no-useless-escape
      message: 'Getting PDF document: \"/document/1/pdf\" from \"\"',
      product: 'reader',
      additionalInfo: '{\"source\":\"\\\"\\\"\"}',
      type: 'performance'
    },
    featureValue,
  ];
};

const storeMetricsError = {
  uuid: expect.stringMatching(/^([a-zA-Z0-9-.'&])*$/),
  data:
  {
    documentId: 1,
    documentType: 'test',
    file: '/document/1/pdf'
  },
  info: {
    message: expect.stringMatching(/^([a-zA-Z0-9-.'&:/ ])*$/),
    product: 'browser',
    type: 'error'
  }
};

describe('PdfFile', () => {

  let wrapper;

  describe('getDocument', () => {

    describe('when the feature toggle metricsRecordPDFJSGetDocument is OFF', () => {

      beforeAll(() => {
        // This component throws an error about halfway through getDocument at destroy
        // giving it access to both recordAsyncMetrics and storeMetrics
        wrapper = shallow(
          <PdfFile
            documentId={documents[0].id}
            key={`${documents[0].content_url}`}
            file={documents[0].content_url}
            onPageChange= {jest.fn()}
            isVisible={documents[0].content_url}
            scale="test"
            documentType="test"
            featureToggles={{
              metricsRecordPDFJSGetDocument: false,
            }}
            clearDocumentLoadError={jest.fn()}
            setDocumentLoadError={jest.fn()}
            setPageDimensions={jest.fn()}
            setPdfDocument={jest.fn()}
          />
        );

        wrapper.instance().componentDidMount();
      });

      afterAll(() => {
        jest.clearAllMocks();
      });

      it('calls recordAsyncMetrics but will not save a metric', () => {
        expect(recordAsyncMetrics).toBeCalledWith(metricArgs()[0], metricArgs()[1], metricArgs(false)[2]);
      });

      it('does not call storeMetrics in catch block', () => {
        expect(storeMetrics).not.toBeCalled();
      });

    });

    describe('when the feature toggle metricsRecordPDFJSGetDocument is ON', () => {

      beforeAll(() => {
        // This component throws an error about halfway through getDocument at destroy
        // giving it access to both recordAsyncMetrics and storeMetrics
        wrapper = shallow(
          <PdfFile
            documentId={documents[0].id}
            key={`${documents[0].content_url}`}
            file={documents[0].content_url}
            onPageChange= {jest.fn()}
            isVisible={documents[0].content_url}
            scale="test"
            documentType="test"
            featureToggles={{
              metricsRecordPDFJSGetDocument: true,
            }}
            clearDocumentLoadError={jest.fn()}
            setDocumentLoadError={jest.fn()}
            setPageDimensions={jest.fn()}
            setPdfDocument={jest.fn()}
          />
        );

        wrapper.instance().componentDidMount();
      });

      afterAll(() => {
        jest.clearAllMocks();
      });

      it('calls recordAsyncMetrics and will save a metric', () => {
        expect(recordAsyncMetrics).toBeCalledWith(metricArgs()[0], metricArgs()[1], metricArgs(true)[2]);
      });

      it('calls storeMetrics in catch block', () => {
        expect(storeMetrics).toBeCalledWith(storeMetricsError.uuid, storeMetricsError.data, storeMetricsError.info);
      });
    });
  });
});
