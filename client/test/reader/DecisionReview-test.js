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
    let apiPatch;
    let apiPost;
    let apiGet;
    let apiDelete;
    let numPages = 3;
    let pdfDocument = { pdfInfo: { numPages } };
    let doc1Name = 'doc1';
    let doc1Id = 1;
    let doc2Name = 'doc2';
    let doc2Id = 2;

    let date1 = '01/02/2017';
    let date2 = '03/04/2017';

    let type1 = 'bva decision';
    let type2 = 'form 9';

    let existingComment = 'Test comment';
    let existingCommentId = 2;
    let documents = [
      {
        id: 1,
        filename: doc1Name,
        received_at: date1,
        label: null,
        type: type1
      },
      {
        id: 2,
        filename: doc2Name,
        received_at: date2,
        label: null,
        type: type2
      }
    ];
    let annotations = [{
        class: 'Annotation',
        page: 1,
        type: 'point',
        x: 50,
        y: 60,
        comment: existingComment,
        document_id: 2,
        id: existingCommentId
      }];

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

      apiPatch = sinon.stub(ApiUtil, 'patch');
      apiPatch.resolves();

      apiGet = sinon.stub(ApiUtil, 'get');
      apiGet.resolves();

      apiPost = sinon.stub(ApiUtil, 'post');
      apiPost.resolves();

      apiDelete = sinon.stub(ApiUtil, 'delete');
      apiDelete.resolves();

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
      ApiUtil.delete.restore();
    });

    context('Can toggle between list and document views', () => {
      it('renders pdf list view', () => {
        expect(wrapper.find('PdfListView')).to.have.length(1);
      });

      it('click into a single pdf', () => {
        wrapper.find('a').findWhere((link) => link.text() === doc1Name).simulate('mouseUp');

        expect(wrapper.find('PdfViewer')).to.have.length(1);

        wrapper.find('#button-backToDocuments').simulate('click');
        expect(wrapper.find('PdfListView')).to.have.length(1);
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

      apiPatch.resetHistory();
      wrapper.find('.cf-pdf-bookmark-decisions').simulate('click');
      await pause();

      expect(apiPatch.calledWith(`/document/${doc1Id}/set-label`, sinon.match({ data: { label: 'decisions' } }))).to.be.true;

      apiPatch.resetHistory();
      wrapper.find('.cf-pdf-bookmark-procedural').simulate('click');
      await pause();

      expect(apiPatch.calledWith(`/document/${doc1Id}/set-label`, sinon.match({ data: { label: 'procedural' } }))).to.be.true;


      apiPatch.resetHistory();
      wrapper.find('.cf-pdf-bookmark-procedural').simulate('click');
      await pause();

      expect(apiPatch.calledWith(`/document/${doc1Id}/set-label`, sinon.match({ data: { label: null } }))).to.be.true;
    }));

    it('Add and delete a comment', asyncTest(async() => {
      let event = {
        offsetX: 10,
        offsetY: 10,
        target: {
          offsetLeft: 20,
          offsetTop: 30
        }
      };

      let firstComment = 'hello';
      let secondComment = 'hello world';
      let commentId = 1;

      let firstAnnotation = {
        class: 'Annotation',
        page: 1,
        type: 'point',
        x: 30,
        y: 40,
        comment: firstComment,
        document_id: 1
      };

      let secondAnnotation = {
        class: 'Annotation',
        page: 1,
        type: 'point',
        x: 30,
        y: 40,
        comment: secondComment,
        document_id: 1,
        uuid: 1
      };

      apiPost.resolves({text: `{ "id": ${commentId} }`});

      // Click on first pdf
      wrapper.find('a').findWhere((link) => link.text() === doc1Name).simulate('mouseUp');
      await pause();

      wrapper.find('a').findWhere((link) => link.text() === '+ Add a Comment').simulate('click');
      wrapper.find('Pdf').getNode().onPageClick(1)(event);

      wrapper.find('#addComment').simulate('change', { target: { value: firstComment } });

      wrapper.find('#button-save').simulate('click');
      await pause();

      expect(apiPost.calledWith('/decision/review/annotation', sinon.match({ data: { annotation: firstAnnotation } }))).to.be.true;
      await pause();

      //console.log(wrapper.debug());
      wrapper.find('#button-edit').simulate('click');
      expect(wrapper.find('TextareaField').props().value).to.be.equal(firstComment);

      wrapper.find('#editCommentBox').simulate('change', { target: { value: secondComment } });
      wrapper.find('#button-save').simulate('click');
      await pause();

      expect(apiPatch.calledWith(`/decision/review/annotation/${commentId}`, sinon.match({ data: { annotation: secondAnnotation } }))).to.be.true;
      await pause();

      wrapper.find('#button-delete').simulate('click');
      
      await pause();
      expect(apiDelete.calledWith(`/decision/review/annotation/${commentId}`)).to.be.true;
    }));

    it('Clicking on comment jumps to icon', asyncTest(async()  => {
      let event = {
        offsetX: 10,
        offsetY: 10,
        target: {
          offsetLeft: 20,
          offsetTop: 30
        }
      };

      let firstComment = 'hello';
      let commentId = 1;

      apiPost.resolves({text: `{ "id": ${commentId} }`});

      wrapper.find('a').findWhere((link) => link.text() === doc1Name).simulate('mouseUp');
      let pdfViewer = wrapper.find('PdfViewer').getNode();
      let jumpTo = sinon.spy(pdfViewer, 'onJumpToComment');

      wrapper.find('a').findWhere((link) => link.text() === '+ Add a Comment').simulate('click');
      wrapper.find('Pdf').getNode().onPageClick(1)(event);

      wrapper.find('#addComment').simulate('change', { target: { value: firstComment } });

      wrapper.find('#button-save').simulate('click');
      await pause();

      wrapper.find('#comment0').simulate('click');
      expect(jumpTo.calledWith(commentId)).to.be.true;
    }));

    context('PDF list view', () => {
      it('Sorting by date orders correctly', () => {
        expect(wrapper.find('#receipt-date-header').find('i').hasClass('fa-caret-down')).to.be.true;

        let textArray = wrapper.find('tr').map(node => node.text());
        expect(textArray[1]).to.include(date1);
        expect(textArray[2]).to.include(date2);

        wrapper.find('#receipt-date-header').simulate('click');
        expect(wrapper.find('#receipt-date-header').find('i').hasClass('fa-caret-up')).to.be.true;

        textArray = wrapper.find('tr').map(node => node.text());
        expect(textArray[1]).to.include(date2);
        expect(textArray[2]).to.include(date1);
      });

      it('Sorting by type orders correctly', () => {
        wrapper.find('#type-header').simulate('click');
        expect(wrapper.find('#type-header').find('i').hasClass('fa-caret-down')).to.be.true;

        let textArray = wrapper.find('tr').map(node => node.text());
        expect(textArray[1]).to.include(type1);
        expect(textArray[2]).to.include(type2);

        wrapper.find('#type-header').simulate('click');
        expect(wrapper.find('#type-header').find('i').hasClass('fa-caret-up')).to.be.true;

        textArray = wrapper.find('tr').map(node => node.text());
        expect(textArray[1]).to.include(type2);
        expect(textArray[2]).to.include(type1);
      });

      it('Searching by date filters properly', () => {
        wrapper.find('input').simulate('change', { target: { value: date2 } });

        let textArray = wrapper.find('tr').map(node => node.text());

        // Header and one filtered row.
        expect(textArray).to.have.length(2);
        expect(textArray[1]).to.include(date2);
        
        wrapper.find('input').simulate('change', { target: { value: '' } });
        textArray = wrapper.find('tr').map(node => node.text());
        expect(textArray).to.have.length(3);
      });

      it('Searching by type filters properly', () => {
        wrapper.find('input').simulate('change', { target: { value: type2 } });

        let textArray = wrapper.find('tr').map(node => node.text());

        // Header and one filtered row.
        expect(textArray).to.have.length(2);
        expect(textArray[1]).to.include(type2);
        
        wrapper.find('input').simulate('change', { target: { value: '' } });
        textArray = wrapper.find('tr').map(node => node.text());
        expect(textArray).to.have.length(3);
      });

      it('Searching by comment filters properly', () => {
        wrapper.find('input').simulate('change', { target: { value: existingComment } });

        let textArray = wrapper.find('tr').map(node => node.text());

        // Header and one filtered row.
        expect(textArray).to.have.length(2);

        // Should only display the second document
        expect(textArray[1]).to.include(type2);
        
        wrapper.find('input').simulate('change', { target: { value: '' } });
        textArray = wrapper.find('tr').map(node => node.text());
        expect(textArray).to.have.length(3);
      });

      it('Entering pdf when filtered to one, removes navigation arrows', () => {
        wrapper.find('input').simulate('change', { target: { value: existingComment } });

        wrapper.find('a').findWhere((link) => link.text() === doc2Name).simulate('mouseUp');
        expect(wrapper.find('#button-next')).to.have.length(0);
        expect(wrapper.find('#button-previous')).to.have.length(0);
      });
    });
  });
  /* eslint-enable max-statements */
});
/* eslint-enable no-unused-expressions */
