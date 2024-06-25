// NetworkUtil.test.js
import networkUtil from '../../../app/util/NetworkUtil';

describe('NetworkUtil', () => {
  describe('connectionInfo', () => {
    beforeEach(() => {
      jest.spyOn(console, 'log').mockImplementation();
    });
    afterEach(() => {
      // eslint-disable-next-line no-console
      console.log.mockRestore();
    });
    if (typeof navigator.connection === 'undefined') {
      it('should handle browsers where Network Information API is not supported', async () => {
        await networkUtil.connectionInfo();
        expect(networkUtil.bandwidth).toBeNull();
        expect(await networkUtil.connectionInfo()).toBe('Speed: Not available');
        // eslint-disable-next-line no-console
        expect(console.log).toHaveBeenCalledWith('Network Information API not supported in this browser');
      });
    } else {
      it('should return speed in Mbits/s if the browser supports the Network Information API', async () => {
        await networkUtil.connectionInfo();
        expect(networkUtil.bandwidth).toBe(navigator.connection.downlink);
        expect(await networkUtil.connectionInfo()).toMatch(/Speed: \d+ Mbits\/s/);
      });
    }
  });
});
