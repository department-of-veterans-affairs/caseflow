import React from 'react';
import { connect } from 'react-redux';
import { rightTriangle } from '../components/RenderFunctions';

class LastReadIndicator extends React.PureComponent {
  render() {
    if (!this.props.shouldShow) {
      return null;
    }

    return <span
      id="read-indicator"
      ref={this.props.getRef}
      aria-label="Most recently read document indicator">
      {rightTriangle()}
    </span>;
  }
}

const lastReadIndicatorMapStateToProps = (state, ownProps) => ({
  shouldShow: state.readerReducer.ui.pdfList.lastReadDocId === ownProps.docId
});

export default connect(lastReadIndicatorMapStateToProps)(LastReadIndicator);
