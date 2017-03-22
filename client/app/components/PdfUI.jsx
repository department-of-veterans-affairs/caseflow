import React, { PropTypes } from 'react';
import Button from '../components/Button';
import DocumentLabels from '../components/DocumentLabels';
import Pdf from '../components/Pdf';

export const linkToSingleDocumentView = (doc) => {
  let id = doc.id;
  let filename = doc.filename;
  let type = doc.type;
  let receivedAt = doc.received_at;

  return `/decision/review/show?id=${id}&type=${type}` +
    `&received_at=${receivedAt}&filename=${filename}`;
};

export default class PdfUI extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      scale: 1,
      currentPage: 1,
      numPages: 1
    };
  }

  zoom = (delta) => () => {
    // TODO: Fix scrolling when zooming
    // let zoomFactor = (this.state.scale + delta) / this.state.scale;

    this.setState({
      scale: this.state.scale + delta
    });
    // this.draw(this.props.file,
    //   document.getElementById('scrollWindow').scrollTop * zoomFactor);
  }

  onColorLabelChange = (label) => () => {
    if (label === this.props.label) {
      this.props.setLabel('');
    } else {
      this.props.setLabel(label);
    }
  }

  onPageChange = (currentPage, numPages) => {
    this.setState({
      currentPage,
      numPages
    });
  }

  render() {
    let selectedLabels = {};

    selectedLabels[this.props.label] = true;

    return <div className="cf-pdf-container">
      <div className="cf-pdf-header cf-pdf-toolbar">
        <div>
          <span className="cf-pdf-buttons-left">
            { this.props.showList &&
              <Button
                name="backToDocuments"
                classNames={["cf-pdf-button"]}
                onClick={this.props.showList}>
                <i className="fa fa-chevron-left" aria-hidden="true"></i>
                &nbsp; View all documents
              </Button> }
          </span>
          <span className="cf-right-side">
            <Button
              name="newTab"
              classNames={["cf-pdf-button"]}
              onClick={() => window.open(
                linkToSingleDocumentView(this.props.doc), '_blank')}>
              {this.props.doc.filename}
            </Button>
          </span>
        </div>
      </div>
      <div className="cf-pdf-navigation">
        { this.props.previousPdf &&
          <span className="cf-pdf-buttons-left">
            <Button
              name="previous"
              classNames={["cf-pdf-button"]}
              onClick={this.props.previousPdf}>
              <i className="fa fa-arrow-circle-left fa-3x" aria-hidden="true"></i>
            </Button>
          </span> }
        { this.props.nextPdf &&
          <span className="cf-pdf-buttons-right">
            <Button
              name="next"
              classNames={["cf-pdf-button cf-right-side"]}
              onClick={this.props.nextPdf}>
              <i className="fa fa-arrow-circle-right fa-3x" aria-hidden="true"></i>
            </Button>
          </span> }
      </div>
      <div>
        <Pdf
          documentId={this.props.doc.id}
          file={this.props.file}
          pdfWorker={this.props.pdfWorker}
          id={this.props.id}
          onPageClick={this.props.onPageClick}
          scale={this.state.scale}
          onPageChange={this.onPageChange}
        />
      </div>
      <div className="cf-pdf-footer cf-pdf-toolbar">
        <div className="usa-grid-full">
          <div className="usa-width-one-third cf-pdf-buttons-left">
            <DocumentLabels
              onClick={this.onColorLabelChange}
              selectedLabels={selectedLabels}/>
          </div>
          <div className="usa-width-one-third cf-pdf-buttons-center">
            Page {this.state.currentPage} of {this.state.numPages}
          </div>
          <div className="usa-width-one-third cf-pdf-buttons-right">
            <Button
              name="download"
              classNames={["cf-pdf-button cf-pdf-spaced-buttons"]}
            >
              <i className="cf-pdf-button fa fa-download" aria-hidden="true"></i>
            </Button>
            <Button
              name="zoomOut"
              classNames={["cf-pdf-button cf-pdf-spaced-buttons"]}
              onClick={this.zoom(-0.3)}>
              <i className="fa fa-minus" aria-hidden="true"></i>
            </Button>
            <Button
              name="fit"
              classNames={["cf-pdf-button cf-pdf-spaced-buttons"]}
              onClick={this.zoom(1)}>
              <i className="fa fa-arrows-alt" aria-hidden="true"></i>
            </Button>
            <Button
              name="zoomIn"
              classNames={["cf-pdf-button cf-pdf-spaced-buttons"]}
              onClick={this.zoom(0.3)}>
              <i className="fa fa-plus" aria-hidden="true"></i>
            </Button>
          </div>
        </div>
      </div>
    </div>;
  }
}

PdfUI.propTypes = {
  doc: PropTypes.object.isRequired,
  file: PropTypes.string.isRequired,
  id: PropTypes.string.isRequired,
  pdfWorker: PropTypes.string.isRequired,
  onPageClick: PropTypes.func,
  showList: PropTypes.func
};
