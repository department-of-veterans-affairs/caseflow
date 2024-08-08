import { recordMetrics, storeMetrics, recordAsyncMetrics } from '../../../app/util/Metrics';
import { cleanup } from '@testing-library/react';
import { waitFor } from '@testing-library/react';
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
      expect(recordAsyncMetrics).toHaveBeenCalledTimes(2);
      expect(recordAsyncMetrics).toHaveBeenCalledWith(...pageMetricData);
      expect(recordAsyncMetrics).toHaveBeenCalledWith(...pageMetricData);
      expect(recordMetrics).toHaveBeenCalledWith(...recordMetricsArgs);

      await waitFor(() => {
        expect(PdfPage.prototype.getText).toHaveBeenCalled();
        expect(PdfPage.prototype.drawPage).toHaveBeenCalled();
        expect(PdfPage.prototype.drawText).toHaveBeenCalled();
      });
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
      pdfPageRenderTimeInMsDisabled();
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
