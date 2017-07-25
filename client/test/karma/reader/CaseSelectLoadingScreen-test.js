import React from 'react';
import { expect } from 'chai';
import { mount } from 'enzyme';
import _ from 'lodash';

import { CaseSelectLoadingScreen } from '../../../app/reader/CaseSelectLoadingScreen';

describe('CaseSelectLoadingScreen', () => {
  const getContext = () => mount(<CaseSelectLoadingScreen onInitialDataLoadingFail={_.noop}>
        <p>Show when welcome page is loaded</p>
    </CaseSelectLoadingScreen>);

  it('displays children when the welcome page is loaded', () => {
    const wrapper = getContext().setProps({
      loadedAssignments: []
    });

    expect(wrapper.text()).to.include('Loading cases in Reader...');
  });

  it('displays the error message when the request failed', () => {
    const wrapper = getContext().setProps({ initialDataLoadingFail: true });

    expect(wrapper.text()).to.include('Unable to load the welcome page');
    expect(wrapper.text()).to.include('It looks like Caseflow was unable to load the welcome page.');
  });
});
