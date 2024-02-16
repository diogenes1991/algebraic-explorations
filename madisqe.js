// utilities
var get = function (selector, scope) {
    scope = scope ? scope : document;
    return scope.querySelector(selector);
};

var getAll = function (selector, scope) {
    scope = scope ? scope : document;
    return scope.querySelectorAll(selector);
};


// This is our terminal window

if (document.getElementsByClassName('terminal').length > 0) {
    
    var speed = 60;
    var delay = 80;
    var terminals = document.getElementsByClassName('terminal');
    
    for (var i = 0; i < terminals.length; i++) {
        var cmd = terminals[i].innerHTML;
        terminals[i].innerHTML = '';
        setTimeout(typeItOut,delay,0,i,cmd);
    }
    
    function typeItOut(i,j,cmd){
        if (i < cmd.length){
            terminals[j].innerHTML += cmd.charAt(i);
            i++;
            setTimeout(typeItOut,speed,i,j,cmd);
        }
    }
    
}

// toggle tabs on codeblock
window.addEventListener("load", function() {
  // get all tab_containers in the document
  var tabContainers = getAll(".tab__container");

  // bind click event to each tab container
  for (var i = 0; i < tabContainers.length; i++) {
    get('.tab__menu', tabContainers[i]).addEventListener("click", tabClick);
  }

  // each click event is scoped to the tab_container
  function tabClick (event) {
    var scope = event.currentTarget.parentNode;
    var clickedTab = event.target;
    var tabs = getAll('.tab', scope);
    var panes = getAll('.tab__pane', scope);
    var activePane = get(`.${clickedTab.getAttribute('data-tab')}`, scope);

    // remove all active tab classes
    for (var i = 0; i < tabs.length; i++) {
      tabs[i].classList.remove('active');
    }

    // remove all active pane classes
    for (var i = 0; i < panes.length; i++) {
      panes[i].classList.remove('active');
    }

    // apply active classes on desired tab and pane
    clickedTab.classList.add('active');
    activePane.classList.add('active');
  }
});

//in page scrolling for documentaiton page
var btns = getAll('.js-btn');
var sections = getAll('.js-section');

function setActiveLink(event) {
  // remove all active tab classes
  for (var i = 0; i < btns.length; i++) {
    btns[i].classList.remove('selected');
  }

  event.target.classList.add('selected');
}

function smoothScrollTo(i, event) {
  var element = sections[i];
  setActiveLink(event);

  window.scrollTo({
    'behavior': 'smooth',
    'top': element.offsetTop - 20,
    'left': 0
  });
}

if (btns.length && sections.length > 0) {
  for (var i = 0; i<btns.length; i++) {
    btns[i].addEventListener('click', smoothScrollTo.bind(this,i));
  }
}

// fix menu to page-top once user starts scrolling
window.addEventListener('scroll', function () {
  var docNav = get('.doc__nav > ul');

  if( docNav) {
    if (window.pageYOffset > 63) {
      docNav.classList.add('fixed');
    } else {
      docNav.classList.remove('fixed');
    }
  }
});

// responsive navigation
var topNav = get('.menu');
var icon = get('.toggle');

window.addEventListener('load', function(){
  function showNav() {
    if (topNav.className === 'menu') {
      topNav.className += ' responsive';
      icon.className += ' open';
    } else {
      topNav.className = 'menu';
      icon.classList.remove('open');
    }
  }
  icon.addEventListener('click', showNav);
});


class Parser {
    constructor(source) {
      this.source = source;
    }

    Parse(){
        let Reader = new FileReader();
        // var File = this.source.target.files[0];
        if (!File) {
            return;
        }

        console.log(this.source);
        // window.open(this.source);

        return 'Hello';

    }
}

function LoadFile() {
    var ThisElement = document.getElementById("Python-Source");
    var strRawContents = ThisElement.innerHTML;
    // var strRawContents = oFrame.contentWindow.document.body.childNodes[0].innerHTML;
    while (strRawContents.indexOf("\r") >= 0)
        strRawContents = strRawContents.replace("\r", "");
    var arrLines = strRawContents.split("\n");
    for (var i = 0; i < arrLines.length; i++) {
        var curLine = arrLines[i];
        // console.log("Line #" + (i + 1) + " is: '" + curLine + "'");
    }
}


// document.getElementsByClassName('RawFile').addEventListener('change',function(){
//     var Content = readTextFile(this.name);
//     document.getElementsByClassName('RawOut')[0].innerHTML = Content;
// })

// function readSingleFile(e) {
//   var file = e.target.files[0];
//   if (!file) {
//     return;
//   }
//   var reader = new FileReader();
//   reader.onload = function(e) {
//     var contents = e.target.result;
//     // Display file content
//     displayContents(contents);
//   };
//   reader.readAsText(file);
// }
 
// function displayContents(contents) {
//     var element = document.getElementById('file-content');
//     element.innerHTML = contents;
// }
 
// if (document.getElementsByClassName('File').length>0){

//     var source = document.getElementsByClassName('File')[0];
//     var SourceParser = new Parser(source);
//     source.innerHTML = SourceParser.Parse();


// document.addEventListener('DOMContentLoaded', function() {
//     var sep = '\uE000'; // an unusual char: unicode 'Private Use, First'
    
//     window.addEventListener('pagehide', function(e) {
//         window.name += sep + window.pageXOffset + sep + window.pageYOffset;
//     });
    
//     if(window.name && window.name.indexOf(sep) > -1){
//         var parts = window.name.split(sep);
//         if(parts.length >= 3){
//             window.name = parts[0];
//             window.scrollTo(parseFloat(parts[parts.length - 2]), parseFloat(parts[parts.length - 1]));
//         }
//     }
// });

// }
