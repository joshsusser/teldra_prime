
// Register for onload
window.onload = startGui;


// Globals

var converter;
var convertTextTimer, processingTime;
var lastText, lastRoomLeft;
var inputAuthor, inputPane, previewDiv, previewAuthor, previewPane, previewButton;
var maxDelay = 3000; // longest update pause (in ms)


//  Initialization

function startGui() {
  // find elements
  inputAuthor = document.getElementById("comment_author_name");
  inputPane = document.getElementById("comment_tofu");
  previewDiv = document.getElementById("preview");
  previewAuthor = document.getElementById("comment_preview_author");
  previewPane = document.getElementById("comment_preview_body");
  previewButton = document.getElementById("preview_button");

  // // set event handlers
  previewButton.onclick = onPreviewButtonClicked;

  // build the converter
  converter = new Showdown.converter();
}

//  Conversion

function convertText() {
  // get input text
  var text = inputPane.value;
  
  // if there's no change to input, cancel conversion
  if (text && text == lastText) {
    return;
  } else {
    lastText = text;
  }

  // Do the conversion
  text = converter.makeHtml(text);

  // update preview pane
  previewPane.innerHTML = text;
};


//  Event handlers

function onPreviewButtonClicked() {
  // hack: force the converter to run
  lastText = "";

  previewAuthor.innerHTML = inputAuthor.value;
  convertText();
  previewDiv.style.display = "block";
  
  inputPane.focus();
}
