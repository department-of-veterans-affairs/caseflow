import React from 'react';
import Error500 from 'app/errors/Error500';
import PropTypes from 'prop-types';

/**
 * ErrorBoundary -- Wraps all components to provide a friendly error screen instead of an empty screen
 */
export class ErrorBoundary extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      error: '',
      info: '',
    };
  }

  componentDidCatch(error, info) {
    this.setState({
      error,
      info,
    });
  }

  render() {
    const { error, info } = this.state;

    if (info) {
      // eslint-disable-next-line
      const errorDetails = process.env.NODE_ENV === 'development' ? (
        <React.Fragment>
          <h2 className="error">An unexpected error has occurred.</h2>
          <details className="preserve-space">
            {error && error.toString()}
            <br />
            {info.componentStack}
          </details>
        </React.Fragment>
      ) : (
        <Error500 />
      );

      return (
        <div>
          {errorDetails}
        </div>
      );
    }

    return this.props.children;
  }
}

ErrorBoundary.propTypes = {
  children: PropTypes.element
}
;
