import ProgressBarUtil from '../../../../app/readerprototype/util/ProgressBarUtil';
import { storeMetrics } from '../../../../../client/app/util/Metrics';
jest.mock('../../../../../client/app/util/Metrics', () => ({
  storeMetrics: jest.fn(),
}));
describe('ProgressBarUtil', () => {
  describe('calculateProgress', () => {
    it('returns 0 if fileSize is 0', () => {
      const result = ProgressBarUtil.calculateProgress({ loaded: 500, fileSize: 0 });

      expect(result).toBe(0);
    });
    it('calculates the correct percentage', () => {
      const result = ProgressBarUtil.calculateProgress({ loaded: 50, fileSize: 100 });

      expect(result).toBe(50);
    });
    it('rounds to the nearest integer', () => {
      const result = ProgressBarUtil.calculateProgress({ loaded: 33, fileSize: 100 });

      expect(result).toBe(33);
    });
  });
  describe('shouldShowProgressBar', () => {
    const readerPreferences = {
      delayBeforeProgressBar: 2000,
      showProgressBarThreshold: 1000,
    };

    it('returns false if delayBeforeProgressBar or showProgressBarThreshold is not set', () => {
      expect(
        ProgressBarUtil.shouldShowProgressBar({
          elapsedTime: 3000,
          downloadSpeed: 10,
          percentage: 5,
          loaded: 500,
          fileSize: 10000,
          readerPreferences: {},
        })
      ).toBe(false);
    });
    it('returns false if percentage is 100', () => {
      expect(
        ProgressBarUtil.shouldShowProgressBar({
          elapsedTime: 3000,
          downloadSpeed: 10,
          percentage: 100,
          loaded: 1000,
          fileSize: 1000,
          readerPreferences,
        })
      ).toBe(false);
    });
    it('returns true if elapsedTime exceeds delay and projected end time is above threshold', () => {
      expect(
        ProgressBarUtil.shouldShowProgressBar({
          elapsedTime: 3000,
          downloadSpeed: 10,
          percentage: 5,
          loaded: 500,
          fileSize: 12000,
          readerPreferences,
        })
      ).toBe(true);
    });
    it('returns false if projected end time is below threshold', () => {
      expect(
        ProgressBarUtil.shouldShowProgressBar({
          elapsedTime: 3000,
          downloadSpeed: 100,
          percentage: 50,
          loaded: 500,
          fileSize: 1000,
          readerPreferences,
        })
      ).toBe(false);
    });
  });
  describe('logCancelRequest', () => {
    const progressData = {
      progressPercentage: 50,
      loadedBytes: 500,
      totalBytes: 1000,
    };
    const documentId = 'doc123';
    const userId = 'user456';
    const getStartTime = new Date().getTime() - 2000;

    it('calls storeMetrics with correct parameters', () => {
      ProgressBarUtil.logCancelRequest({
        progressData,
        documentId,
        userId,
        getStartTime,
      });
      const elapsedTime = expect.any(Number);
      const downloadSpeed = expect.any(Number);

      expect(storeMetrics).toHaveBeenCalledWith(
        documentId,
        {
          user_id: userId,
          download_percent: progressData.progressPercentage,
          document_size_bytes: progressData.totalBytes,
          elapsed_time_ms: elapsedTime,
          download_speed_mbits_sec: downloadSpeed,
        },
        {
          message: 'Reader Progress Bar User Cancelled Request',
          type: 'performance',
          product: 'reader prototype',
          start: null,
          end: null,
          duration: null,
        },
        null
      );
    });
  });
});
