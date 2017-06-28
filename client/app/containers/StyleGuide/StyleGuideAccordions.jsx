import React from 'react';
import { Accordion, AccordionItem } from 'react-sanfona';
import StyleGuideComponentTitle from '../../components/StyleGuideComponentTitle';

export default class StyleGuideAccordions extends React.PureComponent {
  render = () => {
    const accordionItemContents = [1, 2, 3, 4, 5].map((item) => {
      return (
        <AccordionItem
          title={`Example title ${item}`}
          slug={item}
          key={item}>
            Millions of Americans interact with government services every day.
            Veterans apply for benefits. Students compare financial aid options.
            Small business owners seek loans. Too often, outdated tools and
            complex systems make these interactions cumbersome and frustrating.
            Enter the United States Digital Service. We partner leading
            technologists with dedicated public servants to improve the usability
            and reliability of our government's most important digital services.
            Visit USDS.gov to learn more.
        </AccordionItem>
      );
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
  <p><b>Technical Notes:</b> The whole accordion is placed in the <code>Accordion</code>
     element while each accordion (header and body) is listed in the <code>AccordionItem</code>
     element. To obtain your desired border style, specify one of the following classnames
     in the <code>className</code> prop of the <code>Accordion</code> element.</p>
    <h3>Bordered</h3>
      <p>className: <code>usa-accordion-bordered</code></p>
      <Accordion className="usa-accordion-bordered">
        {accordionItemContents}
      </Accordion>
    <h3>Borderless</h3>
      <p>className: <code>usa-accordion</code></p>
      <Accordion className="usa-accordion">
        {accordionItemContents}
      </Accordion>
    <h3>Bordered Outline</h3>
      <p>className: <code>usa-accordion-bordered-outline</code></p>
      <Accordion className="usa-accordion-bordered-outline">
        {accordionItemContents}
      </Accordion>
    </div>;
  }
}
