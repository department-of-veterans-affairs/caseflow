import React from 'react';
import { expect } from 'chai';
import { shallow, mount } from 'enzyme';
import Button from '../../app/components/Button';

describe('Button', () => {
  it('renders loading icon instead of button when loading', () => {
    let onChange = () => true;
    const wrapper = shallow(<Button
                              id="test-button"
                              classNames={['usa-button-primary']}
                              name="foo"
                              onChange={onChange}
                              loading={true} />);

    expect(wrapper.find('.usa-button-primary')).to.have.length(0);
    expect(wrapper.find('#test-button')).to.have.length(0);
    expect(wrapper.find('.cf-react-loading-indicator')).to.have.length(1);
  });

  it('removes other button classes when disabled', () => {
    let onChange = () => true;
    const wrapper = shallow(<Button
                              name="foo"
                              onChange={onChange}
                              classNames={["usa-button-primary"]}
                              disabled={true} />);

    expect(wrapper.find('.usa-button-disabled')).to.have.length(1);
    expect(wrapper.find('.usa-button-primary')).to.have.length(0);
  });

  it('renders while not loading', () => {
    let onChange = () => true;
    const wrapper = shallow(<Button name="foo" onChange={onChange} loading={false} />);

    expect(wrapper.find('button')).to.have.length(1);
  });

  it('calls the on change function', () => {
    let isCalled = false;
    let onClick = () => {
      isCalled = true;
    };
    let wrapper;

    wrapper = mount(<Button name="foo" onClick={onClick} loading={false} />);
    wrapper.find('button').simulate('click');
    expect(isCalled).to.be.eq(true);
  });
});
