// NetworkUtil.test.js
import networkUtil from '../../../app/util/NetworkUtil';

describe('NetworkUtil', () => {
  describe('connectionInfo', () => {
    let originalNavigator;

    beforeEach(() => {
      originalNavigator = global.navigator;
    });
    afterEach(() => {
      global.navigator = originalNavigator;
    });

    it('should handle browsers where Network Information API is not supported', async () => {
      Object.defineProperty(global.navigator, 'connection', {
        value: undefined,
        writable: true
      });

      await networkUtil.connectionInfo();
      expect(networkUtil.bandwidth).toBeNull();
      expect(await networkUtil.connectionInfo()).toBe('Not available');

    });

    it('should return bandwidth in Mbits/s if the browser supports the Network Information API', async () => {
      Object.defineProperty(global.navigator, 'connection', {
        value: {
          downlink: 5,
          effectiveType: '4g'
        },
        writable: true
      });

      await networkUtil.connectionInfo();
      expect(networkUtil.bandwidth).toBe(navigator.connection.downlink);
      expect(await networkUtil.connectionInfo()).toMatch(/\d+ Mbits\/s/);
    });

  });
});
