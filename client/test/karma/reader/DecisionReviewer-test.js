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

describe('DecisionReviewer', () => {
  let wrapper;

  beforeEach(() => {
    PdfJsStub.beforeEach();
    ApiUtilStub.beforeEach();

    const div = document.createElement('div');

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
      </Provider>, { attachTo: div });
  });

  afterEach(() => {
    wrapper.detach();
    ApiUtilStub.afterEach();
    PdfJsStub.afterEach();
  });
});
