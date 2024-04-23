import React from 'react';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { handleSetOverscanValue } from '../reader/PdfViewer/PdfViewerActions';

export class WindowSlider extends React.Component {
  onSlide = (event) => {
    this.props.handleSetOverscanValue(event.target.value);
  }

  render = () => {
    return <span>
      <input
        type="range"
        value={this.props.windowingOverscan}
        min="1"
        max="100"
        onChange={this.onSlide}
      />
      Overscan: {this.props.windowingOverscan}
    </span>;
  }
}

const mapStateToProps = (state) => {
  return {
    windowingOverscan: state.pdfViewer.windowingOverscan
  };
};
const mapDispatchToProps = (dispatch) => ({
  ...bindActionCreators({
    handleSetOverscanValue
  }, dispatch)
});

export default connect(
  mapStateToProps, mapDispatchToProps
)(WindowSlider);
