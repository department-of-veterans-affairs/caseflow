import React from 'react';
import { expect, assert } from 'chai';
import { mount } from 'enzyme';
import DecisionReviewer from '../../app/reader/DecisionReviewer';
import sinon from 'sinon';
import { step } from 'mocha-steps';

import PDFJSAnnotate from 'pdf-annotate.js';
import { PDFJS } from 'pdfjs-dist/web/pdf_viewer.js';

/* eslint-disable no-unused-expressions */
describe.only('DecisionReviewer', () => {
  let pdfId = "pdf";

  // Note, these tests use mount rather than shallow.
  // In order to get that working, we must stub out
  // our endpoints in PDFJS and PDFJSAnnotate.
  // To appraoch reality, our stubbed out versions
  // also add divs representing PDF 'pages' to the dom.

  /* eslint-disable max-statements */
  context('mount and mock out pdfjs', () => {
    let wrapper;
    let pdfjsRenderPage;
    let pdfjsCreatePage;
    let numPages = 3;
    let pdfDocument = { pdfInfo: { numPages } };
    let doc1Name = 'doc1';
    let doc2Name = 'doc2';

    let documents = [
      {
        id: 1,
        filename: doc1Name,
        received_at: '1/2/2017',
        label: 'decisions',
        type: 'bva decision'
      },
      {
        id: 2,
        filename: doc2Name,
        received_at: '3/4/2017',
        label: 'decisions',
        type: 'form 8'
      }
    ];
    let annotations = [];

    beforeEach(() => {
      // We return a pdfInfo object that contains
      // a field numPages.
      let getDocument = sinon.stub(PDFJS, 'getDocument');

      getDocument.resolves(pdfDocument);

      // We return a promise that resolves to an object
      // with a getViewport function.
      pdfjsRenderPage = sinon.stub(PDFJSAnnotate.UI, 'renderPage');
      pdfjsRenderPage.callsFake((arg1, arg2) => {
        console.log(arg1);
        console.log(arg2);
        resolves([
        {
          getViewport: () => 0
        }
      ])});

      // We return fake 'page' divs that the PDF component
      // will add to the dom.
      pdfjsCreatePage = sinon.stub(PDFJSAnnotate.UI, 'createPage');
      pdfjsCreatePage.callsFake((index) => {
        let div = document.createElement("div");

        div.id = `pageContainer${index}`;

        return div;
      });

      wrapper = mount(<DecisionReviewer
        appealDocuments={documents}
        annotations={annotations}
        pdfWorker="worker"
        url="url"
      />, { attachTo: document.getElementById('app') });
    });

    afterEach(() => {
      PDFJS.getDocument.restore();
      PDFJSAnnotate.UI.renderPage.restore();
      PDFJSAnnotate.UI.createPage.restore();
    });

    context('Can enter document from list view', () => {
      step('renders pdf list view', () => {
        expect(wrapper.find('PdfListView')).to.have.length(1);
      });

      step('click into a single pdf', () => {
        wrapper.find('a').findWhere((link) => link.text() === doc1Name).simulate('mouseUp');
        //console.log(wrapper.debug());

        expect(wrapper.find('PdfViewer')).to.have.length(1);
      });
    });

    context('Zoom document', () => {
      step('zoom in and out', () => {
        wrapper.find('a').findWhere((link) => {return link.text() === doc1Name}).simulate('mouseUp');

        ///pdfjsRenderPage.resetHistory();
        console.log('before');
        wrapper.find('#button-zoomIn').simulate('click');
        expect(pdfjsRenderPage.called).to.be.true;
        //expect(pdfjsRenderPage.alwaysCalledWith(sinon.match.number, sinon.match.object)).to.be.true;
        //pdfjsRenderPage.resetHistory();
        //wrapper.find('#button-zoomOut').simulate('click');
        //expect(pdfjsRenderPage.alwaysCalledWith(sinon.match.number, sinon.match.has('scale', 1))).to.be.true;
      });
    });
  });
  /* eslint-enable max-statements */
});
/* eslint-enable no-unused-expressions */
