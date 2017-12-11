import React from 'react';
import LoadingScreen from '../components/LoadingScreen';
import PropTypes from 'prop-types';

export default class AsynchronousDataLoader extends React.Component {

  constructor(props) {
    super(props);
    this.state = {
      showLoader: true,
      message: this.props.message
    };
  }

  componentDidMount() {
    this.props.promiseToResolve.
      then((data) => {
        this.setState({
          showLoader: false,
          eventHasHappened: true,
          promiseRejected: false,
          data
        });
      },
      (error) => {
        this.setState({
          showLoader: false,
          eventHasHappened: true,
          promiseRejected: true,
          error
        });
      });

    // Timer for longer-than-usual message
    setTimeout(
      () => {
        this.setState({
          message: this.props.extendedWaitMessage
        });
      },
      this.props.showExtendedWaitMessageInSeconds
    );
    // Timer for overall timeout
    setTimeout(
      () => {
        this.setState({
          showLoader: false,
          timeout: true
        });
      },
      this.props.showErrorMessageInSeconds
    );
  }

  render() {

    return <div>
      {
        this.state.showLoader && <LoadingScreen
          message={this.state.message}
          spinnerColor={this.props.spinnerColor} />
      }
      {
        ((this.state.timeout && !this.state.eventHasHappened) || this.state.promiseRejected) &&
      this.props.onError(this.state.error)
      }
      {
        (this.state.eventHasHappened && !this.state.promiseRejected) &&
        this.props.onSuccess(this.state.data)
      }
    </div>;
  }
}

AsynchronousDataLoader.propTypes = {
  promiseToResolve: PropTypes.object.isRequired,
  spinnerColor: PropTypes.string.isRequired,
  message: PropTypes.string.isRequired,
  extendedWaitMessage: PropTypes.string.isRequired,
  showExtendedWaitMessageInSeconds: PropTypes.number.isRequired,
  onSuccess: PropTypes.func.isRequired,
  onError: PropTypes.func.isRequired,
  showErrorMessageInSeconds: PropTypes.number.isRequired
};
