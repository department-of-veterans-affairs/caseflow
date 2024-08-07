import React from 'react';
import Alert from '../components/Alert';
import { css } from 'glamor';
import { storeMetrics } from '../util/Metrics';
import uuid from 'uuid';

const alertStyling = css({
  marginBottom: '20px'
});

class BandwidthAlert extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      //downlink: null,
      displayBandwidthAlert: true
    };
  }

  componentDidMount() {
    if ('connection' in navigator) {
      this.updateConnectionInfo();
      // const connection = navigator.connection || navigator.mozConnection || navigator.webkitConnection;

      // connection.addEventListener('change', this.updateConnectionInfo);

    }
  }

  // componentWillUnmount() {
  //   if ('connection' in navigator) {
  //     const connection = navigator.connection || navigator.mozConnection || navigator.webkitConnection;

  //     connection.removeEventListener('change', this.updateConnectionInfo);
  //   }
  // }

  updateConnectionInfo = () => {
    const connection = navigator.connection || navigator.mozConnection || navigator.webkitConnection;

    if (connection.downlink && connection.downlink < 1.5) {
      const logId = uuid.v4();

      storeMetrics(logId, { bandwidth: this.state.downlink }, {
        message: 'Bandwidth Alert Displayed',
        type: 'metric',
        product: 'reader'
      },
      null);
      this.setState({ displayBandwidthAlert: true });
    }
  };
//  const { displayBandwidthAlert } = this.state;
  render() {

    if (this.state.displayBandwidthAlert) {
      return (
        <div {...alertStyling}>
          <Alert title="Slow bandwidth" type="warning">
            You may experience slower downloading times for certain files based on your
            bandwidth speed and document size.
            <br />
          </Alert>
        </div>
      );
    }

    return null;
  }
}

export default BandwidthAlert;
