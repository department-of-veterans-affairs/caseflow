import React from 'react';
import { expect } from 'chai';
import { shallow } from 'enzyme';
import { AddIssues } from '../../../app/intake/pages/addIssues';
import { Redirect } from 'react-router-dom';

describe('AddIssues', () => {
  it('renders Redirect when formType is undefined', () => {
    const wrapper = shallow(<AddIssues />);

    expect(wrapper.find(Redirect)).to.have.lengthOf(1);
  });
});
