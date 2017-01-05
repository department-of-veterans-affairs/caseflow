import React from 'react';
import { PDFJS } from 'pdfjs-dist/web/pdf_viewer.js';
import PDFJSAnnotate from 'pdf-annotate.js';
 
let annotationArray = [];

let MyStoreAdapter = new PDFJSAnnotate.StoreAdapter({
  getAnnotations(documentId, pageNumber) {/* ... */},

  getAnnotation(documentId, annotationId) {/* ... */},

  addAnnotation(documentId, pageNumber, annotation) {
    console.log(annotation);
    annotationArray.push(annotation);
  },

  editAnnotation(documentId, pageNumber, annotation) {/* ... */},

  deleteAnnotation(documentId, annotationId) {/* ... */},

  addComment(documentId, annotationId, content) {/* ... */},

  deleteComment(documentId, commentId) {/* ... */}
});

class MyPdfViewer extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      comments: []
    };
    PDFJS.disableWorker = true;
    //PDFJSAnnotate.setStoreAdapter(MyStoreAdapter);
    
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
      return;

    


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

  generateComments = (pdfDocument) => {
    this.comments = [];
    this.setState({comments: this.comments});
    for (let i = 0; i < pdfDocument.pdfInfo.numPages; i++) {
      PDFJSAnnotate.getStoreAdapter().getAnnotations(this.props.file, i).then((annotations) => {
        annotations.annotations.forEach((annotationId) => {
          PDFJSAnnotate.getStoreAdapter().getComments(this.props.file, annotationId.uuid).then((comment) => {
            if (comment.length > 0) {
              this.comments = [...this.comments, {uuid: annotationId.uuid, content: comment[0].content}];
              this.setState({comments: this.comments});
            }
          });
        });
      });
    }
  }

  draw = () => {
    const { UI } = PDFJSAnnotate;
    
    PDFJS.getDocument(this.props.file).then((pdfDocument) => {
      this.RENDER_OPTIONS = {
        documentId: this.props.file,
        pdfDocument: pdfDocument,
        scale: 1,
        rotate: 0
      };
      this.generateComments(pdfDocument);

      this.isRendered = new Array(pdfDocument.pdfInfo.numPages);

      // Create a page in the DOM for every page in the PDF
      let viewer = document.getElementById('viewer');
      viewer.innerHTML = '';
      let numPages = pdfDocument.pdfInfo.numPages;
      for (let i=0; i<numPages; i++) {
        let page = UI.createPage(i+1);
        viewer.appendChild(page);
      }
      //UI.enableEdit();
      
      if (this.annotationAddListener) {
        UI.removeEventListener('annotation:add', this.annotationAddListener);  
      }
      
      this.annotationAddListener = (e) => {this.generateComments(pdfDocument)};
      UI.addEventListener('annotation:add', this.annotationAddListener);

      

      // Automatically render the first page
      // This assumes that page has already been created and appended
      UI.renderPage(1, this.RENDER_OPTIONS).then(([pdfPage, annotations]) => {
        this.isRendered[0] = true;
        // Useful if you need access to annotations or pdfPage.getViewport, etc.
      }); 
    });
  }

  componentDidUpdate(oldProps) {
    if (oldProps.file !== this.props.file) {
      document.getElementById('scrollWindow').scrollTop = 0;
      this.draw();

    }
  }

  componentDidMount = () => {

    const { UI } = PDFJSAnnotate;

    UI.addEventListener('annotation:click', (e) => {
      // console.log('this is an event');
      // console.log(e);
      // console.log(e.getAttribute('data-pdf-annotate-id'));
      // PDFJSAnnotate.getStoreAdapter().getAnnotation(this.props.file, e.getAttribute('data-pdf-annotate-id')).then((annotation) => {
      //   console.log(annotation);
      // })
      //PDFJSAnnotate.getStoreAdapter().getComments(this.props.file, e.getAttribute('data-pdf-annotate-id')).then((comment) => {
      //})
      let comments = [ ...this.state.comments ];
      comments = comments.map((comment) => {
        let copy = { ...comment };
        copy.selected = false;
        if (comment.uuid === e.getAttribute('data-pdf-annotate-id')) {
          copy.selected = true;
        }
        return copy;
      });
      this.setState({comments: comments});
      
    });

    this.draw();


    // Scroll event to render pages as they come into view
    let scrollWindow = document.getElementById('scrollWindow');
    scrollWindow.addEventListener('scroll', e => {
      Array.prototype.forEach.call(document.getElementsByClassName('page'), (ele, index) => {
        if (!this.isRendered[index] &&
            ele.getBoundingClientRect().bottom > -1000 &&
            ele.getBoundingClientRect().top < scrollWindow.clientHeight + 1000) {
          this.isRendered[index] = true;
          UI.renderPage(index + 1, this.RENDER_OPTIONS).catch(([pdfPage, annotations]) => {
            this.isRendered[index] = false;
          });
        }  
      });
    });



    window.addEventListener('keyup', function(e) {
      console.log(e);
      if (e.key == 'n') {
        UI.enablePoint();
        UI.disableEdit();
      }
      if (e.key == 'm') {
        UI.disablePoint();
        UI.enableEdit();
      }
    })
  }

  jumpToComment = (uuid) => {
    return ((e) => {
      PDFJSAnnotate.getStoreAdapter().getAnnotation(this.props.file, uuid).then((annotation) => {
        console.log(annotation);
        console.log(document.getElementsByClassName('page')[annotation.page - 1].getBoundingClientRect());
        console.log(document.getElementById('scrollWindow').scrollTop);
        document.getElementById('scrollWindow').scrollTop = document.getElementsByClassName('page')[annotation.page - 1].getBoundingClientRect().top + annotation.y - 100 + document.getElementById('scrollWindow').scrollTop;
      });
    });
  }
 
  render() {
    let comments = [];
    console.log(this.state.comments);
    this.state.comments.forEach((comment) => {
      comments.push(<div onClick={this.jumpToComment(comment.uuid)} className={"comment-list-item" + (comment.selected ? " cf-comment-selected" : "")}>{comment.content}</div>)
    });

    return (
      <div>
        <div id="scrollWindow" className="cf-pdf-container">
          <div id="viewer" className="cf-pdf-page pdfViewer singlePageView"></div>
        </div>
        <div id="cf-comment-wrapper">
          <h4>Comments</h4>
          <div className="comment-list">
            <div className="comment-list-container">
              {comments}
            </div>
            <form className="comment-list-form" style={{display: 'none'}}>
              <input type="text" placeholder="Add a Comment"/>
            </form>
          </div>
        </div>
      </div>
      );
  }
}
 
module.exports = MyPdfViewer;