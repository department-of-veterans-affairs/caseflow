import React, { PropTypes } from 'react';

import PdfViewer from '../components/PdfViewer';

export default class DecisionReviewer extends React.Component {
  constructor(props) {
    super(props);

    this.state = { pdf: 0 };
  }

  componentDidMount() {
    window.addEventListener('keydown', (event) => {
      if (event.key === 'ArrowLeft') {
        this.setState({
          pdf: Math.max(this.state.pdf - 1, 0)
        });
      }
      if (event.key === 'ArrowRight') {
        this.setState({
          pdf: Math.min(this.state.pdf + 1, this.props.pdfLinks.length - 1)
        });
      }
    });
  }

  render() {
    let { pdfLinks } = this.props;

    return (
      <div>
        <PdfViewer
          file={pdfLinks[this.state.pdf]} />
      </div>
    );
  }
}

DecisionReviewer.propTypes = {
  pdfLinks: PropTypes.arrayOf(PropTypes.string).isRequired
};
