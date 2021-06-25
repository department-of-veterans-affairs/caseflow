//= require vis-timeline/dist/vis-timeline-graph2d.min.js
// Example timeline visualizations: https://visjs.github.io/vis-timeline/examples/timeline/

/**
 * Support code for app/views/explain/show.html.erb,
 * associated with app/controllers/explain_controller.rb.
 * Also see accompanying app/assets/stylesheets/explain_appeal.css.
 * These are added to the application in config/initializers/assets.rb.
 */

// called from app/views/explain/show.html.erb
function addTimeline(elementId, timeline_data){
  const timelineElement = document.getElementById(elementId);
  const items = new vis.DataSet(decorateTimelineItems(timeline_data));
  const groups = groupEventItems(timeline_data);
  const timeline_options = {
    width: '95%',
    maxHeight: 800,
    horizontalScroll: true,
    verticalScroll: true,
    min: new Date(2018, 0, 1), // TODO: calculate earliest
    max: new Date((new Date()).valueOf() + 1000*60*60*24*30*12), // add exta time so that labels are visible
    zoomMin: 1000 * 60 * 60, // 1 hour in milliseconds
    orientation: {axis: 'both'},  // show time axis on both the top and bottom
    stack: true,
    zoomKey: 'ctrlKey',
    order: (a, b) => b.record_id - a.record_id,
    tooltip: {
      followMouse: true
    }
  };
  return new vis.Timeline(timelineElement, items, groups, timeline_options);
}

const taskNodeColor = {
  assigned: "#00dd00",
  in_progress: "#00ff00",
  on_hold: "#cccc00",
  cancelled: "#8a8",
  completed: "#00bb00"
}

const itemDecoration = {
  tasks: { style: (item)=>"OLD-background-color: "+taskNodeColor[item.status] }
};

// https://visjs.github.io/vis-timeline/docs/timeline/#items
function decorateTimelineItems(items){
  items.forEach(item => {
    if(!itemDecoration.hasOwnProperty(item.tableName)) return;
    for ([key, value] of Object.entries(itemDecoration[item.tableName])) {
      if (typeof value === 'function') {
        value = value(item)
      }
      item[key] = value
    }
  });
  // console.log(items)
  return items;
}

// https://visjs.github.io/vis-timeline/docs/timeline/#groups
function groupEventItems(items){
  var groups = new vis.DataSet();
  // TODO: add checkboxes to set 'visible' value on groups
  groups.add({
      id: 0,
      content: 'phase',
      className: 'group_phase',
      order: 0,
      visible: true
  });
  groups.add({
      id: 1,
      content: 'tasks',
      className: 'group_tasks',
      order: 1,
  });
  groups.add({
    id: 2,
    content: 'intakes',
    className: 'group_intakes',
    order: 2,
  });
return groups;
}
