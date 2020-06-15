import React from 'react';
import TabWindow from 'app/components/TabWindow';
import { shallow, mount } from 'enzyme';
import { tabList } from 'test/data';

const TabPanel = ({ content }) => (
  <div className="cf-tab-window-body-full-screen" id="tab-panel-container" role="tabpanel">
    {content}
  </div>
);

describe('TabWindow', () => {
  test('Matches snapshot with default props', () => {
    // Set the component
    const tabs = shallow(<TabWindow tabs={tabList} />);

    expect(tabs).toMatchSnapshot();
    expect(tabs.containsMatchingElement(TabPanel({ content: 'Content' }))).toEqual(true);

    // Expect 1 child for tab navigation and 1 for tab content
    expect(tabs.children()).toHaveLength(2);

    // Expect the tab navigation to contain both tabs
    expect(tabs.find('.cf-tab-navigation').children()).toHaveLength(2);
    expect(
      tabs.
        find('.cf-tab-navigation').
        childAt(0).
        hasClass('cf-active')
    ).toEqual(true);
    expect(
      tabs.
        find('.cf-tab-navigation').
        childAt(0).
        prop('aria-selected')
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
    const tabs = shallow(<TabWindow fullPage tabs={tabList} />);

    // Snapshot matcher
    expect(tabs).toMatchSnapshot();
    expect(tabs.find('.cf-tab-navigation-full-screen').exists()).toEqual(true);
  });

  test('Renders tab content when a tab is selected', () => {
    // Set the component
    const tabs = shallow(<TabWindow fullPage tabs={tabList} />);

    // Run the test
    tabs.find('#main-tab-1').simulate('click');

    // Snapshot matcher
    expect(tabs).toMatchSnapshot();
    expect(tabs.containsMatchingElement(TabPanel({ content: 'Some other content' }))).toEqual(true);
    expect(
      tabs.
        find('.cf-tab-navigation').
        childAt(1).
        hasClass('cf-active')
    ).toEqual(true);
    expect(
      tabs.
        find('.cf-tab-navigation').
        childAt(1).
        prop('aria-selected')
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
            disable: true
          }
        ]}
      />
    );

    // Run the test
    tabs.find('#main-tab-1').simulate('click');

    // Snapshot matcher
    expect(tabs).toMatchSnapshot();
    expect(tabs.containsMatchingElement(TabPanel({ content: 'Some other content' }))).toEqual(false);
    expect(
      tabs.
        find('.cf-tab-navigation').
        childAt(1).
        hasClass('cf-active')
    ).toEqual(false);
    expect(
      tabs.
        find('.cf-tab-navigation').
        childAt(1).
        prop('aria-selected')
    ).toEqual(false);
  });

  describe('Class methods', () => {
    let instance;

    beforeEach(() => {
      const tabs = shallow(<TabWindow tabs={tabList} />);

      instance = tabs.instance();
      jest.spyOn(instance, 'onTabClick');
      jest.spyOn(instance, 'setState');
      jest.spyOn(instance, 'getTabHeaderWithSVG');
    });

    afterEach(() => {
      jest.restoreAllMocks();
    });

    test('function onTabClick(tabNumber) sets currentPage in state', () => {
      // Setup the test
      const click = instance.onTabClick(1);

      // Run the test
      click();

      // Assertions
      expect(instance.setState).toHaveBeenCalledWith({ currentPage: 1 });
    });

    test('function onTabClick(tabNumber) calls onChange when set', () => {
      // Setup the test
      const changeMock = jest.fn();
      const tabs = shallow(<TabWindow onChange={changeMock} tabs={tabList} />);

      instance = tabs.instance();
      jest.spyOn(instance, 'onTabClick');
      jest.spyOn(instance, 'setState');
      const click = instance.onTabClick(1);

      // Run the test
      click();

      // Assertions
      expect(instance.setState).toHaveBeenCalledWith({ currentPage: 1 });
      expect(changeMock).toHaveBeenCalledWith(1);
    });

    test('function getTabHeaderWithSVG(tab) returns Tab Header with icon when present', () => {
      // Setup the test
      const Header = shallow(
        instance.getTabHeaderWithSVG({
          ...tabList[0],
          icon: 'TestIcon'
        })
      );

      // Assertions
      expect(Header).toMatchSnapshot();
      expect(Header.children().contains('TestIcon')).toEqual(true);
      expect(Header.children().contains('Tab 1')).toEqual(true);
    });

    test('function getTabHeaderWithSVG(tab) returns Tab Header with indicator when present', () => {
      // Setup the test
      const Header = shallow(
        instance.getTabHeaderWithSVG({
          ...tabList[0],
          indicator: 'TestIndicator'
        })
      );

      // Assertions
      expect(Header).toMatchSnapshot();
      expect(Header.children().contains('TestIndicator')).toEqual(true);
      expect(Header.children().contains('Tab 1')).toEqual(true);
    });

    test('function getTabHeaderWithSVG(tab) returns Tab Header with no icon or indicator when not passed', () => {
      // Setup the test
      const Header = shallow(instance.getTabHeaderWithSVG(tabList[0]));

      // Assertions
      expect(Header).toMatchSnapshot();
      expect(Header.children().contains('Tab 1')).toEqual(true);
    });

    test('function getTabHeader(tab) returns the formatted tab header label', () => {
      // Run the test
      const label = instance.getTabHeader(tabList[0]);

      // Assertions
      expect(label).toEqual('Tab 1 tab window');
    });

    test('function getTabClassName(index, currentPage, isTabDisabled) returns active class when tab is active', () => {
      // Run the test
      const className = instance.getTabClassName(0, 0, false);

      // Assertions
      expect(className).toEqual('cf-tab cf-active');
    });

    test('function getTabClassName(index, currentPage, isTabDisabled) returns disabled class when tab is disabled', () => {
      // Run the test
      const className = instance.getTabClassName(0, 1, true);

      // Assertions
      expect(className).toEqual('cf-tab disabled');
    });

    test('function getTabClassName(index, currentPage, isTabDisabled) returns default classes when not active or disabled', () => {
      // Run the test
      const className = instance.getTabClassName(0, 1, false);

      // Assertions
      expect(className).toEqual('cf-tab');
    });

    test('function getTabGroupName(name) returns main when name is not present', () => {
      // Run the test
      const groupName = instance.getTabGroupName();

      // Assertions
      expect(groupName).toEqual('main');
    });

    test('function getTabGroupName(name) returns name when name is present', () => {
      // Run the test
      const groupName = instance.getTabGroupName('test');

      // Assertions
      expect(groupName).toEqual('test');
    });
  });
});
