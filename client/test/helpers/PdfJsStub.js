import sinon from 'sinon';

import PDFJSAnnotate from 'pdf-annotate.js';
import { PDFJS } from 'pdfjs-dist/web/pdf_viewer.js';

let numPages = 3;

export default {
  pdfjsRenderPage: null,
  pdfjsCreatePage: null,
  numPages,
  pdfDocument: { pdfInfo: { numPages } },

  beforeEach() {
    // We return a pdfInfo object that contains
    // a field numPages.
    let getDocument = sinon.stub(PDFJS, 'getDocument');

    getDocument.resolves(this.pdfDocument);

    // We return a promise that resolves to an object
    // with a getViewport function.
    this.pdfjsRenderPage = sinon.stub(PDFJSAnnotate.UI, 'renderPage');
    this.pdfjsRenderPage.resolves([{ getViewport: () => 0 }]);

    // We return fake 'page' divs that the PDF component
    // will add to the dom.
    this.pdfjsCreatePage = sinon.stub(PDFJSAnnotate.UI, 'createPage');
    this.pdfjsCreatePage.callsFake((index) => {
      let outterDiv = document.createElement("div");
      let innerDiv = document.createElement("div");

      outterDiv.id = `pageContainer${index}`;
      innerDiv.className = 'page';

      outterDiv.appendChild(innerDiv);

      return outterDiv;
    });
  },

  afterEach() {
    PDFJS.getDocument.restore();
    PDFJSAnnotate.UI.renderPage.restore();
    PDFJSAnnotate.UI.createPage.restore();
  }
};
