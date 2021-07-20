//= require vis-timeline/dist/vis-timeline-graph2d.min.js
// Example timeline visualizations: https://visjs.github.io/vis-timeline/examples/timeline/

/**
 * Support code for app/views/explain/show.html.erb,
 * associated with app/controllers/explain_controller.rb.
 * Also see accompanying app/assets/stylesheets/explain_appeal.css.
 * These are added to the application in config/initializers/assets.rb.
 */

const items = new vis.DataSet();

// called from app/views/explain/show.html.erb
function addTimeline(elementId, timeline_data){
  items.add(decorateTimelineItems(timeline_data));
  const startDates = items.get({fields: ['start']}).map((str)=> new Date(str.start));
  const endDates = items.get({fields: ['end']}).map((str)=> new Date(str.end));
  const millisInAMonth = 1000*60*60*24*30 // an approximate month in milliseconds
  const timeline_options = {
    width: '95%',
    // maxHeight: 800,
    horizontalScroll: true,
    verticalScroll: true,
    min: new Date(Math.min(...startDates) - millisInAMonth*6), // add extra time so that entire label is visible
    max: new Date(Math.min(Math.max(...endDates), new Date()) + millisInAMonth*12), // add exta time so that labels are visible
    zoomMin: 1000 * 60 * 60, // 1 hour in milliseconds
    orientation: {axis: 'both'},  // show time axis on both the top and bottom
    stack: true,
    zoomKey: 'ctrlKey',
    order: (a, b) => b.record.id - a.record.id,
    tooltip: {
      followMouse: true
    }
  };
  const timelineElement = document.getElementById(elementId);
  const groups = groupEventItems(timeline_data);

  return new vis.Timeline(timelineElement, items, groups, timeline_options);
}

const itemDecoration = {
  tasks: {
    className: (item)=> item.className + " task_" + item.status
  },
  hearings: {
    className: (item)=> item.className + " hearing_" + item.status
  }
};

const formatJson = (obj) => {
  return JSON.stringify(obj, null, ' ').
    replace('{\n', '').
    replace('\n}', '');
};

// https://visjs.github.io/vis-timeline/docs/timeline/#items
function decorateTimelineItems(items){
  items.forEach(item => {
    item.className = item.record_type;

    if(itemDecoration.hasOwnProperty(item.table_name)){
      for ([key, value] of Object.entries(itemDecoration[item.table_name])) {
        item[key] = (typeof value === 'function') ? value(item) : value;
      }
    }

    // `item.title` is displayed as the tooltip
    if(!item.title){
      item.title = "<pre class='event_detail'>"+formatJson(item.record)+"</pre>";
    }
  });
  return items;
}

// https://visjs.github.io/vis-timeline/docs/timeline/#groups
var groups = new vis.DataSet();
function groupEventItems(items){
  groups.add({
      id: 'phase',
      content: 'phases',
      className: 'group_phase',
      order: 0,
  });
  groups.add({
      id: 'tasks',
      content: 'tasks',
      className: 'group_tasks',
      order: 1,
  });
  groups.add({
    id: 'cancelled_tasks',
    content: 'cancelled<br/> tasks',
    className: 'group_cancelled_tasks',
    order: 3,
  });
  groups.add({
    id: 'others',
    content: 'others',
    className: 'group_others',
    order: 9,
  });
  return groups;
}

function toggleTimelineEventGroup(checkbox, group_id){
  groups.update({id: group_id, visible: checkbox.checked});
}
