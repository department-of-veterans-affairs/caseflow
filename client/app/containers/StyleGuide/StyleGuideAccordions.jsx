import React from 'react';
import { Accordion, AccordionItem } from 'react-sanfona';
import StyleGuideComponentTitle from '../../components/StyleGuideComponentTitle';

export default class StyleGuideAccordions extends React.Component {
  render = () => {
    return <div>
    <StyleGuideComponentTitle
      title="Accordions"
      id="accordions"
      link="StyleGuideAccordions.jsx"
    />
  <p>Our accordion style was taken from the US Web Design Standards.
    Accordions are a list of headers that can be clicked to hide or reveal additional
    content.</p>
    <Accordion>
  				{[1, 2, 3, 4, 5].map((item) => {
  					return (
  						<AccordionItem title={`Item ${ item }`} slug={item} key={item}>
  							<div>
  								{`Item ${ item } content`}
  								{item === 3 ? <p><img src="https://cloud.githubusercontent.com/assets/38787/8015584/2883817e-0bda-11e5-9662-b7daf40e8c27.gif" /></p> : null}
  							</div>
  						</AccordionItem>
  					);
  				})}
  			</Accordion>
    </div>;
  }
}
