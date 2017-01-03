import React from 'react';
import { PDFJS } from 'pdfjs-dist/web/pdf_viewer.js';
import PDFJSAnnotate from 'pdf-annotate.js';
 
class MyPdfViewer extends React.Component {
  constructor(props) {
    super(props);
    this.state = {};
    PDFJS.disableWorker = true;
    //PDFJSAnnotate.setStoreAdapter(MyStoreAdapter);
    
    var DEFAULT_URL = this.props.file;
    // Loading document.
    PDFJS.getDocument(DEFAULT_URL).then((pdfDocument) => {
      this.setState({pdfDocument: pdfDocument});
    });

  }
  componentDidUpdate() {
    const { UI } = PDFJSAnnotate;
    // const VIEWER = document.getElementById('viewer');
    // const RENDER_OPTIONS = {
    //   documentId: this.props.pdfLink,
    //   pdfDocument: null,
    //   scale: 1,
    //   rotate: 0
    // };

    // PDFJS.workerSrc = '../../build/webpack/pdf.worker.bundle.js';
    // PDFJSAnnotate.setStoreAdapter(MyStoreAdapter);

    // PDFJS.getDocument(RENDER_OPTIONS.documentId).then((pdf) => {
    //   RENDER_OPTIONS.pdfDocument = pdf;
    //   VIEWER.appendChild(UI.createPage(1));
    //   UI.renderPage(1, RENDER_OPTIONS);
    // });
    //PDFJS.workerSrc = '../../../node_modules/pdfjs-dist/build/pdf.worker.bundle.js';

    //PDFJS.workerSrc = 'pdf.worker.js';
    // Document loaded, retrieving the page.
    let { pdfDocument } = this.state;
    if (pdfDocument) {
      var PAGE_TO_VIEW = 1;
      var SCALE = 1.0;

      for (let i = 0; i < pdfDocument.numPages; i++) {
        pdfDocument.getPage(i+1).then(function (pdfPage) {
          // Creating the page view with default parameters.
          var container = document.getElementById('myPageContainer' + i);

          var pdfPageView = new PDFJS.PDFPageView({
            container: container,
            id: i+1,
            scale: SCALE,
            defaultViewport: pdfPage.getViewport(SCALE),
            // We can enable text/annotations layers, if needed
            textLayerFactory: new PDFJS.DefaultTextLayerFactory(),
            annotationLayerFactory: new PDFJS.DefaultAnnotationLayerFactory()
          });
          // Associates the actual page with the view, and drawing it
          pdfPageView.setPdfPage(pdfPage);
          return pdfPageView.draw();
        });
      }  
    }
    
    
  }
 
  render() {
    let pageViews = [];
    if (this.state.pdfDocument) {
      for (let i = 0; i < this.state.pdfDocument.numPages; i++) {
        pageViews.push(<div key={i} id={"myPageContainer"+i} className="cf-pdf-page pdfViewer singlePageView"></div>)
      }  
    }

    return (
      <div className="cf-pdf-container">
        { pageViews }
      </div>
      );
  }
}
 
module.exports = MyPdfViewer;