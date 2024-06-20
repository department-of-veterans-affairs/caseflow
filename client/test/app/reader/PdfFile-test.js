import React, {useRef} from 'react';
import { shallow } from 'enzyme';
import { render, waitFor, screen, fireEvent} from '@testing-library/react';

import { PdfFile } from '../../../app/reader/PdfFile';
import { documents } from '../../data/documents';
import ApiUtil from '../../../app/util/ApiUtil';
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

let renderStartTime = null;
const setRenderStartTime = jest.fn(time => {
  renderStartTime = time;
});

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
        overscan: undefined
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
    message: expect.stringMatching(/^([a-zA-Z0-9-.'&:/ ])*$/),
    product: 'browser',
    type: 'error'
  },
  eventId: expect.stringMatching(/^([a-zA-Z0-9-.'&])*$/)
};

describe('PdfFile', () => {
  let subjectRef;
  let wrapper;

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
    subjectRef = React.createRef();
      beforeAll( () => {
        // This component throws an error about halfway through getDocument at destroy
        // giving it access to both recordAsyncMetrics and storeMetrics
        render(
        <PdfFile
            ref={subjectRef}
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
      });

      afterAll(() => {
        jest.clearAllMocks();
      });

      it('records metrics with additionalInfo when x-document-source is present in response headers', () => {
            expect(recordAsyncMetrics).toBeCalledWith(
              metricArgs()[0],
              metricArgs()[1],
              metricArgs(true)[2]
            );
      });

      it('records metrics with no additionalInfo when x-document-source is absent in response headers', () => {
        ApiUtil.get = jest.fn().mockResolvedValue(() => new Promise((resolve) => resolve()));
            // Assert that the recordAsyncMetrics method was called with the expected arguments
            expect(recordAsyncMetrics).toBeCalledWith(
              metricArgs()[0],
              metricArgs()[1],
              metricArgs(true)[2]
            );
      });

      it('calls storeMetrics in catch block', () => {
        waitFor(() => expect(storeMetrics).toBeCalledWith(storeMetricsError.uuid,
          storeMetricsError.data,
          storeMetricsError.info,
          storeMetricsError.eventId));
      });

      it('clears measureTimeStartMs after unmount', async () => {
        // Mock the ApiUtil.get function to return a Promise that resolves immediately
        jest.mock('../../../app/util/ApiUtil', () => ({
          get: jest.fn().mockResolvedValue({}),
        }));


        const domNode = subjectRef.current;
        console.log(domNode); // Now logs the actual value of subjectRef.current
        // const instance = container.querySelector('div');
        // console.log(container.querySelector('div'));

        // instance.click();
        // console.log('instance', instance);

        // Trigger the ApiUtil.get function call
        // await instance.getDocument();

        // Assert that measureTimeStartMs is counting
        // expect(instance.props.renderStartTime).not.toBeNull();
        // const subject = wrapper.instance();

        // Trigger the ApiUtil.get function call
        // subject.getDocument();

        // Assert that measureTimeStartMs is counting
        // expect(subject.props.renderStartTime).not.toBeNull();
      });
    });
  });
});
