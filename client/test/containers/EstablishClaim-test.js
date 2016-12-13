import React from 'react';
import { expect } from 'chai';
import { mount } from 'enzyme';
import EstablishClaim, { FORM_PAGE } from
  '../../app/containers/EstablishClaimPage/EstablishClaim';

describe('EstablishClaim', () => {
  context('.render', () => {
    let wrapper;

    beforeEach(() => {
      const task = {
        appeal: 'b',
        user: 'a'
      };

      wrapper = mount(<EstablishClaim task={task}/>);

      // Force component to Form page
      wrapper.setState({ page: FORM_PAGE });
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

    context('when task is cancelled', () => {
      beforeEach(() => {
        wrapper.find('#button_Cancel').simulate('click');
      });

      it('modal is shown', () => {
        expect(wrapper.find('.cf-modal')).to.have.length(1);
      });

      it('modal can be closed', () => {
        wrapper.find('#button_\u00AB_Go_Back').simulate('click');
        expect(wrapper.find('.cf-modal')).to.have.length(0);
      });
    });
  });
});
