let highPriorityPageArray = [];
let lowPriorityPageArray = [];

let currentlyRenderingPages = [];

const getNextPage = () => highPriorityPageArray.pop() || lowPriorityPageArray.pop();

const renderNextPage = () => {
  const completeRender = (page) => {
    currentlyRenderingPages = currentlyRenderingPages.filter((item) => item.pageIndex !== page.pageIndex || item.file !== page.file );
    // console.log("COMPLETE RENDER", page, currentlyRenderingPages);
    renderNextPage();
  };

  if (currentlyRenderingPages.length >= 4) {
    return;
  }

  const page = getNextPage();

  // console.log(page);
  if (page) {
    const renderTask = page.page.render(page.options);

    currentlyRenderingPages.push({
      ...page,
      renderTask
    });

    // console.log('currentlyRenderingPages', currentlyRenderingPages);
    const t0 = performance.now();

    renderTask.then(() => {
      page.resolve();
      console.log('time to render', performance.now() - t0);
      completeRender(page);
    }, () => {
      page.reject();
      completeRender(page);
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
  // console.log("pageindex", pageIndex, "PRIORITY CHANGED", priority);
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
  const currentlyRenderingPage = currentlyRenderingPages.find((page) => pageIndex === page.pageIndex && file === page.file);

  if (currentlyRenderingPage) {
    // console.log("pageindex", pageIndex, "TOTALLY CANCELLED");
    currentlyRenderingPage.renderTask.cancel();
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
