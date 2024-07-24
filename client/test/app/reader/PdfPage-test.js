import { recordMetrics, storeMetrics, recordAsyncMetrics } from '../../../app/util/Metrics';
import { cleanup } from '@testing-library/react';
import { render, screen, waitFor } from '@testing-library/react';
import {
  metricsPdfStorePagesDisabled,
  pageMetricData,
  pdfPageRenderTimeInMsDisabled,
  pdfPageRenderTimeInMsEnabled,
  recordMetricsArgs,
  storeMetricsBrowserError,
  storeMetricsData
} from '../../helpers/PdfPageTests';
import {PdfPage} from '../../../app/reader/PdfPage';

jest.mock('../../../app/util/Metrics', () => ({
  storeMetrics: jest.fn().mockReturnThis(),
  recordMetrics: jest.fn().mockReturnThis(),
  recordAsyncMetrics: jest.fn().mockImplementation(() => Promise.resolve())
}));



jest.mock('uuid', () => ({
  v4: jest.fn().mockReturnValue('1234')
}));

const getFiberNode = (element) => {
  const key = Object.keys(element).find(key => key.startsWith('__reactFiber$'));
  return element[key];
};

function extractPropsAndState(fiberNode) {
  if (!fiberNode) return null;

  // Traverse up the tree to find the relevant component node
  while (fiberNode.return) {
    fiberNode = fiberNode.return;
    if (fiberNode.memoizedProps && fiberNode.memoizedState) {
      return {
        pendingProps: fiberNode.pendingProps,
        memoizedProps: fiberNode.memoizedProps,
        memoizedState: fiberNode.memoizedState,
      };
    }
  }
  return null;
}

describe('PdfPage', () => {
  afterEach(() => {
    cleanup();
    jest.clearAllMocks();
  });

  describe('.render', () => {
    it('renders outer div', () => {
      const {container} = pdfPageRenderTimeInMsEnabled();

      expect(container.querySelector('.cf-pdf-pdfjs-container')).toBeInTheDocument();
    });
  });

  describe('when pdfPageRenderTimeInMs is enabled', () => {
    beforeAll(() => {
      pdfPageRenderTimeInMsEnabled();

      jest.spyOn(PdfPage.prototype, 'getText').mockImplementation(() =>
        Promise.resolve({ data: {} })
      );
      jest.spyOn(PdfPage.prototype, 'drawPage').mockImplementation(() =>
        Promise.resolve()
      );
      jest.spyOn(PdfPage.prototype, 'drawText').mockReturnValue('Test');
    });

    it('metrics are stored and recorded', async () => {
      // pdfPageRenderTimeInMsEnabled();
      expect(recordAsyncMetrics).toHaveBeenCalledTimes(2);
      expect(recordAsyncMetrics).toHaveBeenCalledWith(...pageMetricData);
      expect(recordAsyncMetrics).toHaveBeenCalledWith(...pageMetricData);
      expect(recordMetrics).toHaveBeenCalledWith(...recordMetricsArgs);

      const pdfPage = screen.getByTestId('pdf-page');
      const fiberNode = getFiberNode(pdfPage);
      const extractedData = extractPropsAndState(fiberNode);
      const memoizedProps = extractedData.memoizedProps;
      const pageIndex = memoizedProps.children.props.pageIndex;
      // console.log(memoizedState);

        // console.log(recordAsyncMetrics.mock.calls);
      await waitFor(() => {
        expect(PdfPage.prototype.getText).toHaveBeenCalled();
        expect(PdfPage.prototype.drawPage).toHaveBeenCalled();
        expect(PdfPage.prototype.drawText).toHaveBeenCalled();
      });

      screen.debug();

        // expect(storeMetrics).toHaveBeenCalledWith(...storeMetricsData);
        // expect(storeMetrics).toHaveBeenCalledWith(...storeMetricsData);
      // if (pageIndex === 0) {
      // }
    });
  });

  describe('when pdfPageRenderTimeInMs is disabled with error thrown', () => {
    beforeAll(() => {
      metricsPdfStorePagesDisabled();
      jest.spyOn(PdfPage.prototype, 'getText').mockImplementation(() => {
        throw new Error();
      });
    });
    it('storeMetrics is not called', () => {
      expect(storeMetrics).not.toBeCalled();
    });
  });

  describe('when pdfPageRenderTimeInMs is disabled', () => {
    beforeAll(() => {
      const {container} = pdfPageRenderTimeInMsDisabled();
      jest.spyOn(PdfPage.prototype, 'getText').mockImplementation(() =>
        Promise.resolve({ data: {} })
      );
      jest.spyOn(PdfPage.prototype, 'drawPage').mockImplementation(() =>
        Promise.resolve()
      );
      jest.spyOn(PdfPage.prototype, 'drawText').mockReturnValue('Test');
    });
    it('storeMetrics is not called', () => {
      expect(storeMetrics).not.toBeCalled();
    });
  });

  describe('when metricsPdfStorePages is enabled and error thrown', () => {
    beforeAll(() => {
      pdfPageRenderTimeInMsEnabled();
      jest.spyOn(PdfPage.prototype, 'getText').mockImplementation(() => {
        throw new Error();
      });
    });
    it('storeMetrics is called with browser error', () => {
      expect(storeMetrics).toHaveBeenCalledWith(...storeMetricsBrowserError);
    });
  });
});
