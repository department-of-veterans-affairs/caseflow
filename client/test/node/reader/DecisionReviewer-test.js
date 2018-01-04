/* eslint-disable max-lines */

import React from 'react';
import { expect } from 'chai';
import { mount } from 'enzyme';

import { MemoryRouter } from 'react-router-dom';
import DecisionReviewer from '../../../app/reader/DecisionReviewer';
import { documents } from '../../data/documents';
import { annotations } from '../../data/annotations';
import { createStore, applyMiddleware, compose } from 'redux';
import thunk from 'redux-thunk';
import { Provider } from 'react-redux';
import { reduxSearch } from 'redux-search';
import { asyncTest, pause } from '../../helpers/AsyncTests';
import ApiUtilStub from '../../helpers/ApiUtilStub';
import ApiUtil from '../../../app/util/ApiUtil';
import { formatDateStr } from '../../../app/util/DateUtil';

import PdfJsStub, { PAGE_WIDTH, PAGE_HEIGHT } from '../../helpers/PdfJsStub';
import { onReceiveDocs } from '../../../app/reader/Documents/DocumentsActions';
import { onReceiveAnnotations } from '../../../app/reader/AnnotationLayer/AnnotationActions';
import sinon from 'sinon';
import { AutoSizer } from 'react-virtualized';
import rootReducer from '../../../app/reader/reducers';

const vacolsId = 'reader_id1';

// This is the route history preset in react router
// prior to tests running
const INITIAL_ENTRIES = [
  `/${vacolsId}/documents`,
  `/${vacolsId}/documents/${documents[0].id}`
];

const getStore = () => createStore(
  rootReducer,
  compose(
    applyMiddleware(thunk),
    reduxSearch({
      // Configure redux-search by telling it which resources to index for searching
      resourceIndexes: {
        // In this example Books will be searchable by :title and :author
        extractedText: ['text']
      },
      // This selector is responsible for returning each collection of searchable resources
      resourceSelector: (resourceName, state) => {
        // In our example, all resources are stored in the state under a :resources Map
        // For example "books" are stored under state.resources.books
        return state.searchActionReducer[resourceName];
      }
    })
  )
);

const getWrapper = (store) => mount(
  <Provider store={store}>
    <DecisionReviewer
      featureToggles={{}}
      userDisplayName="Name"
      feedbackUrl="fakeurl"
      dropdownUrls={[{
        title: 'title',
        link: 'link'
      }]}
      pdfWorker="worker"
      url="url"
      router={MemoryRouter}
      routerTestProps={{
        initialEntries: INITIAL_ENTRIES
      }}

    />
  </Provider>, { attachTo: document.getElementById('app') });

/* eslint-disable camelcase */
/* eslint-disable no-unused-expressions */
/* eslint-disable max-statements */
describe('DecisionReviewer', () => {
  let wrapper;

  describe('with ApiUtil stubbing', () => {

    let setUpDocuments;

    beforeEach(() => {
      PdfJsStub.beforeEach();
      ApiUtilStub.beforeEach();

      /* eslint-disable no-underscore-dangle */
      sinon.stub(AutoSizer.prototype, 'render').callsFake(function () {
        return <div ref={this._setRef}>
          {this.props.children({ width: 200,
            height: 100 })}
        </div>;
      });
      /* eslint-enable no-underscore-dangle */

      const store = getStore();

      setUpDocuments = () => {
      // We simulate receiving the documents from the endpoint, and dispatch the
      // required actions to skip past the loading screen and avoid stubing out
      // the API call to the index endpoint.
        store.dispatch(onReceiveDocs(documents, vacolsId));
        store.dispatch(onReceiveAnnotations(annotations));
      };

      wrapper = getWrapper(store);
    });

    afterEach(() => {
      wrapper.detach();
      ApiUtilStub.afterEach();
      PdfJsStub.afterEach();
      AutoSizer.prototype.render.restore();
    });

    context('PDF View', () => {
      beforeEach(() => setUpDocuments());

      context('renders', () => {
        it('the PDF list view', () => {
          expect(wrapper.find('PdfListView')).to.have.length(1);
        });

        it('the PDF view when a PDF is clicked', asyncTest(async () => {
        // Click on first document link
          wrapper.find('a').filterWhere(
            (link) => link.text() === documents[0].type).
            simulate('click', { button: 0 });
          await pause();

          expect(wrapper.find('PdfViewer')).to.have.length(1);

          // Return to document list view
          wrapper.find('a').filterWhere(
            (link) => link.text().includes('Back to claims')).
            simulate('click', { button: 0 });
          await pause();

          expect(wrapper.find('PdfListView')).to.have.length(1);
        }));
      });

      context('rotate', () => {
        it('turns pages', asyncTest(async() => {
        // Stub ApiUtil.get() calls so request to content_url return some fake response.
          ApiUtilStub.apiGet.withArgs(documents[0].content_url).resolves({ body: 'hello world' });

          // Click on first document link
          wrapper.find('a').filterWhere(
            (link) => link.text() === documents[0].type).
            simulate('click', { button: 0 });
          await pause();

          expect(wrapper.find('#rotationDiv1').
            props().style.transform).to.equal('rotate(0deg)');

          wrapper.find('#button-rotation').simulate('click', { button: 0 });

          expect(wrapper.find('#rotationDiv1').
            props().style.transform).to.equal('rotate(90deg)');

          const pageContainerStyle = wrapper.find('#pageContainer1').props().style;

          await pause();

          expect(pageContainerStyle.width).to.equal(`${PAGE_HEIGHT}px`);
          expect(pageContainerStyle.height).to.equal(`${PAGE_WIDTH}px`);
        }));
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

          // Stub ApiUtil.get() calls so request to content_url return some fake response.
          ApiUtilStub.apiGet.withArgs(documents[0].content_url).resolves({ body: 'hello world' });

          // Stub out post requests to return the commentId
          ApiUtilStub.apiPost.resolves({ text: `{ "id": ${commentId} }` });

          wrapper.find('a').filterWhere(
            (link) => link.text() === documents[0].type).
            simulate('click', { button: 0 });

          await pause();

          // Click on the add a comment button
          wrapper.find('#button-AddComment').simulate('click');

          // Click on the pdf at the location specified by event
          wrapper.find('#comment-layer-0-/document/1/pdf').simulate('click', event);

          // Add text to the comment text box.
          wrapper.find('#addComment').simulate('change',
            { target: { value: firstComment.comment } });

          // Click on save
          wrapper.find('#button-save').simulate('click');
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
      });
    });

    context('PDF list view', () => {
      beforeEach(() => setUpDocuments());

      context('last read indicator', () => {
        it('appears on latest read document', asyncTest(async() => {
        // Click on first document link
          wrapper.find('a').filterWhere(
            (link) => link.text() === documents[0].type).
            simulate('click', { button: 0 });
          await pause();

          // Previous button moves us to the previous page
          wrapper.find('#button-previous').simulate('click');
          await pause();

          wrapper.find('a').filterWhere(
            (link) => link.text().includes('Back to claims')).
            simulate('click', { button: 0 });
          await pause();
          // Make sure that the 2nd row has the last
          // read indicator in the first column.
          expect(wrapper.find('#table-row-2').childAt(1).
            children()).to.have.length(1);
        }));

        it('appears on document opened in new tab', asyncTest(async() => {
          const event = {
            ctrlKey: true,
            button: 0
          };

          wrapper.find('a').filterWhere(
            (link) => link.text() === documents[0].type).
            simulate('click', event);
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
          expect(wrapper.find('#receipt-date-header .cf-sort-arrowup')).to.have.length(1);

          let textArray = wrapper.find('tr').map((node) => node.text());

          expect(textArray[1]).to.include(formatDateStr(documents[1].received_at));
          expect(textArray[2]).to.include(formatDateStr(documents[0].received_at));

          wrapper.find('#receipt-date-header').simulate('click');
          expect(wrapper.find('#receipt-date-header .cf-sort-arrowdown')).to.have.length(1);

          textArray = wrapper.find('tr').map((node) => node.text());
          expect(textArray[1]).to.include(formatDateStr(documents[0].received_at));
          expect(textArray[2]).to.include(formatDateStr(documents[1].received_at));
        });

        it('type ordered correctly', () => {
          wrapper.find('#type-header').simulate('click');
          expect(wrapper.find('#type-header .cf-sort-arrowdown')).to.have.length(1);

          let textArray = wrapper.find('tr').map((node) => node.text());

          expect(textArray[1]).to.include(documents[0].type);
          expect(textArray[2]).to.include(documents[1].type);

          wrapper.find('#type-header').simulate('click');
          expect(wrapper.find('#type-header .cf-sort-arrowup')).to.have.length(1);

          textArray = wrapper.find('tr').map((node) => node.text());
          expect(textArray[1]).to.include(documents[1].type);
          expect(textArray[2]).to.include(documents[0].type);
        });
      });

      context('when searched by', () => {
        it('does and logic search', () => {
          wrapper.find('input').simulate('change',
            { target: { value: '/2017 mytag form' } });

          let textArray = wrapper.find('tbody').find('tr').
            map((node) => node.text());

          expect(textArray).to.have.length(1);
          expect(textArray[0]).to.include('form 9');

          wrapper.find('input').simulate('change',
            { target: { value: '/2017 mytag do not show' } });

          textArray = wrapper.find('tbody').find('tr').
            map((node) => node.text());
          expect(textArray).to.have.length(0);
        });

        it('does search highlighting for matched keywords', () => {
          wrapper.find('input').simulate('change',
            { target: { value: 'mytag form' } });

          const doesArrayIncludeString = (array, string) => array.some((item) => item.includes(string));
          let textArray = wrapper.find('mark').
            map((node) => node.text());

          expect(doesArrayIncludeString(textArray, 'form')).to.be.true;
          expect(doesArrayIncludeString(textArray, 'mytag')).to.be.true;

          // searching for a comment
          wrapper.find('input').simulate('change',
            { target: { value: 'comment' } });

          // comment is already expanded and highlighted
          expect(wrapper.html()).to.include('<mark class=" ">Comment</mark>');
        });

        it('does search highlighting for categories', () => {
          wrapper.find('input').simulate('change',
            { target: { value: 'medical' } });

          // get the first category icon
          let textArray = wrapper.find('tbody').find('tr').
            find('.cf-document-category-icons').
            find('li').
            first();

          expect(textArray.prop('aria-label')).to.equal('Medical');
          expect(textArray.hasClass('highlighted')).to.be.true;
        });

        it('date displays properly', () => {
          const receivedAt = formatDateStr(documents[1].received_at);

          wrapper.find('input').simulate('change',
            { target: { value: receivedAt } });

          let textArray = wrapper.find('tr').map((node) => node.text());

          // Header and one filtered row.
          expect(textArray).to.have.length(2);
          expect(textArray[1]).to.include(receivedAt);

          wrapper.find('input').simulate('change', { target: { value: '' } });
          textArray = wrapper.find('tr').map((node) => node.text());
          expect(textArray).to.have.length(3);
        });

        it('receipt date search works properly', () => {
          const receivedAt = formatDateStr(documents[1].received_at, null, 'MM/DD/YYYY');

          wrapper.find('input').simulate('change',
            { target: { value: receivedAt } });

          let textArray = wrapper.find('tbody').find('tr').
            map((node) => node.text());

          expect(textArray).to.have.length(1);
          expect(textArray[0]).to.include(receivedAt);
          expect(textArray[0]).to.include(documents[1].type);

          wrapper.find('input').simulate('change', { target: { value: '' } });
          textArray = wrapper.find('tbody').find('tr').
            map((node) => node.text());
          expect(textArray).to.have.length(2);

          wrapper.find('input').simulate('change', { target: { value: '/2017' } });
          textArray = wrapper.find('tbody').find('tr').
            map((node) => node.text());
          expect(textArray).to.have.length(2);

          wrapper.find('input').simulate('change', { target: { value: '03' } });
          textArray = wrapper.find('tbody').find('tr').
            map((node) => node.text());
          expect(textArray).to.have.length(1);
          expect(textArray[0]).to.include('form 9');
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
          expect(textArray).to.have.length(3);

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

          // Header and two filtered row.
          expect(textArray).to.have.length(3);

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

          // Header and two filtered row.
          expect(textArray).to.have.length(3);

          // Should only display the second document
          expect(textArray[1]).to.include(documents[1].type);

          checkBox(wrapper, 'mytag', false);
        });
      });
    });
  });

  // In theory, we can come up with a nicer way to share logic between these two
  // describe blocks. However, I failed to do so after spending substantial time.
  // I think the approach below is reasonable.
  describe('without ApiUtil stubbing', () => {
    beforeEach(() => {
      const store = getStore();

      wrapper = getWrapper(store);
    });

    afterEach(() => {
      wrapper.detach();
    });

    context('Loading Spinner', () => {
      it('renders', () => {
        // eslint-disable-next-line no-empty-function
        const eternalPromise = new Promise(() => {});

        sinon.stub(ApiUtil, 'get').returns(eternalPromise);
        expect(wrapper.text()).to.include('Loading claims folder');
      });
    });
  });
});

