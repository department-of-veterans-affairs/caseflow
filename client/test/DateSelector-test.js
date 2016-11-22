import React from 'react';
import { expect } from 'chai';
import { shallow, mount } from 'enzyme';
import DateSelector from '../app/components/DateSelector';

describe('DateSelector', () => {
  context('.dateFill', () => {
    let type;
    let wrapper;
    let backspace;

    beforeEach(() => {
      wrapper = mount(<DateSelector name='test'/>);
      let input = wrapper.find('input');
      type = function(str) {
        for (let i = 0; i < str.length; i++) {
          let value = wrapper.state().value;
          input.simulate('change', {target: {value: (value + str.charAt(i))}});
        }
      }
      backspace = function() {
        let value = wrapper.state().value;
        input.simulate('change', {target: {value: value.substr(0, value.length - 1)}});
      }
    });
    context('month', () => {
      it('valid', () => {
        type('12');
        expect(wrapper.state().value).to.be.eq('12/');
      });
      it('invalid first digit', () => {
        type('21');
        expect(wrapper.state().value).to.be.eq('1');
      });
      it('invalid character', () => {
        type('a1b1');
        expect(wrapper.state().value).to.be.eq('11/');
      });
      it('adding slash', () => {
        type('09/');
        expect(wrapper.state().value).to.be.eq('09/');
      });
      it('backspacing', () => {
        type('09');
        backspace();
        expect(wrapper.state().value).to.be.eq('0');
      });
    })
    context('date', () => {
      it('valid', () => {
        type('12/11');
        expect(wrapper.state().value).to.be.eq('12/11/');
      });
      it('invalid first digit', () => {
        type('12/41');
        expect(wrapper.state().value).to.be.eq('12/1');
      });
      it('invalid character', () => {
        type('12/a0b8');
        expect(wrapper.state().value).to.be.eq('12/08/');
      });
      it('adding slash', () => {
        type('09/03/');
        expect(wrapper.state().value).to.be.eq('09/03/');
      });
      it('backspacing', () => {
        type('09/12/');
        backspace();
        expect(wrapper.state().value).to.be.eq('09/1');
      });
    })
    context('year', () => {
      it('valid', () => {
        type('12/11/1994');
        expect(wrapper.state().value).to.be.eq('12/11/1994');
      });
      it('invalid character', () => {
        type('12/01/a1b9c9d1');
        expect(wrapper.state().value).to.be.eq('12/01/1991');
      });
    })
  });
});
