import { cleanup } from '@testing-library/react';
import {
  pdfPageRenderTimeInMsEnabled,
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
});
