import React from 'react';
import { assert } from 'chai';
import { shallow } from 'enzyme';
import { AddIssues } from '../../../app/intake/pages/addIssues';
import { Redirect } from 'react-router-dom';
import { PAGE_PATHS } from '../../../app/intake/constants';

describe('AddIssues', () => {
  it('redirects to intake start when formType is undefined, like after canceling an intake', () => {
    const wrapper = shallow(<AddIssues />);

    assert.isTrue(wrapper.contains(<Redirect to={PAGE_PATHS.BEGIN} />));
  });
});
