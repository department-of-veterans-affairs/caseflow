import React from 'react';
import { expect } from 'chai';
import { mount } from 'enzyme';
import _ from 'lodash';

import { ReaderLoadingScreen } from '../../../app/reader/ReaderLoadingScreen';

describe('ReaderLoadingScreen', () => {
  const getContext = () => mount(<ReaderLoadingScreen>
    <p>Show when documents are loaded</p>
  </ReaderLoadingScreen>);
  const vacolsId = 1;

  it('displays children when the documents are loaded', () => {
    const wrapper = getContext().setProps({
      documentsLoaded: true,
      loadedAppealId: vacolsId,
      vacolsId
    });

    expect(wrapper.text()).to.include('Show when documents are loaded');
  });
});
