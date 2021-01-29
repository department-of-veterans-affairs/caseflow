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
import { asyncTest } from '../../helpers/AsyncTests';
import ApiUtilStub from '../../helpers/ApiUtilStub';
import ApiUtil from '../../../app/util/ApiUtil';
import { formatDateStr } from '../../../app/util/DateUtil';

import PdfJsStub from '../../helpers/PdfJsStub';
import { onReceiveDocs } from '../../../app/reader/Documents/DocumentsActions';
import { onReceiveAnnotations } from '../../../app/reader/AnnotationLayer/AnnotationActions';
import sinon from 'sinon';
import { AutoSizer } from 'react-virtualized';
import rootReducer from '../../../app/reader/reducers';

import { findElementById } from '../../helpers';

const vacolsId = 'reader_id1';

const sleep = (ms) => {
  return new Promise((resolve) => setTimeout(resolve, ms));
};

// This is the route history preset in react router
// prior to tests running
const INITIAL_ENTRIES = [
  `/${vacolsId}/documents`,
  `/${vacolsId}/documents/${documents[0].id}`
];

const getStore = () => createStore(
  rootReducer,
  compose(
    applyMiddleware(thunk)
  )
);

const getWrapper = (store) => mount(
  <Provider store={store}>
    <MemoryRouter initialEntries={INITIAL_ENTRIES}>
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
      />
    </MemoryRouter>
  </Provider>, { attachTo: document.getElementById('app') });

/* eslint-disable camelcase */
/* eslint-disable no-unused-expressions */
/* eslint-disable max-statements */
describe('DecisionReviewer', () => {
  const setUpDocuments = (store) => {
    // We simulate receiving the documents from the endpoint, and dispatch the
    // required actions to skip past the loading screen and avoid stubing out
    // the API call to the index endpoint.
    store.dispatch(onReceiveDocs(documents, vacolsId));
    store.dispatch(onReceiveAnnotations(annotations));
  };

  let wrapper;
  let store;
  let autoSizerStub;

  describe('with ApiUtil stubbing', () => {
    beforeEach(async() => {
      PdfJsStub.beforeEach();
      ApiUtilStub.beforeEach();

      /* eslint-disable no-underscore-dangle */
      autoSizerStub = sinon.stub(AutoSizer.prototype, 'render');
      autoSizerStub.callsFake(function () {
        return <div ref={this._setRef}>
          {this.props.children({ width: 200,
            height: 100 })}
        </div>;
      });
      /* eslint-enable no-underscore-dangle */

      store = getStore();
      setUpDocuments(store);
      wrapper = getWrapper(store);
      await sleep();
      wrapper.update();
    });

    afterEach(() => {
      wrapper.detach();
      ApiUtilStub.afterEach();
      PdfJsStub.afterEach();
      autoSizerStub.restore();
    });

    context('PDF list view', () => {
      context('when expanded comments', () => {
        it('can view comments', () => {
          expect(wrapper.text()).to.not.include('Test Comment');
          findElementById(wrapper, 'expand-2-comments-button').simulate('click');
          expect(wrapper.text()).to.include('Test Comment');
        });

        it('page number is displayed', asyncTest(async() => {
          findElementById(wrapper, 'expand-2-comments-button').simulate('click');
          expect(wrapper.text()).to.include(`Page ${annotations[0].page}`);
        }));
      });

      context('when sorted by', () => {
        it('date is ordered correctly', () => {
          expect(wrapper.find('#receipt-date-header .cf-sort-arrowup')).to.have.length(1);

          let textArray = wrapper.find('tr').map((node) => node.text());

          expect(textArray[1]).to.include(formatDateStr(documents[1].received_at));
          expect(textArray[2]).to.include(formatDateStr(documents[0].received_at));

          findElementById(wrapper, 'receipt-date-header').simulate('click');
          expect(wrapper.find('#receipt-date-header .cf-sort-arrowdown')).to.have.length(1);

          textArray = wrapper.find('tr').map((node) => node.text());
          expect(textArray[1]).to.include(formatDateStr(documents[0].received_at));
          expect(textArray[2]).to.include(formatDateStr(documents[1].received_at));
        });

        it('type ordered correctly', () => {
          findElementById(wrapper, 'type-header').simulate('click');
          expect(wrapper.find('#type-header .cf-sort-arrowdown')).to.have.length(1);

          let textArray = wrapper.find('tr').map((node) => node.text());

          expect(textArray[1]).to.include(documents[0].type);
          expect(textArray[2]).to.include(documents[1].type);

          findElementById(wrapper, 'type-header').simulate('click');
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
      store = getStore();

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

