import React from 'react';
import Collapse, { Panel } from 'rc-collapse';
import StyleGuideComponentTitle from '../../components/StyleGuideComponentTitle';

export default class StyleGuideAccordions extends React.Component {
  render = () => {
    let headerNumber = [1,2,3,4,5];
    let accordionText = <p>
      Millions of Americans interact with government services every day.
      Veterans apply for benefits. Students compare financial aid options.
      Small business owners seek loans. Too often, outdated tools and complex
      systems make these interactions cumbersome and frustrating. Enter the
      United States Digital Service. We partner leading technologists with
      dedicated public servants to improve the usability and reliability of
      our government's most important digital services.
      Visit USDS.gov to learn more.
    </p>

    return <div>
    <StyleGuideComponentTitle
      title="Accordions"
      id="accordions"
      link="StyleGuideAccordions.jsx"
    />
  <p>Our accordion style was taken from the US Web Design Standards.
    Accordions are a list of headers that can be clicked to hide or reveal additional
    content.</p>
    <h3>Border</h3>
      <Collapse accordion={true} className="usa-accordion-bordered">
        {headerNumber.map((header) => {
          return (<Panel header={"Example title " + header} headerClass="usa-accordion-button" key={header}>
            <div className="usa-accordion-content">
              {accordionText}
            </div>
          </Panel>)
        })}
      </Collapse>

    <h3>Borderless</h3>
      <Collapse accordion={true} className="usa-accordion">
        {headerNumber.map((header) => {
          return (<Panel header={"Example title " + header} headerClass="usa-accordion-button" key={header}>
            <div className="usa-accordion-content">
              {accordionText}
            </div>
          </Panel>)
        })}
      </Collapse>

    <h3>Border with Outline</h3>
      <Collapse accordion={true} className="usa-accordion-bordered-outline">
        {headerNumber.map((header) => {
          return (<Panel header={"Example title " + header} headerClass="usa-accordion-button" key={header}>
            <div className="usa-accordion-content">
              {accordionText}
            </div>
          </Panel>)
        })}
      </Collapse>
    </div>;
  }
}
