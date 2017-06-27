import React from 'react';
import Collapse, { Panel } from 'rc-collapse';
import StyleGuideComponentTitle from '../../components/StyleGuideComponentTitle';

export default class StyleGuideAccordions extends React.Component {
  render = () => {
    const headerNumber = [1, 2, 3, 4, 5];

    const accordionText = <p>
      Millions of Americans interact with government services every day.
      Veterans apply for benefits. Students compare financial aid options.
      Small business owners seek loans. Too often, outdated tools and complex
      systems make these interactions cumbersome and frustrating. Enter the
      United States Digital Service. We partner leading technologists with
      dedicated public servants to improve the usability and reliability of
      our government's most important digital services.
      Visit USDS.gov to learn more.
    </p>;

    const headerPanels = headerNumber.map((header) => {
      return (<Panel header={`Example title ${header}`} headerClass="usa-accordion-button" key={header}>
        <div className="usa-accordion-content">
          {accordionText}
        </div>
      </Panel>);
    });

    return <div>
    <StyleGuideComponentTitle
      title="Accordions"
      id="accordions"
      link="StyleGuideAccordions.jsx"
    />
  <p>Our accordion style was taken from the US Web Design Standards.
    Accordions are a list of headers that can be clicked to hide or reveal additional
    content.</p>
  <p><b>Technical Notes:</b> The whole accordion is placed in the <code>Collapse</code>
    element while each accordion (header and body) is listed in the <code>Panel</code>
    element. To obtain your desired border style, specify one of the following classnames
    in the <code>className</code> prop of the <code>Collapse</code> element.</p>
    <h3>Border</h3>
      <p>className: <code>usa-accordion-bordered</code></p>
      <Collapse accordion={true} className="usa-accordion-bordered">
        {headerPanels}
      </Collapse>

    <h3>Borderless</h3>
      <p>className: <code>usa-accordion</code></p>
      <Collapse accordion={true} className="usa-accordion">
        {headerPanels}
      </Collapse>

    <h3>Border with Outline</h3>
      <p>className: <code>usa-accordion-bordered-outline</code></p>
      <Collapse accordion={true} className="usa-accordion-bordered-outline">
        {headerPanels}
      </Collapse>
    </div>;
  }
}
