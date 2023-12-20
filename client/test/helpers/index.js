// This lil' bundle o' joy is a workaround for an Enzyme bug.
// The Enzyme full renderer produces a structure like:
//
//  <Button id="foo">
//    <button id="foo">
//
// In the example above, we have a React component with an id set as a prop,
// and a child DOM element with the same id set as an attribute. If we do a
// simple wrapper.find('#foo'), enzyme will return both elements, and then
// complain when we call methods that assume only one element was found.
//
// To work around this, we manually find the element that's an actual DOM node,
// and not a React element.
export const findElementById = (wrapper, id) => wrapper.find({ id }).hostNodes();
