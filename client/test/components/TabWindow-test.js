import React from 'react';
import { expect } from 'chai';
import { shallow, mount } from 'enzyme';
import TabWindow from '../../app/components/TabWindow';

describe('TabWindow', () => {
  it('shows two tabs when two tabs are specified', () => {
    const wrapper = shallow(<TabWindow
      tabs={['one', 'two']}
      pages={[<div id="pageOne">page one</div>, <div id="pageTwo">page two</div>]}/>);

    expect(wrapper.find('.cf-tab')).to.have.length(2);
  });

  it('shows page one first, then page two when tab two is clicked', () => {
    const wrapper = mount(<TabWindow
      tabs={['one', 'two']}
      pages={[<div id="pageOne">page one</div>, <div id="pageTwo">page two</div>]}/>);

    expect(wrapper.find('#pageOne')).to.have.length(1);
    expect(wrapper.find('#pageTwo')).to.have.length(0);
    wrapper.find('#tab-1').simulate('click');
    expect(wrapper.find('#pageOne')).to.have.length(0);
    expect(wrapper.find('#pageTwo')).to.have.length(1);
  });

  it('renders full page view if configured so', () => {
    const wrapper = shallow(<TabWindow
      tabs={['one', 'two']}
      pages={[<div id="pageOne">page one</div>, <div id="pageTwo">page two</div>]}
      fullPage={true}/>);

    expect(wrapper.find('.cf-tab-navigation-full-screen')).to.have.length(1);
  });

  it('onChange is fired when tab is switched', () => {
    let tabSelected = null;
    const onChange = (tabNumber) => {
      tabSelected = tabNumber;
    };
    const wrapper = mount(<TabWindow
      tabs={['one', 'two']}
      pages={[<div id="pageOne">page one</div>, <div id="pageTwo">page two</div>]}
      onChange={onChange}/>);

    wrapper.find('#tab-1').simulate('click');
    expect(tabSelected).to.be.eq(1);
  });
});
