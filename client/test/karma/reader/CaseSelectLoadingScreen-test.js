import React from 'react';
import { expect } from 'chai';
import { mount } from 'enzyme';

import { CaseSelectLoadingScreen } from '../../../app/reader/CaseSelectLoadingScreen';

describe('CaseSelectLoadingScreen', () => {
  const getContext = () => mount(<CaseSelectLoadingScreen>
    <p>Show when welcome page is loaded</p>
  </CaseSelectLoadingScreen>);

  it('displays children when the welcome page is loaded', () => {
    const wrapper = getContext().setProps({
      assignments: [],
      assignmentsLoaded: true
    });

    expect(wrapper.text()).to.include('Show when welcome page is loaded');
  });
});
