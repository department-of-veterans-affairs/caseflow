import React from 'react';
import { expect } from 'chai';
import { mount } from 'enzyme';
import DecisionReviewer from '../../../app/reader/DecisionReviewer';
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

    const div = document.createElement('div');

    div.id = 'app';
    document.body.appendChild(div);

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

  context('PDF list view', () => {
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
        expect(wrapper.find('#table-row-1').childAt(0).
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
        expect(wrapper.find('#table-row-0').childAt(0).
          children()).to.have.length(1);
      }));
    });
  });
});

/* eslint-enable max-statements */
/* eslint-enable no-unused-expressions */
/* eslint-enable camelcase */
