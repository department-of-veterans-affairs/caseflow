import { recordMetrics, storeMetrics, recordAsyncMetrics } from '../../../app/util/Metrics';
import { cleanup } from '@testing-library/react';
import {
  metricsPdfStorePagesDisabled,
  pageMetricData,
  pdfPageRenderTimeInMsDisabled,
  pdfPageRenderTimeInMsEnabled,
  recordMetricsArgs,
  storeMetricsBrowserError,
  storeMetricsData
} from '../../helpers/PdfPageTests';

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
      const wrapper = pdfPageRenderTimeInMsEnabled();

      expect(wrapper.find('.cf-pdf-pdfjs-container')).toHaveLength(1);
    });
  });

  describe('when pdfPageRenderTimeInMs is enabled', () => {
    beforeAll(() => {
      const wrapper = pdfPageRenderTimeInMsEnabled();
      const instance = wrapper.instance();

      jest.spyOn(instance, 'getText').mockImplementation(() =>
        new Promise((resolve) => resolve({ data: {} })));
      jest.spyOn(instance, 'drawPage').mockImplementation(() =>
        new Promise((resolve) => resolve({ data: {} })));
      jest.spyOn(instance, 'drawText').mockReturnValue('Test');
    });

    it('metrics are stored and recorded', () => {
      expect(recordAsyncMetrics).toHaveBeenCalledTimes(2);
      expect(recordAsyncMetrics).toHaveBeenCalledWith(...pageMetricData);
      expect(recordAsyncMetrics).toHaveBeenCalledWith(...pageMetricData);
      expect(recordMetrics).toHaveBeenCalledWith(...recordMetricsArgs);
      if (pdfPageRenderTimeInMsEnabled().instance().props.pageIndex === 0) {
        expect(storeMetrics).toHaveBeenCalledWith(...storeMetricsData);
      }
    });
  });

  describe('when pdfPageRenderTimeInMs is disabled with error thrown', () => {

    beforeAll(() => {
      const wrapper = metricsPdfStorePagesDisabled();
      const instance = wrapper.instance();

      jest.spyOn(instance, 'getText').mockImplementation(() => {
        throw new Error();
      });
    });

    it('storeMetrics is not called', () => {
      expect(storeMetrics).not.toBeCalled();
    });
  });

  describe('when pdfPageRenderTimeInMs is disabled', () => {
    beforeAll(() => {
      const wrapper = pdfPageRenderTimeInMsDisabled();
      const instance = wrapper.instance();

      jest.spyOn(instance, 'getText').mockImplementation(() =>
        new Promise((resolve) => resolve({ data: {} })));
      jest.spyOn(instance, 'drawPage').mockImplementation(() =>
        new Promise((resolve) => resolve({ data: {} })));
      jest.spyOn(instance, 'drawText').mockReturnValue('Test');
    });

    it('storeMetrics is not called', () => {
      expect(storeMetrics).not.toBeCalled();
    });
  });

  describe('when metricsPdfStorePages is enabled and error thrown', () => {

    beforeAll(() => {
      const wrapper = pdfPageRenderTimeInMsEnabled();
      const instance = wrapper.instance();

      jest.spyOn(instance, 'getText').mockImplementation(() => {
        throw new Error();
      });
    });

    it('storeMetrics is called with browser error', () => {
      expect(storeMetrics).toHaveBeenCalledWith(...storeMetricsBrowserError);
    });
  });
});
