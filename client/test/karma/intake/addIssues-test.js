import React from 'react';
import { expect } from 'chai';
import { shallow } from 'enzyme';
import { AddIssues } from '../../../app/intake/pages/AddIssues';
import { Redirect } from 'react-router-dom';

describe.only('AddIssues', () => {
  it('renders Redirect when formType is undefined', () => {
    const wrapper = shallow(<AddIssues formType={undefined}/>);
    expect(wrapper.find(Redirect)).to.have.lengthOf(1);
  });
});
