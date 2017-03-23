import React from 'react';
import { expect } from 'chai';
import { mount } from 'enzyme';
import Pdf from '../../app/components/Pdf';
import sinon from 'sinon';

import PDFJSAnnotate from 'pdf-annotate.js';
import { PDFJS } from 'pdfjs-dist/web/pdf_viewer.js';

describe('Pdf', () => {

  // Note, these tests use mount rather than shallow
  // in order to get that working, we must mock out
  // our endpoints in PDFJS and PDFJSAnnotate.
  // Unfortunately PDFJS has to add to the DOM outside
  // of our normal React flow. Enzyme only tracks
  // elements that are added within this flow.
  // This means if you want to reference any
  // elements created by our mock'd PDFJS you
  // will have to use document.getElement(s)By...
  context('mount and mock out pdfjs', () => {
    let wrapper;
    let mock;
    let renderPage;
    let createPage;

    let numPages = 3;
    let pdfId = "pdf";

    let stubCreatePage = (index) => {
      let pageDiv = document.createElement("div");
      let divId = `pageContainer${index}`;

      pageDiv.id = divId;
      pageDiv.className = 'page';
      pageDiv.style.width = '400px';
      pageDiv.style.height = '400px';
      return pageDiv;
    }

    let stubRenderPage = (index, RENDER_OPTIONS) => {
      let divId = `pageContainer${index}`;
      let pageContent = document.createTextNode(divId);
      let pageDiv = document.getElementById(divId);
      
      pageDiv.appendChild(pageContent);

      return new Promise((resolve, reject) =>
        {
          resolve([{ getViewport: () => { return 0; } }]);
        });
    }

    beforeEach(() => {
      let getDocument = sinon.stub(PDFJS, 'getDocument');
      getDocument.resolves({ pdfInfo: { numPages } });

      renderPage = sinon.stub(PDFJSAnnotate.UI, 'renderPage', stubRenderPage);
      createPage = sinon.stub(PDFJSAnnotate.UI, 'createPage', stubCreatePage);

      wrapper = mount(<Pdf
        documentId={1}
        file="test.pdf"
        id={pdfId}
        pdfWorker="noworker"
        scale={1}
      />, { attachTo: document.getElementById('app') });
    });

    afterEach(() => {
      PDFJS.getDocument.restore();
      PDFJSAnnotate.UI.renderPage.restore();
      PDFJSAnnotate.UI.createPage.restore();
    });

    context.only('.mount', () => {
      it(`creates ${numPages} pages`, () => {
        expect(wrapper.find('#scrollWindow')).to.have.length(1);
        expect(createPage.callCount).to.equal(3);
        expect(renderPage.callCount).to.equal(1);

        // expect(document.getElementById('pageContainer1').innerHTML).to.equal('pageContainer1');
        // expect(document.getElementsByClassName('page')).to.have.length(numPages);
      });

      it(`only renders the first page`, () => {
        expect(document.getElementById('pageContainer1').innerHTML).to.equal('pageContainer1');
        expect(document.getElementById('pageContainer2').innerHTML).to.equal('');
      });    
    });

    context('.renderPage', () => {
      it('creates a new page', () => {
        expect(document.getElementById('pageContainer2').innerHTML).to.equal('');
        wrapper.getNode().renderPage(1);
        expect(document.getElementById('pageContainer2').innerHTML).to.equal('pageContainer2');
      });

      it('marks page as rendered', () => {
        expect(wrapper.getNode().isRendered[1]).to.be.undefined;
        wrapper.getNode().renderPage(1);
        expect(wrapper.getNode().isRendered[1]).to.be.true;
      });

      context('mock renderPage to fail', () => {
        it('receives render', () => {
          expect(wrapper.getNode().isRendered[1]).to.be.undefined;
          wrapper.getNode().renderPage(1);
          expect(wrapper.getNode().isRendered[1]).to.be.true;
        });
      });
    });
  });
});
