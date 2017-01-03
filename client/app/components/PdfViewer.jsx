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
    PDFJSAnnotate.setStoreAdapter(new PDFJSAnnotate.LocalStoreAdapter());
    PDFJSAnnotate.getStoreAdapter().addAnnotation(
      this.props.file,
      1,
      {
        type: 'area',
        width: 100,
        height: 50,
        x: 75,
        y: 75
      }
    );

    // Loading document.
    PDFJS.getDocument(DEFAULT_URL).then((pdfDocument) => {
      this.RENDER_OPTIONS = {
        documentId: this.props.file,
        pdfDocument: pdfDocument,
        scale: 1,
        rotate: 0
      };
      this.setState({pdfDocument: pdfDocument, isRendered: new Array(pdfDocument.pdfInfo.numPages)});
    });

  }
  componentDidUpdate() {
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
    const { UI } = PDFJSAnnotate;
    

    let { pdfDocument } = this.state;
    if (this.RENDER_OPTIONS) {

      // Create a page in the DOM for every page in the PDF
      let viewer = document.getElementById('viewer');
      viewer.innerHTML = '';
      let numPages = pdfDocument.pdfInfo.numPages;
      for (let i=0; i<numPages; i++) {
        let page = UI.createPage(i+1);
        viewer.appendChild(page);
      }
      //UI.enableEdit();
      UI.enablePoint();

      // Automatically render the first page
      // This assumes that page has already been created and appended
      UI.renderPage(1, this.RENDER_OPTIONS).then(([pdfPage, annotations]) => {
        this.state.isRendered[0] = true;
        // Useful if you need access to annotations or pdfPage.getViewport, etc.
      });
    }

    


    // let { pdfDocument } = this.state;
    // if (pdfDocument) {
    //   var PAGE_TO_VIEW = 1;
    //   var SCALE = 1.0;

    //   for (let i = 0; i < pdfDocument.numPages; i++) {
    //     pdfDocument.getPage(i+1).then((pdfPage) => {
    //       // Creating the page view with default parameters.
    //       var container = document.getElementById('myPageContainer' + i);
    //       var svg = document.getElementById('myPageSvg' + i);

    //       var pdfPageView = new PDFJS.PDFPageView({
    //         container: container,
    //         id: i+1,
    //         scale: SCALE,
    //         defaultViewport: pdfPage.getViewport(SCALE),
    //         // We can enable text/annotations layers, if needed
    //         textLayerFactory: new PDFJS.DefaultTextLayerFactory(),
    //         annotationLayerFactory: new PDFJS.DefaultAnnotationLayerFactory()
    //       });
    //       // Associates the actual page with the view, and drawing it
    //       pdfPageView.setPdfPage(pdfPage);
          
    //       PDFJSAnnotate.render(
    //         svg,
    //         pdfPage.getViewport(SCALE),
    //         PDFJSAnnotate.getStoreAdapter().getAnnotations(this.props.file, i+1));

    //       return pdfPageView.draw();
    //     }).then(function () {

    //     });
    //   }
    // }
    
    
  }

  componentDidMount = () => {
    const { UI } = PDFJSAnnotate;
    // Scroll event to render pages as they come into view
    let scrollWindow = document.getElementById('scrollWindow');
    scrollWindow.addEventListener('scroll', e => {
      Array.prototype.forEach.call(document.getElementsByClassName('page'), (ele, index) => {
        if (!this.state.isRendered[index] &&
            ele.getBoundingClientRect().bottom > -1000 &&
            ele.getBoundingClientRect().top < scrollWindow.clientHeight + 1000) {
          this.state.isRendered[index] = true;
          UI.renderPage(index + 1, this.RENDER_OPTIONS).catch(([pdfPage, annotations]) => {
            this.state.isRendered[index] = false;
          });
        }  
      });
    });
  }
 
  render() {
    // let pageViews = [];
    // if (this.state.pdfDocument) {
    //   for (let i = 0; i < this.state.pdfDocument.numPages; i++) {
    //     pageViews.push(<div key={i}><div key={"myPageContainer"+i} id={"myPageContainer"+i} className="cf-pdf-page pdfViewer singlePageView"></div><svg key={"myPageSvg"+i} id={"myPageSvg"+i} /></div>)
    //   }  
    // }

    return (
      <div id="scrollWindow" className="cf-pdf-container">
        <div id="viewer" className="cf-pdf-page pdfViewer singlePageView"></div>
      </div>
      );
  }
}
 
module.exports = MyPdfViewer;