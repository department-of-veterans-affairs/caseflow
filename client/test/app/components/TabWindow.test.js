import React from 'react';
import TabWindow from 'app/components/TabWindow';
import { shallow, mount } from 'enzyme';
import { tabList } from 'test/data';

/* eslint-disable dot-location */
describe('TabWindow', () => {
  test('Matches snapshot with default props', () => {
    // Set the component
    const tabs = mount(<TabWindow tabs={tabList} />);

    expect(tabs).toMatchSnapshot();

    // We now expect just one child (the <Tabs> component)
    expect(tabs.children()).toHaveLength(1);

    // Expect the tab navigation to contain both tabs
    expect(tabs.find('.cf-tab-navigation').children()).toHaveLength(2);
    expect(
      tabs
        .find('.cf-tab-navigation')
        .childAt(0)
        .find('button')
        .hasClass('cf-active')
    ).toEqual(true);
    expect(
      tabs
        .find('.cf-tab-navigation')
        .childAt(0)
        .find('button')
        .prop('aria-selected')
    ).toEqual(true);
  });

  test('Renders an empty div when no tabs are passed', () => {
    // Set the component
    const tabs = shallow(<TabWindow />);

    // Snapshot matcher
    expect(tabs).toMatchSnapshot();
    expect(tabs.children().exists()).toEqual(false);
  });

  test('Renders full page when the `fullPage` prop is true', () => {
    // Set the component
    const tabs = mount(<TabWindow fullPage tabs={tabList} />);

    // Snapshot matcher
    expect(tabs).toMatchSnapshot();
    expect(tabs.find('.cf-tab-navigation-full-screen').exists()).toEqual(true);
  });

  test('Renders tab content when a tab is selected', () => {
    // Set the component
    const tabs = mount(<TabWindow fullPage tabs={tabList} />);

    // Run the test
    tabs.find('#main-tab-1').simulate('click');

    // Snapshot matcher
    expect(tabs).toMatchSnapshot();
    expect(
      tabs
        .find('.cf-tab-navigation')
        .childAt(1)
        .find('button')
        .hasClass('cf-active')
    ).toEqual(true);
    expect(
      tabs
        .find('.cf-tab-navigation')
        .childAt(1)
        .find('button')
        .prop('aria-selected')
    ).toEqual(true);
  });

  test('Does not render tab content when a tab is disabled and clicked', () => {
    // Set the component
    const tabs = mount(
      <TabWindow
        fullPage
        tabs={[
          tabList[0],
          {
            ...tabList[1],
            disable: true,
          },
        ]}
      />
    );

    // Run the test
    tabs.find('#main-tab-1').simulate('click');

    // Snapshot matcher
    expect(tabs).toMatchSnapshot();
    expect(
      tabs
        .find('.cf-tab-navigation')
        .childAt(1)
        .find('button')
        .hasClass('cf-active')
    ).toEqual(false);
    expect(
      tabs
        .find('.cf-tab-navigation')
        .childAt(1)
        .find('button')
        .prop('aria-selected')
    ).toEqual(false);
  });

  test('calls onChange when tab changes', () => {
    const onChange = jest.fn();

    // Set the component
    const tabs = mount(<TabWindow onChange={onChange} tabs={tabList} />);

    // Run the test
    tabs.find('#main-tab-1').simulate('click');
    expect(onChange).toHaveBeenCalledWith(1);
  });

  test('renders tabs with one tab if alwaysShowTabs is true', () => {
    const tabs = mount(
      <TabWindow
        tabs={[tabList[0]]}
        alwaysShowTabs
      />
    );

    expect(tabs.find('button.cf-tab')).toHaveLength(1);
  });
});
/* eslint-enable dot-location */
