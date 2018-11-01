import React from 'react';
import { assert } from 'chai';
import { shallow } from 'enzyme';
import { AddIssuesPage } from '../../../app/intake/pages/addIssues';
import { Redirect } from 'react-router-dom';
import { PAGE_PATHS } from '../../../app/intake/constants';

describe('AddIssuesPage', () => {
  it('redirects to intake start when formType is undefined, like after canceling an intake', () => {
    const wrapper = shallow(<AddIssuesPage />);

    assert.isTrue(wrapper.contains(<Redirect to={PAGE_PATHS.BEGIN} />));
  });
});
