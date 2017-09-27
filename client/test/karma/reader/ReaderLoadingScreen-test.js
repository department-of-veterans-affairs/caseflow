import React from 'react';
import { expect } from 'chai';
import { mount } from 'enzyme';
import _ from 'lodash';

import { ReaderLoadingScreen } from '../../../app/reader/ReaderLoadingScreen';

describe('ReaderLoadingScreen', () => {
  const getContext = () => mount(<ReaderLoadingScreen onInitialDataLoadingFail={_.noop} >
        <p>Show when documents are loaded</p>
    </ReaderLoadingScreen>, { attachTo: document.body });
  const vacolsId = 1;

  it('displays children when the documents are loaded', () => {
    const wrapper = getContext().setProps({
      documentsLoaded: true,
      loadedAppealId: vacolsId,
      vacolsId
    });

    expect(wrapper.text()).to.include('Show when documents are loaded');
  });

  it('displays the error message when the request failed', () => {
    const wrapper = getContext().setProps({ initialDataLoadingFail: true });

    expect(wrapper.text()).to.include('Unable to load documents');
    expect(wrapper.text()).to.include('It looks like Caseflow was unable to load this case.');
  });
});
