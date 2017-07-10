import React from 'react';
import { expect } from 'chai';
import { mount } from 'enzyme';
import _ from 'lodash';

import { LoadingScreen } from '../../../app/reader/LoadingScreen';

describe('LoadingScreen', () => {
  const getContext = () => mount(<LoadingScreen onInitialDataLoadingFail={_.noop} >
        <p>Show when documents are loaded</p>
    </LoadingScreen>);
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
