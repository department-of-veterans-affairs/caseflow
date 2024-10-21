import React from 'react';
import { render, waitFor, cleanup} from '@testing-library/react';

import { PdfFile } from '../../../app/reader/PdfFile';
import { documents } from '../../data/documents';
import { storeMetrics, recordAsyncMetrics } from '../../../app/util/Metrics';

jest.mock('../../../app/util/ApiUtil', () => ({
  get: jest.fn().mockResolvedValue({
    body: {},
    header: { 'x-document-source': 'VBMS' }
  }),
}));
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
        numPagesInDoc: null,
        pageIndex: null,
        file: '/document/1/pdf',
        documentType: 'test',
        prefetchDisabled: undefined,
        overscan: undefined,
        isPageVisible: true,
        name: null
      },
      // eslint-disable-next-line no-useless-escape
      message: 'Getting PDF document: \"/document/1/pdf\"',
      product: 'reader',
      additionalInfo: JSON.stringify({ source: 'VBMS' }),
      type: 'performance',
      eventId: expect.stringMatching(/^([a-zA-Z0-9-.'&])*$/)
    },
    featureValue,
  ];
};

const storeMetricsError = {
  uuid: expect.stringMatching(/^([a-zA-Z0-9-.'&])*$/),
  data:
  {
    documentId: 1,
    file: '/document/1/pdf',
    documentType: 'test',
  },
  info: {
    message: expect.stringMatching(/^([a-zA-Z0-9-.'&:/ ()]*)$/),
    product: 'browser',
    type: 'error'
  },
  eventId: expect.stringMatching(/^([a-zA-Z0-9-.'&])*$/)
};

describe('PdfFile', () => {

  describe('getDocument', () => {

    describe('when the feature toggle metricsRecordPDFJSGetDocument is OFF', () => {

      beforeAll(() => {
        // This component throws an error about halfway through getDocument at destroy
        // giving it access to both recordAsyncMetrics and storeMetrics
        const {container} = render(
          <PdfFile
            documentId={documents[0].id}
            key={`${documents[0].content_url}`}
            file={documents[0].content_url}
            onPageChange= {jest.fn()}
            isVisible
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
      let renderStartTime = null;
      const setRenderStartTime = jest.fn(time => {
        renderStartTime = time;
      });

      beforeAll(() => {
        render(
          <PdfFile
            documentId={documents[0].id}
            key={`${documents[0].content_url}`}
            file={documents[0].content_url}
            onPageChange={jest.fn()}
            isVisible
            scale="test"
            documentType="test"
            featureToggles={{
              metricsRecordPDFJSGetDocument: true,
            }}
            clearDocumentLoadError={jest.fn()}
            setDocumentLoadError={jest.fn()}
            setPageDimensions={jest.fn()}
            setPdfDocument={jest.fn()}
            setRenderStartTime={setRenderStartTime}
          />
        );
      });

      afterAll(() => {
        cleanup();
        jest.clearAllMocks();
      });

      it('records metrics with additionalInfo when x-document-source is present in response headers', () => {
        expect(recordAsyncMetrics).toBeCalledWith(
          metricArgs()[0],
          metricArgs()[1],
          metricArgs(true)[2]
        );
      });

      it('calls storeMetrics in catch block', () => {
        waitFor(() => {
          expect(storeMetrics).toBeCalledWith(
            storeMetricsError.uuid,
            storeMetricsError.data,
            storeMetricsError.info,
            storeMetricsError.eventId
          );
        });
      });

      it('clears measureTimeStartMs after unmount', async () => {
        const simulatedStartTime = Date.now();
        setRenderStartTime(simulatedStartTime);;

        waitFor(() => {
          expect(setRenderStartTime).toHaveBeenCalledWith(simulatedStartTime);
        });

        cleanup();

        waitFor(() => {
          expect(setRenderStartTime).toHaveBeenCalledWith(null);
        });
      });

      it.skip('calls sotoreMetrics when getDocument fails', async () => {

        const timeoutError = new Error('Timeout error');

        // Mock ApiUtil.get to simulate a timeout error
        ApiUtil.get.mockRejectedValueOnce(timeoutError);

        // Trigger the getDocument method which initiates the API call
        await wrapper.instance().getDocument();
        // Only metric should be created per error event
        expect(storeMetrics).toHaveBeenCalledTimes(1);

        // Verify that storeMetrics is called with the correct error metric arguments
        expect(storeMetrics).toHaveBeenCalledWith(
          expect.any(String),
          {
            documentId: documents[0].id,
            documentType: 'test',
            file: documents[0].content_url,
            step: 'getDocument',
            reason: timeoutError,
            prefetchDisabled: undefined,
            bandwidth: '5 Mbits/s',

          },
          {
            message: expect.stringContaining(`Getting PDF document: "${documents[0].content_url}"`),
            type: 'error',
            product: 'reader'
          },
          expect.any(String)
        );

        jest.clearAllMocks();
      });

      it.skip('calls storeMetrics when getPage fails', async () => {
        ApiUtil.get.mockResolvedValue({
          body: {},
          header: { 'x-document-source': 'VBMS' }
        });

        const error = new Error('Failed to get pages');

        jest.spyOn(wrapper.instance(), 'getPages').mockImplementation(() => {
          return Promise.reject(error);
        });

        await wrapper.instance().getDocument();

        expect(storeMetrics).toHaveBeenCalledTimes(1);
        expect(storeMetrics).toHaveBeenLastCalledWith(
          expect.any(String),
          {
            documentId: documents[0].id,
            documentType: 'test',
            file: documents[0].content_url,
            step: 'setPageDimensions',
            reason: error,
            prefetchDisabled: undefined,
            bandwidth: '5 Mbits/s',

          },
          {
            message: expect.stringContaining(`Getting PDF document: "${documents[0].content_url}"`),
            type: 'error',
            product: 'reader'
          },
          expect.any(String)
        );
      });

      describe('when internet bandwidth is not available', () => {

        beforeEach(() => {
          networkUtil.connectionInfo.mockResolvedValueOnce('Not available');
          // This component throws an error about halfway through getDocument at destroy
          // giving it access to both recordAsyncMetrics and storeMetrics
          wrapper = shallow(
            <PdfFile
              documentId={documents[0].id}
              key={`${documents[0].content_url}`}
              file={documents[0].content_url}
              onPageChange= {jest.fn()}
              isVisible
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

        afterEach(() => {
          jest.clearAllMocks();
        });

        it.skip('handles bandwidth: Not available from NetworkUtil', async () => {
          const timeoutError = new Error('Timeout error');

          jest.clearAllMocks();

          // Mock ApiUtil.get to simulate a timeout error
          ApiUtil.get.mockRejectedValueOnce(timeoutError);
          await wrapper.instance().getDocument();

          expect(storeMetrics).toHaveBeenLastCalledWith(
            expect.any(String),
            {
              documentId: documents[0].id,
              documentType: 'test',
              file: documents[0].content_url,
              step: 'getDocument',
              reason: timeoutError,
              prefetchDisabled: undefined,
              bandwidth: 'Not available'

            },
            {
              message: expect.stringContaining(
                `Getting PDF document: "${documents[0].content_url}"`),
              type: 'error',
              product: 'reader'
            },
            expect.any(String)
          );
        });
      });
    });
  });
});
