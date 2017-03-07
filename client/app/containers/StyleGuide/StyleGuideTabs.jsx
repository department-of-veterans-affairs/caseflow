import React from 'react';

// components
import TabWindow from '../../components/TabWindow';
// import RenderFunctions from '../../components/RenderFunctions';
import { closeSymbolHtml, missingSymbolHtml } from '../../components/RenderFunctions.jsx';

export const tabIconFunctions = [closeSymbolHtml(), missingSymbolHtml()];

export default class StyleGuideTabs extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      tabText: "HI"
    };

  }

  render() {

    let {
      tabHeaders,
      tabHeadersWithIcons,
      tabPages,
      tabPagesWithIcons
    } = this.props;

    tabHeaders = [
      "Tab 1",
      "Tab 2",
      "Tab 3"
    ];

    tabHeadersWithIcons = [
      " Active Tab",
      "Enabled Tab",
      "Disabled Tab"
    ];

    tabPages = [
      "This is an 'Active' Tab.",
      "This is an 'Enabled' Tab.",
      "This is a 'Disabled' Tab"
    ];

    tabPagesWithIcons = [
      "This tab uses the 'Suggested Questions' icon.",
      "This tab uses the 'All Questions' icon.",
      "This tab uses the 'In Progress' icon.",
      "This tab uses the 'Completed' icon.",
      "This tab uses the 'Errors' icon."
    ];

    return <div>
      <h2 id="tabs">Tabs</h2>
      <h3>Tabs without Icons</h3>
      <p>
        The US Web Design doesn’t include tabs so we’ve designed our own.
        The active tab is highligted with a blue border and blue text.
        Inactive tabs have grey text. Disabled tabs are grey, have faded grey text,
        and cannot be clicked.
      </p>
      <TabWindow
        tabs={tabHeaders}
        pages={tabPages}
        onChange={this.onTabSelected}/>
      <h3>Tabs with Icons</h3>
      <p>
        Icons are optional on tabs and are set by the designer in the mockup.
        These icons come from the Font Awesome package, which is set in the
        U.S. Design standards. Here is an example of tabs with icons:
      </p>
      <TabWindow
        tabs={tabHeadersWithIcons}
        pages={tabPagesWithIcons}
        onChange={this.onTabSelected}/>
    </div>;
  }
}
