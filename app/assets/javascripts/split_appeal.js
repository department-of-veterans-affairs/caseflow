// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.

let splitpost = new XMLHttpRequest();

splitpost.setRequestHeader("Accept", "application/json");
splitpost.setRequestHeader("Content-Type", "application/json");

splitpost.onload = () => console.log(splitpost.responseText);

let data = [orignalappeal, splitappeal, appealcomment]

splitpost.send(data).window.open(data)
;

//
//let xhr = new XMLHttpRequest();
//xhr.open("POST", "https://reqbin.com/echo/post/json");

//xhr.setRequestHeader("Accept", "application/json");
//xhr.setRequestHeader("Content-Type", "application/json");

//xhr.onload = () => console.log(xhr.responseText);

//let data = `{
  //"Id": 78912,
  //"Customer": "Jason Sweet",
//}`;