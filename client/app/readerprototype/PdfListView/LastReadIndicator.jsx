import React from 'react';
import { connect } from 'react-redux';
import { RightTriangleIcon } from '../components/icons/RightTriangleIcon';
import PropTypes from 'prop-types';

class LastReadIndicator extends React.PureComponent {
  render() {
    if (!this.props.shouldShow) {
      return null;
    }

    return <span
      id="read-indicator"
      ref={this.props.getRef}
      aria-label="Most recently read document indicator">
      <RightTriangleIcon />
    </span>;
  }
}

const lastReadIndicatorMapStateToProps = (state, ownProps) => ({
  shouldShow: state.documentList.pdfList.lastReadDocId === ownProps.docId
});

LastReadIndicator.propTypes = {
  shouldShow: PropTypes.bool,
  getRef: PropTypes.func
};

export default connect(lastReadIndicatorMapStateToProps)(LastReadIndicator);

