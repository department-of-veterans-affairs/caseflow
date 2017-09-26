import sinon from 'sinon';
import { PDFJS } from 'pdfjs-dist/web/pdf_viewer.js';

const numPages = 3;
const PAGE_WIDTH = 100;
const PAGE_HEIGHT = 100;

export default {
  numPages,
  pdfDocument: {
    pdfInfo: {
      numPages
    },
    getPage: sinon.stub().resolves({
      getViewport: () => ({ width: PAGE_WIDTH,
        height: PAGE_HEIGHT }),
      transport: {
        destroyed: false
      }
    }),
    destroy: sinon.stub(),
    transport: {
      destroyed: false
    }
  },

  beforeEach() {
    // We return a pdfInfo object that contains
    // a field numPages.
    let getDocument = sinon.stub(PDFJS, 'getDocument');

    getDocument.resolves(this.pdfDocument);
  },

  afterEach() {
    PDFJS.getDocument.restore();
  }
};
