import React from 'react';
import LoadingScreen from '../components/LoadingScreen';

export default class AsynchronousDataLoader extends React.Component {

  constructor(props) {
    super(props);
    this.state = {
      showLoader: true,
      message: this.props.message
    };
  }

  runPromise() {
    this.props.componentsPromise(this.props.endpoint).
      then((data) => {
        if (!JSON.parse(data.text).loading_data && !JSON.parse(data.text).loading_data_failed) {
          this.setState({
            showLoader: false,
            eventHasHappened: true,
            promiseRejected: false,
            data
          });
        } else if (JSON.parse(data.text).loading_data_failed) {
          this.setState({
            showLoader: false,
            eventHasHappened: true,
            promiseRejected: true,
            error: data
          });
        }
      },
      (error) => {
        this.setState({
          showLoader: false,
          eventHasHappened: true,
          promiseRejected: true,
          error
        });
      });
  }

  componentDidMount() {
    // initial check
    this.runPromise();

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

  componentDidUpdate() {
    // subsequent checks if data is still loading
    if (!this.state.data && !this.state.promiseRejected && !this.state.timeout && !this.state.eventHasHappened) {
      setTimeout(() =>
        this.runPromise(),
      this.props.pollingIntervalSeconds);
    }
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
        (this.state.eventHasHappened && !this.state.promiseRejected) && this.props.onSuccess(this.state.data)
      }
    </div>;
  }
}

