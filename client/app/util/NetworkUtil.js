// NetworkUtil.js

class NetworkUtil {
  constructor() {
    this.bandwidth = null;
  }

  async getConnectionInfo() {
    try {
      if ('connection' in navigator) {
        const connection = navigator.connection || navigator.mozConnection || navigator.webkitConnection;

        // Update network details during connectionInfo()
        this.bandwidth = connection.downlink;
      } else {
        // eslint-disable-next-line no-console
        console.log('Network Information API not supported in this browser');
      }
    } catch (error) {
      // eslint-disable-next-line no-console
      console.error('Error getting connection info:', error);
    }
  }

  async connectionInfo() {
    await this.getConnectionInfo();

    // Handle case where bandwidth is not set
    if (this.bandwidth === null) {
      return 'Not available';
    }

    return `${this.bandwidth} Mbits/s`;
  }
}

const networkUtil = new NetworkUtil();

export default networkUtil;
