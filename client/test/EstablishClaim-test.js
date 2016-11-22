import React from 'react';
import { expect } from 'chai';
import { shallow, mount } from 'enzyme';
import EstablishClaim from '../app/containers/EstablishClaim';

describe.only('EstablishClaim', () => {
  context('.render', () => {
    let wrapper;
    beforeEach(() => {
      const task = {user: 'a', appeal: 'b'};
      wrapper = mount(<EstablishClaim task={task}/>);
    });
    context('when POA is None', () => {
      it('hides POA code textfield', () => {
        wrapper.find('#POA_None').simulate('change');
        expect(wrapper.find('#POACode')).to.have.length(0);
      });
      it('hides Allow POA access checkbox', () => {
        wrapper.find('#POA_None').simulate('change');
        expect(wrapper.find('#AllowPOA')).to.have.length(0);
      });
    });
    context('when POA is VSO', () => {
      it('show POA code textfield', () => {
        wrapper.find('#POA_VSO').simulate('change');
        expect(wrapper.find('#POACode')).to.have.length(1);
      });
      it('show Allow POA access checkbox', () => {
        wrapper.find('#POA_VSO').simulate('change');
        expect(wrapper.find('#AllowPOA')).to.have.length(1);
      });
    });
    context('when POA is Private', () => {
      it('show POA code textfield', () => {
        wrapper.find('#POA_VSO').simulate('change');
        expect(wrapper.find('#POACode')).to.have.length(1);
      });
      it('show Allow POA access checkbox', () => {
        wrapper.find('#POA_VSO').simulate('change');
        expect(wrapper.find('#AllowPOA')).to.have.length(1);
      });
    });
  });
});
