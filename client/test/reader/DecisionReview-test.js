import React from 'react';
import { expect } from 'chai';
import { mount } from 'enzyme';
import DecisionReviewer from '../../app/reader/DecisionReviewer';
import sinon from 'sinon';
import { documents } from '../data/documents';
import { annotations } from '../data/annotations';

import { asyncTest, pause } from '../helpers/AsyncTests';
import ApiUtilStub from '../helpers/ApiUtilStub';

import PdfJsStub from '../helpers/PdfJsStub';

/* eslint-disable camelcase */
/* eslint-disable no-unused-expressions */
/* eslint-disable max-statements */
describe('DecisionReviewer', () => {
  let wrapper;

  beforeEach(() => {
    PdfJsStub.beforeEach();
    ApiUtilStub.beforeEach();

    wrapper = mount(<DecisionReviewer
      appealDocuments={documents}
      annotations={annotations}
      pdfWorker="worker"
      url="url"
    />, { attachTo: document.getElementById('app') });
  });

  afterEach(() => {
    wrapper.detach();
    ApiUtilStub.afterEach();
    PdfJsStub.afterEach();
  });

  context('PDF View', () => {
    context('renders', () => {
      it('the PDF list view', () => {
        expect(wrapper.find('PdfListView')).to.have.length(1);
      });

      it('the PDF view when a PDF is clicked', asyncTest(async () => {
        // Click on first document link
        wrapper.find('a').findWhere(
          (link) => link.text() === documents[0].type).
          simulate('mouseUp');
        await pause();

        expect(wrapper.find('PdfViewer')).to.have.length(1);

        // Return to document list view
        wrapper.find('#button-backToDocuments').simulate('click');
        expect(wrapper.find('PdfListView')).to.have.length(1);
      }));
    });

    context('zooming buttons', () => {
      it('render pdf at different scales', asyncTest(async () => {
        // Click on first document link
        wrapper.find('a').findWhere(
          (link) => link.text() === documents[0].type).
          simulate('mouseUp');

        // Verify when we click zoom in, we render the PDF zoomed in
        wrapper.find('#button-zoomIn').simulate('click');
        await pause();
        expect(PdfJsStub.pdfjsRenderPage.lastCall.calledWith(sinon.match.number,
          sinon.match({ scale: 1.3 }))).to.be.true;

        // Verify when we click zoom out, we render the PDF zoomed out
        wrapper.find('#button-zoomOut').simulate('click');
        await pause();

        expect(PdfJsStub.pdfjsRenderPage.lastCall.calledWith(sinon.match.number,
          sinon.match({ scale: 1 }))).to.be.true;
      }));
    });

    context('navigation buttons', () => {
      it('move to the next and previous pdfs', asyncTest(async() => {
        // Click on first document link
        wrapper.find('a').findWhere(
          (link) => link.text() === documents[0].type).
          simulate('mouseUp');
        await pause();

        expect(PdfJsStub.pdfjsRenderPage.alwaysCalledWith(sinon.match.number,
          sinon.match({ documentId: documents[0].id }))).to.be.true;

        // Next button moves us to the next page
        wrapper.find('#button-next').simulate('click');
        await pause();

        expect(PdfJsStub.pdfjsRenderPage.lastCall.calledWith(sinon.match.number,
          sinon.match({ documentId: documents[1].id }))).to.be.true;

        // Previous button moves us to the previous page
        wrapper.find('#button-previous').simulate('click');
        await pause();

        expect(PdfJsStub.pdfjsRenderPage.lastCall.calledWith(sinon.match.number,
          sinon.match({ documentId: documents[0].id }))).to.be.true;
      }));

      it('are hidden when there is no next or previous pdf', () => {
        // Filter documents on the second document's comment
        wrapper.find('input').simulate('change',
          { target: { value: annotations[0].comment } });

        // Enter the pdf view
        wrapper.find('a').findWhere(
          (link) => link.text() === documents[1].type).
          simulate('mouseUp');

        // Verify the arrow navigations keys are not present
        expect(wrapper.find('#button-next')).to.have.length(0);
        expect(wrapper.find('#button-previous')).to.have.length(0);

        // Verify there is still has a back to documents button
        expect(wrapper.find('#button-backToDocuments')).to.have.length(1);
      });
    });

    context('labels', () => {
      it('send the correct data when clicked and highlights the right label',
        asyncTest(async() => {
          // Enter the pdf view
          wrapper.find('a').findWhere(
            (link) => link.text() === documents[0].type).
            simulate('mouseUp');

          // Click on the decision label
          wrapper.find('.cf-pdf-bookmark-decisions').simulate('click');
          await pause();

          // Verify the decisions label is selected, and that we send an api request
          expect(wrapper.find('.cf-pdf-bookmark-decisions').
            parent().
            hasClass('cf-selected-label')).to.be.true;
          expect(ApiUtilStub.apiPatch.lastCall.
            calledWith(`/document/${documents[0].id}/set-label`,
            sinon.match({ data: { label: 'decisions' } }))).to.be.true;

          // Click on a different label
          wrapper.find('.cf-pdf-bookmark-procedural').simulate('click');
          await pause();

          // Verify the procedural label is selected, and that we send an api request
          expect(wrapper.find('.cf-pdf-bookmark-procedural').
            parent().
            hasClass('cf-selected-label')).to.be.true;
          expect(ApiUtilStub.apiPatch.lastCall.
            calledWith(`/document/${documents[0].id}/set-label`,
            sinon.match({ data: { label: 'procedural' } }))).to.be.true;

          // Click on the same label
          wrapper.find('.cf-pdf-bookmark-procedural').simulate('click');
          await pause();

          // Verify the procedural label is not selected,
          // and that we send an api request to deselect
          expect(wrapper.find('.cf-pdf-bookmark-procedural').
            parent().
            hasClass('cf-selected-label')).to.be.false;
          expect(ApiUtilStub.apiPatch.lastCall.
            calledWith(`/document/${documents[0].id}/set-label`,
            sinon.match({ data: { label: null } }))).to.be.true;
        }));
    });

    context('comments', () => {
      let event = {
        offsetX: 10,
        offsetY: 10,
        target: {
          offsetLeft: 20,
          offsetTop: 30
        }
      };

      it('can be added, edited, and deleted', asyncTest(async() => {
        let commentId = 1;
        let firstComment = {
          class: 'Annotation',
          page: 1,
          type: 'point',
          x: 30,
          y: 40,
          comment: 'hello',
          document_id: 1
        };
        let secondComment = {
          class: 'Annotation',
          page: 1,
          type: 'point',
          x: 30,
          y: 40,
          comment: 'hello world',
          document_id: 1,
          uuid: commentId
        };

        // Stub out post requests to return the commentId
        ApiUtilStub.apiPost.resolves({ text: `{ "id": ${commentId} }` });

        // Click on first pdf
        wrapper.find('a').findWhere(
          (link) => link.text() === documents[0].type).
          simulate('mouseUp');
        await pause();

        // Click on the add a comment button
        wrapper.find('a').findWhere(
          (link) => link.text() === '+ Add a Comment').
          simulate('click');

        // Click on the pdf at the location specified by event
        wrapper.find('Pdf').getNode().
          onPageClick(1)(event);

        // Add text to the comment text box.
        wrapper.find('#addComment').simulate('change',
          { target: { value: firstComment.comment } });

        // Click on save
        wrapper.find('#button-save').simulate('click');
        await pause();

        // Verify the api is called to add a comment
        expect(ApiUtilStub.apiPost.calledWith('/decision/review/annotation',
          sinon.match({ data: { annotation: firstComment } }))).to.be.true;
        await pause();

        // Click on the edit button
        wrapper.find('#button-edit').simulate('click');

        // Verify that the text in the textbox is the existing comment
        expect(wrapper.find('TextareaField').props().value).
          to.be.equal(firstComment.comment);

        // Add new text to the edit textbox
        wrapper.find('#editCommentBox').simulate('change',
          { target: { value: secondComment.comment } });

        // Save the edit
        wrapper.find('#button-save').simulate('click');
        await pause();

        // Verify the api is called to edit a comment
        expect(ApiUtilStub.apiPatch.calledWith(`/decision/review/annotation/${commentId}`,
          sinon.match({ data: { annotation: secondComment } }))).to.be.true;

        // Click on the delete button
        wrapper.find('#button-delete').simulate('click');
        await pause();

        // Verify the api is called to delete a comment
        expect(ApiUtilStub.apiDelete.
          calledWith(`/decision/review/annotation/${commentId}`)).
          to.be.true;
      }));

      it('can be clicked on to jump to icon', asyncTest(async() => {
        let commentId = 1;

        ApiUtilStub.apiPost.resolves({ text: `{ "id": ${commentId} }` });

        wrapper.find('a').findWhere(
          (link) => link.text() === documents[0].type).
          simulate('mouseUp');
        let pdfViewer = wrapper.find('PdfViewer').getNode();
        let jumpTo = sinon.spy(pdfViewer, 'onJumpToComment');

        wrapper.find('a').findWhere(
          (link) => link.text() === '+ Add a Comment').
          simulate('click');
        wrapper.find('Pdf').getNode().
          onPageClick(1)(event);

        wrapper.find('#addComment').simulate('change', { target: { value: 'hello' } });

        wrapper.find('#button-save').simulate('click');
        await pause();

        wrapper.find('#comment0').simulate('click');
        expect(jumpTo.calledWith(commentId)).to.be.true;
      }));

      it('highlighted by clicking on the icon', asyncTest(async() => {
        wrapper.find('a').findWhere(
          (link) => link.text() === documents[1].type).
          simulate('mouseUp');

        let clickedOnCommentEvent = {
          getAttribute: () => {
            return annotations[0].id;
          }
        };

        wrapper.find('Pdf').getNode().
          onCommentClick(clickedOnCommentEvent);
        expect(wrapper.find('#comment0').hasClass('comment-container-selected')).
          to.be.true;
      }));
    });
  });

  context('PDF list view', () => {
    context('when sorted by', () => {
      it('date is ordered correctly', () => {
        expect(wrapper.find('#receipt-date-header').
          find('i').
          hasClass('fa-caret-down')).to.be.true;

        let textArray = wrapper.find('tr').map((node) => node.text());

        expect(textArray[1]).to.include(documents[0].received_at);
        expect(textArray[2]).to.include(documents[1].received_at);

        wrapper.find('#receipt-date-header').simulate('click');
        expect(wrapper.find('#receipt-date-header').
          find('i').
          hasClass('fa-caret-up')).to.be.true;

        textArray = wrapper.find('tr').map((node) => node.text());
        expect(textArray[1]).to.include(documents[1].received_at);
        expect(textArray[2]).to.include(documents[0].received_at);
      });

      it('type ordered correctly', () => {
        wrapper.find('#type-header').simulate('click');
        expect(wrapper.find('#type-header').
          find('i').
          hasClass('fa-caret-down')).to.be.true;

        let textArray = wrapper.find('tr').map((node) => node.text());

        expect(textArray[1]).to.include(documents[0].type);
        expect(textArray[2]).to.include(documents[1].type);

        wrapper.find('#type-header').simulate('click');
        expect(wrapper.find('#type-header').
          find('i').
          hasClass('fa-caret-up')).to.be.true;

        textArray = wrapper.find('tr').map((node) => node.text());
        expect(textArray[1]).to.include(documents[1].type);
        expect(textArray[2]).to.include(documents[0].type);
      });
    });

    context('when filtered by', () => {
      it('date displays properly', () => {
        wrapper.find('input').simulate('change',
          { target: { value: documents[1].received_at } });

        let textArray = wrapper.find('tr').map((node) => node.text());

        // Header and one filtered row.
        expect(textArray).to.have.length(2);
        expect(textArray[1]).to.include(documents[1].received_at);

        wrapper.find('input').simulate('change', { target: { value: '' } });
        textArray = wrapper.find('tr').map((node) => node.text());
        expect(textArray).to.have.length(3);
      });

      it('type displays properly', () => {
        wrapper.find('input').simulate('change',
          { target: { value: documents[1].type } });

        let textArray = wrapper.find('tr').map((node) => node.text());

        // Header and one filtered row.
        expect(textArray).to.have.length(2);
        expect(textArray[1]).to.include(documents[1].type);

        wrapper.find('input').simulate('change', { target: { value: '' } });
        textArray = wrapper.find('tr').map((node) => node.text());
        expect(textArray).to.have.length(3);
      });

      it('comment displays properly', () => {
        wrapper.find('input').simulate('change',
          { target: { value: annotations[0].comment } });

        let textArray = wrapper.find('tr').map((node) => node.text());

        // Header and one filtered row.
        expect(textArray).to.have.length(2);

        // Should only display the second document
        expect(textArray[1]).to.include(documents[1].type);

        wrapper.find('input').simulate('change', { target: { value: '' } });
        textArray = wrapper.find('tr').map((node) => node.text());
        expect(textArray).to.have.length(3);
      });
    });
  });
});

/* eslint-enable max-statements */
/* eslint-enable no-unused-expressions */
/* eslint-enable camelcase */
