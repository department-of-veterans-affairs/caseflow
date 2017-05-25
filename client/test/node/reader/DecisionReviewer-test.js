import React from 'react';
import { expect } from 'chai';
import { mount } from 'enzyme';
import sinon from 'sinon';

import { MemoryRouter } from 'react-router-dom';
import DecisionReviewer from '../../../app/reader/DecisionReviewer';
import { documents } from '../../data/documents';
import { annotations } from '../../data/annotations';
import { createStore, applyMiddleware } from 'redux';
import thunk from 'redux-thunk';
import { Provider } from 'react-redux';
import { asyncTest, pause } from '../../helpers/AsyncTests';
import ApiUtilStub from '../../helpers/ApiUtilStub';
import { formatDateStr } from '../../../app/util/DateUtil';

import readerReducer from '../../../app/reader/reducer';
import PdfJsStub from '../../helpers/PdfJsStub';
import { onReceiveDocs, onReceiveAnnotations } from '../../../app/reader/actions';

// This is the route history preset in react router
// prior to tests running
const INITIAL_ENTRIES = [
  '/reader_id1/documents',
  `/reader_id1/documents/${documents[0].id}`
];

/* eslint-disable camelcase */
/* eslint-disable no-unused-expressions */
/* eslint-disable max-statements */
describe('DecisionReviewer', () => {
  let wrapper;
  let setUpDocuments;

  beforeEach(() => {
    PdfJsStub.beforeEach();
    ApiUtilStub.beforeEach();

    const store = createStore(readerReducer, applyMiddleware(thunk));

    setUpDocuments = () => {
      // We simulate receiving the documents from the endpoint, and dispatch the
      // required actions to skip past the loading screen and avoid stubing out
      // the API call to the index endpoint.
      store.dispatch(onReceiveDocs(documents));
      store.dispatch(onReceiveAnnotations(annotations));
    };

    wrapper = mount(
      <Provider store={store}>
        <DecisionReviewer
          pdfWorker="worker"
          url="url"
          router={MemoryRouter}
          routerTestProps={{
            initialEntries: INITIAL_ENTRIES
          }}

        />
      </Provider>, { attachTo: document.getElementById('app') });
  });

  afterEach(() => {
    wrapper.detach();
    ApiUtilStub.afterEach();
    PdfJsStub.afterEach();
  });

  context('Loading Spinner', () => {
    it('renders', () => {
      expect(wrapper.text()).to.include('Loading document list');
    });
  });

  context('PDF View', () => {
    beforeEach(() => setUpDocuments());

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
        let setUpPdf = sinon.spy(pdf, 'setUpPdf');

        // Next button moves us to the next page
        wrapper.find('#button-next').simulate('click');
        await pause();

        expect(setUpPdf.lastCall.calledWith(
          `/document/${documents[1].id}/pdf`)).to.be.true;

        // Previous button moves us to the previous page
        wrapper.find('#button-previous').simulate('click');
        await pause();

        expect(setUpPdf.lastCall.calledWith(
          `/document/${documents[0].id}/pdf`)).to.be.true;
      }));

      it('are hidden when there is no next or previous pdf', () => {
        // Filter documents on the second document's type
        wrapper.find('input').simulate('change',
          { target: { value: documents[1].type } });

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
        wrapper.find('#button-edit-comment-1').simulate('click');

        // Verify that the text in the textbox is the existing comment
        expect(wrapper.find('textarea').props().value).
          to.be.equal(firstComment.comment);

        // Add new text to the edit textbox
        wrapper.find('#editCommentBox-1').simulate('change',
          { target: { value: secondComment.comment } });

        // Save the edit
        wrapper.find('#button-save').simulate('click');
        await pause();

        // Verify the api is called to edit a comment
        expect(ApiUtilStub.apiPatch.calledWith(
          `/document/${documents[0].id}/annotation/${commentId}`,
          sinon.match({ data: { annotation: secondComment } }))).to.be.true;

        // Click on the delete button
        wrapper.find('#button-delete-comment-1').simulate('click');

        // Click on the cancel delete in the modal
        wrapper.find('#Delete-Comment-button-id-0').simulate('click');

        // Re-open delete modal
        wrapper.find('#button-delete-comment-1').simulate('click');

        // Click on the confirm delete in the modal
        wrapper.find('#Delete-Comment-button-id-1').simulate('click');
        await pause();

        // Verify the api is called to delete a comment
        expect(ApiUtilStub.apiDelete.
          calledWith(`/document/${documents[0].id}/annotation/${commentId}`)).
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

  context('PDF list view', () => {
    beforeEach(() => setUpDocuments());

    context('last read indicator', () => {
      it('appears on latest read document', asyncTest(async() => {
        // Click on first document link
        wrapper.find('a').findWhere(
          (link) => link.text() === documents[0].type).
          simulate('mouseUp');
        await pause();

        // Next button moves us to the next page
        wrapper.find('#button-next').simulate('click');
        await pause();

        wrapper.find('#button-backToDocuments').simulate('click');
        // Make sure that the 1st row has the last
        // read indicator in the first column.
        expect(wrapper.find('#table-row-2').childAt(0).
          children()).to.have.length(1);
      }));

      it('appears on document opened in new tab', asyncTest(async() => {
        const event = {
          ctrlKey: true
        };

        wrapper.find('a').findWhere(
          (link) => link.text() === documents[0].type).
          simulate('mouseUp', event);
        await pause();

        // Make sure that the 0th row has the last
        // read indicator in the first column.
        expect(wrapper.find('#table-row-1').childAt(0).
          children()).to.have.length(1);
      }));
    });

    context('when expanded comments', () => {
      it('can view comments', () => {
        expect(wrapper.text()).to.not.include('Test Comment');
        wrapper.find('#expand-2-comments-button').simulate('click');
        expect(wrapper.text()).to.include('Test Comment');
      });

      it('page number is displayed', asyncTest(async() => {
        wrapper.find('#expand-2-comments-button').simulate('click');
        expect(wrapper.text()).to.include(`Page ${annotations[0].page}`);
      }));
    });

    context('when sorted by', () => {
      it('date is ordered correctly', () => {
        expect(wrapper.find('#receipt-date-header').
          find('i').
          hasClass('fa-caret-down')).to.be.true;

        let textArray = wrapper.find('tr').map((node) => node.text());

        expect(textArray[1]).to.include(formatDateStr(documents[0].received_at));
        expect(textArray[2]).to.include(formatDateStr(documents[1].received_at));

        wrapper.find('#receipt-date-header').simulate('click');
        expect(wrapper.find('#receipt-date-header').
          find('i').
          hasClass('fa-caret-up')).to.be.true;

        textArray = wrapper.find('tr').map((node) => node.text());
        expect(textArray[1]).to.include(formatDateStr(documents[1].received_at));
        expect(textArray[2]).to.include(formatDateStr(documents[0].received_at));
      });

      it('type ordered correctly', () => {
        wrapper.find('#type-header').simulate('click');
        expect(wrapper.find('#type-header').
          find('i').
          hasClass('fa-caret-up')).to.be.true;

        let textArray = wrapper.find('tr').map((node) => node.text());

        expect(textArray[1]).to.include(documents[1].type);
        expect(textArray[2]).to.include(documents[0].type);

        wrapper.find('#type-header').simulate('click');
        expect(wrapper.find('#type-header').
          find('i').
          hasClass('fa-caret-down')).to.be.true;

        textArray = wrapper.find('tr').map((node) => node.text());
        expect(textArray[1]).to.include(documents[0].type);
        expect(textArray[2]).to.include(documents[1].type);
      });
    });

    context('when searched by', () => {
      it('date displays properly', () => {
        wrapper.find('input').simulate('change',
          { target: { value: documents[1].received_at } });

        let textArray = wrapper.find('tr').map((node) => node.text());

        // Header and one filtered row.
        expect(textArray).to.have.length(2);
        expect(textArray[1]).to.include(formatDateStr(documents[1].received_at));

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

      it('category displays properly', () => {
        wrapper.find('input').simulate('change',
          { target: { value: 'medical' } });

        let textArray = wrapper.find('tr').map((node) => node.text());

        // Header and one filtered row.
        expect(textArray).to.have.length(2);

        // Should only display the first document
        expect(textArray[1]).to.include(documents[0].type);

        wrapper.find('input').simulate('change', { target: { value: '' } });
        textArray = wrapper.find('tr').map((node) => node.text());
        expect(textArray).to.have.length(3);
      });

      it('tag displays properly', () => {
        wrapper.find('input').simulate('change',
          { target: { value: 'mytag' } });

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

    context('when filtered by', () => {
      const openMenu = (node, menuName) => {
        node.find(`#${menuName}-header`).find('svg').
          simulate('click');
      };

      const checkBox = (node, text, value) => {
        node.find('Checkbox').filterWhere((box) => box.text().
          includes(text)).
          find('input').
          simulate('change', { target: { checked: value } });
      };

      it('category displays properly', () => {
        openMenu(wrapper, 'categories');

        checkBox(wrapper, 'Procedural', true);

        let textArray = wrapper.find('tr').map((node) => node.text());

        // Header and one filtered row.
        expect(textArray).to.have.length(2);

        // Should only display the first document
        expect(textArray[1]).to.include(documents[1].type);

        checkBox(wrapper, 'Procedural', false);

        textArray = wrapper.find('tr').map((node) => node.text());
        expect(textArray).to.have.length(3);
      });

      it('tag displays properly', () => {
        openMenu(wrapper, 'tags');

        checkBox(wrapper, 'mytag', true);

        let textArray = wrapper.find('tr').map((node) => node.text());

        // Header and one filtered row.
        expect(textArray).to.have.length(2);

        // Should only display the second document
        expect(textArray[1]).to.include(documents[1].type);

        checkBox(wrapper, 'mytag', false);
      });
    });
  });
});

/* eslint-enable max-statements */
/* eslint-enable no-unused-expressions */
/* eslint-enable camelcase */
