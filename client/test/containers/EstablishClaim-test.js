import React from 'react';
import { expect } from 'chai';
import { shallow, mount } from 'enzyme';
import EstablishClaim from '../../app/containers/EstablishClaim';

describe('EstablishClaim', () => {
  context('.render', () => {
    let wrapper;
    beforeEach(() => {
      const task = {user: 'a', appeal: 'b'};
      wrapper = mount(<EstablishClaim task={task}/>);
    });

    context('when POA is None', () => {
      beforeEach(() => {
        wrapper.find('#POA_None').simulate('change');
      });

      it('hides POA code textfield', () => {
        expect(wrapper.find('#POACode')).to.have.length(0);
      });
      it('hides Allow POA access checkbox', () => {
        expect(wrapper.find('#AllowPOA')).to.have.length(0);
      });
    });

    context('when POA is VSO', () => {
      beforeEach(() => {
        wrapper.find('#POA_VSO').simulate('change');
      });

      it('show POA code textfield', () => {
        expect(wrapper.find('#POACode')).to.have.length(1);
      });
      it('show Allow POA access checkbox', () => {
        expect(wrapper.find('#allowPoa')).to.have.length(1);
      });
    });

    context('when POA is Private', () => {
      beforeEach(() => {
        wrapper.find('#POA_Private').simulate('change');
      });

      it('show POA code textfield', () => {
        expect(wrapper.find('#POACode')).to.have.length(1);
      });
      it('show Allow POA access checkbox', () => {
        expect(wrapper.find('#allowPoa')).to.have.length(1);
      });
    });
  });
});
