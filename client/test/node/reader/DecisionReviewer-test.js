import React from 'react';
import { expect, assert } from 'chai';
import { mount } from 'enzyme';
import DecisionReviewer from '../../../app/reader/DecisionReviewer';
import sinon from 'sinon';
import { documents } from '../../data/documents';
import { annotations } from '../../data/annotations';
import _ from 'lodash';
import { Provider } from 'react-redux';
import { createStore } from 'redux';
import { asyncTest, pause } from '../../helpers/AsyncTests';
import ApiUtilStub from '../../helpers/ApiUtilStub';

import { readerReducer } from '../../../app/reader/index';
import PdfJsStub from '../../helpers/PdfJsStub';

/* eslint-disable camelcase */
/* eslint-disable no-unused-expressions */
/* eslint-disable max-statements */
describe('DecisionReviewer', () => {
  let wrapper;

  beforeEach(() => {
    PdfJsStub.beforeEach();
    ApiUtilStub.beforeEach();

    wrapper = mount(
      <Provider store={createStore(readerReducer)}>
        <DecisionReviewer
          appealDocuments={documents}
          annotations={annotations}
          onReceiveDocs={_.noop}
          pdfWorker="worker"
          url="url"
        />
      </Provider>, { attachTo: document.getElementById('app') });
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

    context('navigation buttons', () => {
      it('move to the next and previous pdfs', asyncTest(async() => {
        // Click on first document link
        wrapper.find('a').findWhere(
          (link) => link.text() === documents[0].type).
          simulate('mouseUp');
        await pause();

        let pdf = wrapper.find('Pdf').getNode();
        let setupPdf = sinon.spy(pdf, 'setupPdf');

        // Next button moves us to the next page
        wrapper.find('#button-next').simulate('click');
        await pause();

        expect(setupPdf.lastCall.calledWith(
          `/document/${documents[1].id}/pdf`)).to.be.true;

        // Previous button moves us to the previous page
        wrapper.find('#button-previous').simulate('click');
        await pause();

        expect(setupPdf.lastCall.calledWith(
          `/document/${documents[0].id}/pdf`)).to.be.true;
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

    context('comments', () => {
      let event = {
        pageX: 10,
        pageY: 20
      };

      it('can be added, edited, and deleted', asyncTest(async() => {
        let commentId = 1;
        let firstComment = {
          class: 'Annotation',
          page: 1,
          type: 'point',
          x: 10,
          y: 20,
          comment: 'hello',
          document_id: 1
        };
        let secondComment = {
          class: 'Annotation',
          page: 1,
          type: 'point',
          x: 10,
          y: 20,
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
        wrapper.find('#button-AddComment').simulate('click');

        // Click on the pdf at the location specified by event
        wrapper.find('#pageContainer1').simulate('click', event);

        // Add text to the comment text box.
        wrapper.find('#addComment').simulate('change',
          { target: { value: firstComment.comment } });

        // Click on save
        wrapper.find('#button-save').simulate('click');
        await pause();

        // Verify the api is called to add a comment
        expect(ApiUtilStub.apiPost.calledWith(`/document/${documents[0].id}/annotation`,
          sinon.match({ data: { annotation: firstComment } }))).to.be.true;
        await pause();

        // Click on the edit button
        wrapper.find('#button-edit').simulate('click');

        // Verify that the text in the textbox is the existing comment
        expect(wrapper.find('textarea').props().value).
          to.be.equal(firstComment.comment);

        // Add new text to the edit textbox
        wrapper.find('#editCommentBox').simulate('change',
          { target: { value: secondComment.comment } });

        // Save the edit
        wrapper.find('#button-save').simulate('click');
        await pause();

        // Verify the api is called to edit a comment
        expect(ApiUtilStub.apiPatch.calledWith(
          `/document/${documents[0].id}/annotation/${commentId}`,
          sinon.match({ data: { annotation: secondComment } }))).to.be.true;

        // Click on the delete button
        wrapper.find('#button-delete').simulate('click');

        // Click on the cancel delete in the modal
        wrapper.find('#Delete-Comment-button-id-0').simulate('click');

        // Re-open delete modal
        wrapper.find('#button-delete').simulate('click');

        // Click on the confirm delete in the modal
        wrapper.find('#Delete-Comment-button-id-1').simulate('click');
        await pause();

        // Verify the api is called to delete a comment
        expect(ApiUtilStub.apiDelete.
          calledWith(`/document/${documents[0].id}/annotation/${commentId}`)).
          to.be.true;
      }));

      it('can be clicked on to jump to icon', asyncTest(async() => {
        let commentId = 1;
        let jumpTo = sinon.spy(wrapper.find('DecisionReviewer').
          getNode(), 'onJumpToComment');

        ApiUtilStub.apiPost.resolves({ text: `{ "id": ${commentId} }` });

        wrapper.find('a').findWhere(
          (link) => link.text() === documents[0].type).
          simulate('mouseUp');

        wrapper.find('#button-AddComment').simulate('click');

        await pause();
        wrapper.find('#pageContainer1').simulate('click', event);

        wrapper.find('#addComment').simulate('change', { target: { value: 'hello' } });

        wrapper.find('#button-save').simulate('click');
        await pause();

        wrapper.find('#comment0').simulate('click');
        assert(jumpTo.calledWith(sinon.match({ id: commentId })));
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

      it('comment has page number', asyncTest(async() => {
        wrapper.find('a').findWhere(
          (link) => link.text() === documents[1].type).
          simulate('mouseUp');

        expect(wrapper.text()).to.include(`Page ${annotations[0].page}`);
      }));
    });
  });
});

/* eslint-enable max-statements */
/* eslint-enable no-unused-expressions */
/* eslint-enable camelcase */
