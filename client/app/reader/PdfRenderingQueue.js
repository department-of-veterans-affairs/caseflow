let highPriorityPageArray = [];
let lowPriorityPageArray = [];

let currentlyRenderingPage = null;
let renderTask = null;

const getNextPage = () => highPriorityPageArray.pop() || lowPriorityPageArray.pop();

const renderNextPage = () => {
  const completeRender = () => {
    currentlyRenderingPage = null;
    renderNextPage();
  };

  if (currentlyRenderingPage) {
    return;
  }

  const page = getNextPage();
  console.log(page);
  if (page) {
    currentlyRenderingPage = page;

    renderTask = page.page.render(page.options);
    renderTask.then(() => {
      page.resolve();
      completeRender();
    }, () => {
      page.reject();
      completeRender();
    });
  }
};

const removePageFromQueues = ({ pageIndex, file }) => {
  highPriorityPageArray = highPriorityPageArray.filter(
    (page) => page.pageIndex !== pageIndex || page.file !== file);
  lowPriorityPageArray = lowPriorityPageArray.filter(
    (page) => page.pageIndex !== pageIndex || page.file !== file);
};

export const changePriority = ({ pageIndex, file, priority }) => {
  console.log("pageindex", pageIndex, "PRIORITY CHANGED", priority);
  const pageToChange = [...highPriorityPageArray, ...lowPriorityPageArray].find(
    (page) => page.pageIndex === pageIndex && page.file === file);

  if (pageToChange) {
    removePageFromQueues({
      pageIndex,
      file
    });

    if (priority) {
      highPriorityPageArray.push(pageToChange);
    } else {
      lowPriorityPageArray.push(pageToChange);
    }
  }
};

export const removePageFromRenderQueue = ({ pageIndex, file }) => {
  if (renderTask && currentlyRenderingPage && pageIndex === currentlyRenderingPage.pageIndex && file === currentlyRenderingPage.file) {
    console.log("pageindex", pageIndex, "TOTALLY CANCELLED");
    renderTask.cancel();
  }
  removePageFromQueues({
    pageIndex,
    file
  });
};

export const addPageToRenderQueue = ({ page, options, pageIndex, file, priority }) => {
  return new Promise((resolve, reject) => {
    const params = {
      page,
      options,
      pageIndex,
      file,
      resolve,
      reject
    };

    if (priority) {
      highPriorityPageArray.push(params);
    } else {
      lowPriorityPageArray.push(params);
    }

    renderNextPage();
  });
};
