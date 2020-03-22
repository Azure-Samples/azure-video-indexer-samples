(function(){
  var baseInsightsUrl = "https://www.videoindexer.ai/embed/insights/";
  var basePlayerInsightsUrl = "https://www.videoindexer.ai/embed/player/";
  var videoIdInput = $("#videoId");
  var accountIdInput = $("#accountId");
  var insightsInputs = $(".insights");
  var titleEl = $('input[name="title"]');
  var generatedInsightsUrlEl = $("#generatedInsightsUrl");
  var generatedPlayerInsightsUrlEl = $("#generatedPlayerUrl");
  var insightsWidgetUrlParams = {};
  var playerInsightsWidgetUrlParams = {autoplay:false};
  var widgetsToRender = [];
  var allWidgets = $('input[name="all"]');
  var captionsCheckbox = $("#captions");
  var autoplayCheckbox = $("#autoplay");
  var langSelect = $("#lang");
  
  // Register listeners
  titleEl.on("keyup", modifyInsightsUrl);
  insightsInputs.on("change", modifyInsightsUrl);
  allWidgets.on("change", toggleUncheckAll);
  captionsCheckbox.on("change", modifyPlayerUrl);
  autoplayCheckbox.on("change", modifyPlayerUrl);
  langSelect.on("change",modifyPlayerUrl);
  videoIdInput.on("keyup", function() {
    var id  = videoIdInput.val();
    var accountId  = accountIdInput.val();
    generateUrlFromParams(insightsWidgetUrlParams, baseInsightsUrl, generatedInsightsUrlEl, accountId, id);
    generateUrlFromParams(playerInsightsWidgetUrlParams, basePlayerInsightsUrl, generatedPlayerInsightsUrlEl, accountId, id);
  });
  
  accountIdInput.on("keyup", function() {
    var id  = videoIdInput.val();
    var accountId  = accountIdInput.val();
    generateUrlFromParams(insightsWidgetUrlParams, baseInsightsUrl, generatedInsightsUrlEl, accountId, id);
    generateUrlFromParams(playerInsightsWidgetUrlParams, basePlayerInsightsUrl, generatedPlayerInsightsUrlEl, accountId , id);
  });
  // Init
  toggleUncheckAll();
  
  // Utils Functions
  function modifyPlayerUrl() {
    var $this = $(this);
    var value = $this.val();
    
    
    if($this.attr("type") === "checkbox") {
      if($this.is(":checked")) {
        playerInsightsWidgetUrlParams[$this.val()] = true;
      } else {
        playerInsightsWidgetUrlParams[$this.val()] = false;
      }
    } 
    if($this.prop("id") === "lang") {
      if(value!=="English") {
        playerInsightsWidgetUrlParams.captions=value;
      } else {
        delete playerInsightsWidgetUrlParams.captions;
      }
    }
    console.log(playerInsightsWidgetUrlParams);
    generateUrlFromParams(playerInsightsWidgetUrlParams, basePlayerInsightsUrl, generatedPlayerInsightsUrlEl , accountIdInput.val() , videoIdInput.val());
  }
  
  function modifyInsightsUrl() {
    var $this = $(this);
    var value = $this.val();
    var title = titleEl.val();
    insightsWidgetUrlParams = {};
    
    if(title) {
      insightsWidgetUrlParams["title"] = title;  
    }
    
    if($this.attr("type") === "checkbox") {
      if($this.is(":checked")) {
        
        widgetsToRender.push(value); 
      } else {
        remove(widgetsToRender, value); 
      }
    }
    
    
    if(widgetsToRender.length) {
      insightsWidgetUrlParams.widgets = widgetsToRender.join(",");
    }
    
    generateUrlFromParams(insightsWidgetUrlParams, baseInsightsUrl, generatedInsightsUrlEl, accountIdInput.val() , videoIdInput.val());
    console.log(insightsWidgetUrlParams);
  }
  
  function toggleUncheckAll(){

    insightsInputs.each(function() {
          if(allWidgets.is(':checked')) {
            delete insightsWidgetUrlParams.widgets;
            widgetsToRender.length = 0;
            if($(this).attr("type") === "checkbox") {
              $(this).prop({"checked": false, "disabled":true});
            }
          } else {
            if($(this).attr("type") === "checkbox") {
               
               $(this).prop({"checked": false, "disabled":false});
            }
          }
    });
    
    generateUrlFromParams(insightsWidgetUrlParams, baseInsightsUrl, generatedInsightsUrlEl, accountIdInput.val(), videoIdInput.val());
  }
  
  function remove(array, element) {
      const index = array.indexOf(element);

      if (index !== -1) {
          array.splice(index, 1);
      }
  }
  
  function generateUrlFromParams(obj, baseUrl, el, accountId , id) {
     var objKeys = Object.keys(obj);
     var urlParams = objKeys.length ? "?" : "";
     for(key in obj) {
       if(obj.hasOwnProperty(key)) {
         urlParams += key + "=" + obj[key];
         if(key !== objKeys[objKeys.length - 1]) {
           urlParams += "&";
         }
       }
     }
    el.val(baseUrl + accountId + "/" + id + "/" + urlParams);
  }
  
}())