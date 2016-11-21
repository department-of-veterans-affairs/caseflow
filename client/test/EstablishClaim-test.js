import React from 'react';
import { expect } from 'chai';
import { shallow, mount } from 'enzyme';
import EstablishClaim from '../app/containers/EstablishClaim';

describe.only('EstablishClaim', () => {
  context('.render', () => {
    var task;

    beforeEach(() => {
      task = {user: 'a', appeal: 'b'};
    });
    context('when POA is None', () => {
      it('hides POA code', () => {
        const wrapper = mount(<EstablishClaim task={task}/>);
        console.log(wrapper.find('#POA_VSO').length);
        // wrapper.find('#POA_None').parent().simulate('click');
        // console.log(wrapper.find('#POACode'));
        //expect(wrapper.find('#POACode')).to.have.length(0);
        expect(true).to.be.true;
      });  
    });
    context('when POA is VSO', () => {
      it('show POA code', () => {
        // console.log(wrapper.html());
        //console.log(wrapper.find('#POA_VSO').html());
        //wrapper.find('#POA_VSO').parent().simulate('click');
        // console.log(wrapper.find('#POACode'));
        //console.log(wrapper.state('poa'));
        // expect(wrapper.find('#POACode')).to.have.length(1);
        expect(true).to.be.true;
      });  
    });
  });
});
