import React from 'react';
import Alert from '../components/Alert';
import { css } from 'glamor';

const alertStyling = css({
  marginBottom: '20px'
});

class BandwidthAlert extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      downlink: null,
    };
  }

  componentDidMount() {
    if ('connection' in navigator) {
      this.updateConnectionInfo();
      const connection = navigator.connection || navigator.mozConnection || navigator.webkitConnection;

      connection.addEventListener('change', this.updateConnectionInfo);
    }
  }

  componentWillUnmount() {
    if ('connection' in navigator) {
      const connection = navigator.connection || navigator.mozConnection || navigator.webkitConnection;

      connection.removeEventListener('change', this.updateConnectionInfo);
    }
  }

  updateConnectionInfo = () => {
    const connection = navigator.connection || navigator.mozConnection || navigator.webkitConnection;

    this.setState({ downlink: connection.downlink });
  };

  render() {
    const { downlink } = this.state;

    if (downlink && downlink < 1.5) {
      return (
        <div {...alertStyling}>
          <Alert title="Warning" type="warning">
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
