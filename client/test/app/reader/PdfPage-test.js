import uuid, { v4 as uuidv4 } from 'uuid';
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
  v4: jest.fn().mockReturnValue("1234")
}));

describe('PdfPage', () => {

  afterEach(() => {
    cleanup();
    jest.clearAllMocks();
  })

  describe('.render', () => {
    it('renders outer div', () => {
      const wrapper = pdfPageRenderTimeInMsEnabled();

      expect(wrapper.find('.cf-pdf-pdfjs-container')).toHaveLength(1);
    });
  });

  describe('pdfPageRenderTimeInMs is enabled', () => {
    beforeAll(() => {
      const wrapper = pdfPageRenderTimeInMsEnabled();
      const instance = wrapper.instance()
      jest.spyOn(instance, 'getText').mockImplementation(() =>
        new Promise((resolve) => resolve({ data: {} })));
      jest.spyOn(instance, 'drawPage').mockImplementation(() =>
        new Promise((resolve) => resolve({ data: {} })));
      jest.spyOn(instance, 'drawText').mockReturnValue("Test");
    });
    it('metrics are stored and recorded', () => {

      expect(recordAsyncMetrics).toHaveBeenCalledTimes(2)
      expect(recordAsyncMetrics).toHaveBeenCalledWith(...pageMetricData);
      expect(recordAsyncMetrics).toHaveBeenCalledWith(...pageMetricData);
      expect(recordMetrics).toHaveBeenCalledWith(...recordMetricsArgs);
      expect(storeMetrics).toHaveBeenCalledWith(...storeMetricsData);
    });
  });

  describe('metricsPdfStorePages is enabled with error thrown', () => {

    beforeAll(() => {
      const wrapper = pdfPageRenderTimeInMsEnabled();
      const instance = wrapper.instance()
      jest.spyOn(instance, 'getText').mockImplementation(() => { throw new Error() });
    });

    it('Error is thrown and browser error metric is stored', () => {

      expect(storeMetrics).toHaveBeenCalledWith(...storeMetricsBrowserError);
    });
  });

  describe('pdfPageRenderTimeInMs is disabled', () => {
    beforeAll(() => {
      const wrapper = pdfPageRenderTimeInMsDisabled();
      const instance = wrapper.instance()
      jest.spyOn(instance, 'getText').mockImplementation(() =>
        new Promise((resolve) => resolve({ data: {} })));
      jest.spyOn(instance, 'drawPage').mockImplementation(() =>
        new Promise((resolve) => resolve({ data: {} })));
      jest.spyOn(instance, 'drawText').mockReturnValue("Test");
    });

    it('metrics are not stored', () => {
      expect(recordAsyncMetrics).toHaveBeenCalledTimes(2)
      expect(recordAsyncMetrics).toHaveBeenCalledWith(...pageMetricData);
      expect(recordAsyncMetrics).toHaveBeenCalledWith(...pageMetricData);
      expect(recordMetrics).toHaveBeenCalledWith(...recordMetricsArgs);
      expect(storeMetrics).not.toBeCalled();
    });
  });

  describe('pdfPageRenderTimeInMs is disabled with error thrown', () => {

    beforeAll(() => {
      const wrapper = metricsPdfStorePagesDisabled();
      const instance = wrapper.instance()
      jest.spyOn(instance, 'getText').mockImplementation(() => { throw new Error() });
    });

    it('Error is thrown and browser error metric is not stored', () => {

      expect(storeMetrics).not.toBeCalled();
    });
  });
});
