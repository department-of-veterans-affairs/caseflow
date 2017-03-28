import React from 'react';
import { expect, assert } from 'chai';
import { mount } from 'enzyme';
import DecisionReviewer from '../../app/reader/DecisionReviewer';
import sinon from 'sinon';
import { eventually } from 'chai-as-promised';

import PDFJSAnnotate from 'pdf-annotate.js';
import { PDFJS } from 'pdfjs-dist/web/pdf_viewer.js';
import ApiUtil from '../../app/util/ApiUtil';

let asyncTest = (fn) => {
  return () => {
    return new Promise(async (resolve, reject) => {
      try {
        await fn();
        resolve();
      } catch (err) {
        reject(err);
      }
    });
  };
}

let pause = (ms = 0) => {
  return new Promise((resolve) => {
    setTimeout(() => {
      return resolve();
    }, ms);
  });
}

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
    let patch;
    let post;
    let get;
    let numPages = 3;
    let pdfDocument = { pdfInfo: { numPages } };
    let doc1Name = 'doc1';
    let doc1Id = 1;
    let doc2Name = 'doc2';
    let doc2Id = 2;

    let documents = [
      {
        id: 1,
        filename: doc1Name,
        received_at: '1/2/2017',
        label: null,
        type: 'bva decision'
      },
      {
        id: 2,
        filename: doc2Name,
        received_at: '3/4/2017',
        label: null,
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
      pdfjsRenderPage.resolves([{ getViewport: () => 0 }]);

      // We return fake 'page' divs that the PDF component
      // will add to the dom.
      pdfjsCreatePage = sinon.stub(PDFJSAnnotate.UI, 'createPage');
      pdfjsCreatePage.callsFake((index) => {
        let div = document.createElement("div");

        div.id = `pageContainer${index}`;

        return div;
      });

      patch = sinon.stub(ApiUtil, 'patch');
      patch.resolves();

      get = sinon.stub(ApiUtil, 'get');
      get.resolves();

      post = sinon.stub(ApiUtil, 'post');
      post.resolves();

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
      ApiUtil.patch.restore();
      ApiUtil.post.restore();
      ApiUtil.get.restore();
    });

    context('Can enter document from list view', () => {
      it('renders pdf list view', () => {
        expect(wrapper.find('PdfListView')).to.have.length(1);
      });

      it('click into a single pdf', () => {
        wrapper.find('a').findWhere((link) => link.text() === doc1Name).simulate('mouseUp');
        //console.log(wrapper.debug());

        expect(wrapper.find('PdfViewer')).to.have.length(1);
      });
    });

    context('Zooming calls pdfjs to rerender with the correct scale', () => {
      it('zoom in and zoom out', asyncTest(async () => {
        wrapper.find('a').findWhere((link) => link.text() === doc1Name).simulate('mouseUp');
        pdfjsRenderPage.resetHistory();
        wrapper.find('#button-zoomIn').simulate('click');
        await pause();
        expect(pdfjsRenderPage.calledWith(sinon.match.number, sinon.match({ scale: 1.3 }))).to.be.true;
        
        pdfjsRenderPage.resetHistory();
        wrapper.find('#button-zoomOut').simulate('click');
        await pause();

        expect(pdfjsRenderPage.alwaysCalledWith(sinon.match.number, sinon.match({ scale: 1 }))).to.be.true;
      }));
    });

    context('Navigation buttons move between PDFs', () => {
      it('next button moves to the next PDF previous button moves back', asyncTest(async() => {
        wrapper.find('a').findWhere((link) => link.text() === doc1Name).simulate('mouseUp');
        await pause();

        expect(pdfjsRenderPage.alwaysCalledWith(sinon.match.number, sinon.match({ documentId: doc1Id }))).to.be.true;

        pdfjsRenderPage.resetHistory();
        wrapper.find('#button-next').simulate('click');
        await pause();

        expect(pdfjsRenderPage.alwaysCalledWith(sinon.match.number, sinon.match({ documentId: doc2Id }))).to.be.true;

        pdfjsRenderPage.resetHistory();
        wrapper.find('#button-previous').simulate('click');
        await pause();

        expect(pdfjsRenderPage.alwaysCalledWith(sinon.match.number, sinon.match({ documentId: doc1Id }))).to.be.true;
      }));
    });

    it('Clicking label buttons send labels to the server', asyncTest(async() => {
      wrapper.find('a').findWhere((link) => link.text() === doc1Name).simulate('mouseUp');

      patch.resetHistory();
      wrapper.find('.cf-pdf-bookmark-decisions').simulate('click');
      await pause();

      expect(patch.calledWith(`/document/${doc1Id}/set-label`, sinon.match({ data: { label: 'decisions' } }))).to.be.true;

      patch.resetHistory();
      wrapper.find('.cf-pdf-bookmark-procedural').simulate('click');
      await pause();

      expect(patch.calledWith(`/document/${doc1Id}/set-label`, sinon.match({ data: { label: 'procedural' } }))).to.be.true;


      patch.resetHistory();
      wrapper.find('.cf-pdf-bookmark-procedural').simulate('click');
      await pause();

      expect(patch.calledWith(`/document/${doc1Id}/set-label`, sinon.match({ data: { label: null } }))).to.be.true;
    }));

    it('Adding comments', asyncTest(async() => {
      // Click on first pdf
      wrapper.find('a').findWhere((link) => link.text() === doc1Name).simulate('mouseUp');
      await pause();

      wrapper.find('a').findWhere((link) => link.text() === '+ Add a Comment').simulate('click');
      wrapper.find('Pdf').instance().
    }));
  });
  /* eslint-enable max-statements */
});
/* eslint-enable no-unused-expressions */
