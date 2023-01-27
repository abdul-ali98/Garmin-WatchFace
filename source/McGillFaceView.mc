import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
using Toybox.UserProfile;
import Toybox.WatchUi;
using Toybox.ActivityMonitor;
using Toybox.Sensor;
using Toybox.Time;
using Toybox.Position;
using Toybox.Weather;
using Toybox.Time.Gregorian as Date;


class McGillFaceView extends WatchUi.WatchFace {
  private var mcGillImage;
  private var lastHR;
  private var weather_icon_snow;
  private var weather_icon_normal;
  private var weather_icon_worst;
  private var battery_icon_charging;
  private var battery_icon_not_charging;
  var steps_icon;
  private var flip; // for the time label to show/hide the ":"
  private var isSleep;
  var heartLabelView ;
  var lowTemperature;
  var highTemperature;
  
  public function initialize() {
    WatchFace.initialize();

    mcGillImage = Application.loadResource(Rez.Drawables.mcgill_logo);
    weather_icon_snow = Application.loadResource(Rez.Drawables.weather_icon_snow);
    weather_icon_normal = Application.loadResource(Rez.Drawables.weather_icon_normal);
    weather_icon_worst = Application.loadResource(Rez.Drawables.weather_icon_worst);
    steps_icon = Application.loadResource(Rez.Drawables.steps_icon);
    battery_icon_charging = Application.loadResource(Rez.Drawables.battery_icon_charging);
     battery_icon_not_charging = Application.loadResource(Rez.Drawables.battery_icon_not_charging);

    lastHR = "";
    flip = false;
    isSleep = false;
  }

  // Load your resources here
  function onLayout(dc as Dc) as Void {
    setLayout(Rez.Layouts.WatchFace(dc));
  }

  // Called when this View is brought to the foreground. Restore
  // the state of this View and prepare it to be shown. This includes
  // loading resources into memory.
  function onShow() as Void {
    
  }

function onPartialUpdate(dc as Dc) as Void {
  /*   System.println("in onPartialUpdate");		 
     var seconds =  System.getClockTime().sec; */

        if (Activity.getActivityInfo() != null) {
          lastHR = Activity.getActivityInfo().currentHeartRate + "";
        }
        if (lastHR == null || lastHR == 0 || lastHR.equals("null")) {
           lastHR= "...";
        }
        heartLabelView.setText(lastHR); 

    /*    dc.drawArc(dc.getWidth()/2,dc.getWidth()/2 , dc.getWidth()/2, 
    Graphics.ARC_CLOCKWISE , 90 ,  seconds <= 15 ? (90  - (360 / 60)* seconds) : (15 -seconds) * 360/60); */
}
  // Update the view
  function onUpdate(dc as Dc) as Void {
    // Get the current time and format it correctly
   System.println("in onUpdate");
    var timeFormat = "$1$:$2$";
    var clockTime = System.getClockTime();
    var hours = clockTime.hour;
    var seconds = clockTime.sec;
    if (!System.getDeviceSettings().is24Hour) {
      if (hours > 12) {
        hours = hours - 12;
      }
    }
    var hoursString = hours;

    if (hours < 10) {
      hoursString = "0" + hours;
    }
    var minutes = clockTime.min.format("%02d").toLong();
    var minutesString = minutes;
    if (minutes < 10) {
      minutesString = "0" + minutes;
    }
    var timeString = hoursString + (flip || isSleep ? ":" : " ") + minutesString;
    flip = !flip;
    // Update the view
    var view = View.findDrawableById("TimeLabel") as Text;
    view.setColor(/*getApp().getProperty("ForegroundColor") as Number */ Graphics.COLOR_RED);
    view.setText(timeString);
    view.setLocation(
      dc.getWidth() / 2,
      dc.getHeight() / 4 - mcGillImage.getHeight() / 5
    );
    // Call the parent onUpdate function to redraw the layout
    View.onUpdate(dc);

    dc.drawBitmap(dc.getWidth() / 4 + 1, dc.getHeight() / 4, mcGillImage);

    dc.setColor(
      Graphics.COLOR_WHITE, // Using Blue as foreground color
      Graphics.COLOR_TRANSPARENT // Using transparent as background color
    );
        
        var batteryLabelView = View.findDrawableById("batteryLabel") as Text;
        var systemStats = System.getSystemStats();
        var battery = systemStats.battery;
        var batteryString = battery.format("%.0f") +"%";
        batteryLabelView.setText(batteryString);

        if (systemStats.charging) {
              dc.drawBitmap(103, 9, battery_icon_charging);
        } else {
              dc.drawBitmap(106, 12, battery_icon_not_charging);
        }
        
        heartLabelView = View.findDrawableById("heartLabel") as Text;
        if (Activity.getActivityInfo() != null) {
          lastHR = Activity.getActivityInfo().currentHeartRate + "";
        }
        if (lastHR == null || lastHR == 0 || lastHR.equals("null")) {
           lastHR= "...";
        }
        heartLabelView.setText(lastHR); 

  var userActivityIterator = UserProfile.getUserActivityHistory();
  var distance = 0;
  var sample = userActivityIterator.next();
  
   
   var todayTime = new Time.Moment(Time.today().value());
   var todayDate = Date.info(todayTime, Time.FORMAT_SHORT);
   var dayOfWeek = todayDate.day_of_week;
   var oneDay = new Time.Duration(24*60*60);
   var startOfWeek = new Time.Moment(todayTime.value() - (((dayOfWeek - 1) * oneDay.value()) + (todayDate.hour * 60 * 60) + todayDate.min * 60));
   while (sample != null) {
    
    if (sample.distance != null) { 
      if (sample.startTime.value() > startOfWeek.value()) {
        if (sample.type == Activity.SPORT_RUNNING ) {
          distance += sample.distance;
        } 
      } 
   }
        sample = userActivityIterator.next();
   }
    var distanceLabelView = View.findDrawableById("distanceLabel") as Text;
    distanceLabelView.setText( (distance/1000) + " KM");


    drawLines(dc);
    dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT); // Using white as foreground color
    dc.fillCircle(dc.getWidth() / 2, dc.getHeight() / 2, 3.5);
    dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT); // Using white as foreground color
    drawDate(dc, 7, dc.getHeight() / 2);
     dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT); // Using white as foreground color
     if (!isSleep) {
    dc.drawArc(dc.getWidth()/2,dc.getWidth()/2 , dc.getWidth()/2, 
    Graphics.ARC_CLOCKWISE , 90 ,  seconds <= 15 ? (90  - (360 / 60)* seconds) : (15 -seconds) * 360/60);
     }
     

     /******************************** Weather *********************************************************/
     
     dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT); // Using white as foreground color
    
    var dailyForecast = Weather.getDailyForecast();
 //   System.println("Daily Forecast: " + dailyForecast[0].forecastTime.value());
    
    if (dailyForecast == null || dailyForecast.size() < 1 || dailyForecast[0].lowTemperature == null || dailyForecast[0].highTemperature == null) {
      if (lowTemperature != null && highTemperature != null) {
        drawWeather(dc, lowTemperature, highTemperature);
      } 
      else {
        drawWeather(dc, "--", "--");
      }
    } else {
           lowTemperature = dailyForecast[0].lowTemperature;
           highTemperature =dailyForecast[0].highTemperature;

          drawWeather(dc, lowTemperature, highTemperature);
    }
   
      var info = ActivityMonitor.getInfo();
      var steps = info.steps;
      var stepsString = steps +"";
      while(stepsString.length() < 4) {
        stepsString = " " + stepsString;
      }
      dc.drawText(
      180, // The x coordinate
      73, // The y coordinate
      Graphics.FONT_XTINY, // Using the default font with medium size
      stepsString, // The text to draw
      Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER // Justify to center both horizonatally and vertically using bitmap mask
    );
        dc.drawBitmap(210, 70, steps_icon);

 /***********************************************************************************************/

     drawHand(dc, 60, minutes, 0.4 * dc.getWidth(), 4.5);
   // drawHand2(dc, 360/minutes, 4.5, 0.4 * dc.getWidth());
    drawHandOffset(dc, 12.0, 60.0, hours, minutes, 0.3 * dc.getWidth(), 4.5);
  }


function drawWeather(dc, temperature, feelLikeTemperature) {
 if (!temperature.equals("--") && (System.getDeviceSettings().temperatureUnits == System.UNIT_STATUTE)) {
      temperature = (temperature *9/5) + 32;
      feelLikeTemperature = (feelLikeTemperature *9/5) + 32;
     }
     var temperatureString = temperature + "\u00B0";
     var feelLikeTemperatureString = feelLikeTemperature + "\u00B0";
     while (feelLikeTemperatureString.length() < 3) {
      feelLikeTemperatureString = " " + feelLikeTemperatureString;
     }
     while (temperatureString.length() < 3) {
      temperatureString = " " + temperatureString;
     }  

     dc.drawText(
      30, // The x coordinate
      60, // The y coordinate
      Graphics.FONT_XTINY, // Using the default font with medium size
     temperatureString , // The text to draw
      Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER // Justify to center both horizonatally and vertically using bitmap mask
    );
    
    dc.setPenWidth(2);
    dc.drawLine(45 ,78 , 60, 68);
    
     dc.drawText(
      50, // The x coordinate
      83, // The y coordinate
      Graphics.FONT_XTINY, // Using the default font with medium size
     feelLikeTemperatureString, // The text to draw
      Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER // Justify to center both horizonatally and vertically using bitmap mask
    );
  
  if (Weather.getCurrentConditions() != null) {
    var condition = Weather.getCurrentConditions().condition;
    
        switch ( condition ) {
    case Weather.CONDITION_CHANCE_OF_SHOWERS: 
    case Weather.CONDITION_HEAVY_RAIN:
    case Weather.CONDITION_HEAVY_SHOWERS:
    case Weather.CONDITION_HURRICANE:
    case Weather.CONDITION_SANDSTORM:
    case Weather.CONDITION_THUNDERSTORMS:
      dc.drawBitmap(20, 80, weather_icon_worst);
  //    System.println("weather condition is:" + condition);
      break;
    case Weather.CONDITION_CHANCE_OF_SNOW:
    case  Weather.CONDITION_SNOW:
    case Weather.CONDITION_LIGHT_SNOW:
      dc.drawBitmap(20, 80, weather_icon_snow);
  //    System.println("weather condition iss:" + condition);
      break;
    default:
     dc.drawBitmap(20, 80, weather_icon_normal);
  //  System.println("weather condition isss:" + condition);
    break;
}
  } else {
    dc.drawBitmap(20, 80, weather_icon_normal);
  }
}
  // Called when this View is removed from the screen. Save the
  // state of this View here. This includes freeing resources from
  // memory.
  function onHide() as Void {}

  // The user has just looked at their watch. Timers and animations may be started here.
  function onExitSleep() as Void {
    isSleep= false;
  //      System.println("in onExistSleep function");
  }

  // Terminate any active timers and prepare for slow updates.
  function onEnterSleep() as Void {
    isSleep= true;
  //  System.println("in onEnterSleep function");
  }

function drawLines(dc) {
    dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT); // Using white as foreground color
    dc.setPenWidth(1);
    var fontHeight = Graphics.getFontHeight(Graphics.FONT_MEDIUM);
     var center = dc.getWidth() / 2;
    
     dc.drawLine(175, center + fontHeight/2, 250, center + fontHeight/2);
     dc.drawLine(175,  center - fontHeight/2, 250,  center - fontHeight/2);
     dc.drawLine(10, center + fontHeight/2 , 85, center + fontHeight/2);
     dc.drawLine(10, center - fontHeight/2 , 85, center - fontHeight/2);
     
   /*  dc.drawLine(center - 45,center - 45, center - 45, center + 45);
     dc.drawLine(center + 45,center - 45, center + 45, center + 45);
     dc.drawLine(center- 45,center - 45, center + 45, center - 45);
     dc.drawLine(center - 45,center + 45, center + 45, center + 45); */

     drawHandCut(dc, 60 /* 60 */, 6 /* minutes */, 75, 2);
     drawHandCut(dc, 60 /* 60 */, 54 /* minutes */, 75, 2);

      drawHandCut(dc, 60 /* 60 */, 25 /* minutes */, 75, 2);
     drawHandCut(dc, 60 /* 60 */, 35 /* minutes */, 75, 2);
  }
  function drawHandCut(dc, num /* 60 */, time /* minutes */, length, stroke) {
    var angle = Math.toRadians((360 / num) * time) - Math.PI / 2;

    var center = dc.getWidth() / 2;

    dc.setPenWidth(stroke);

    var x1 = center + Math.round(Math.cos(angle) * 45 * Math.sqrt(2));
    var y1 = center + Math.round(Math.sin(angle) * 45 * Math.sqrt(2));
    var x2 = x1 + Math.round(Math.cos(angle) * length);
    var y2 = y1 + Math.round(Math.sin(angle) * length);

    dc.drawLine(x1, y1, x2, y2);
  }

  //! Draw the watch hand
//! @param dc Device Context to Draw
//! @param angle Angle to draw the watch hand
//! @param length Length of the watch hand
//! @param width Width of the watch hand
function drawHand2(dc, angle, length, width)
{
// Map out the coordinates of the watch hand
var coords = [ [-(width/2),0], [-(width/2), -length], [width/2, -length], [width/2, 0] ];
var result = new [4];
var centerX = dc.getWidth() / 2;
var centerY = dc.getHeight() / 2;
var cos = Math.cos(angle);
var sin = Math.sin(angle);

//System.println("coord has:" + coords[0] + "  " + coords[1]);
// Transform the coordinates
for (var i = 0; i < 4; i += 1)
{
var x = (coords[0] * cos) - (coords[1] * sin);
var y = (coords[0] * sin) + (coords[1] * cos);
result= [ centerX+x, centerY+y];
}

// Draw the polygon
dc.fillPolygon(result);
dc.fillPolygon(result);
}
  function drawHand(dc, num /* 60 */, time /* minutes */, length, stroke) {
     dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
    var angle = Math.toRadians((360 / num) * time) - Math.PI / 2;

    var center = dc.getWidth() / 2;

    dc.setPenWidth(stroke);

    var x = center + Math.round(Math.cos(angle) * length);
    var y = center + Math.round(Math.sin(angle) * length);

    dc.drawLine(center, center, x, y);
  }

  /**
    For Hours, i.e if the time is 9:30, we need the hour hand to be in between 9 and 10
    */
  function drawHandOffset(dc, num, offsetNum, time, offsetTime, length, stroke) {
     dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
    var angle = Math.toRadians((360 / num) * time) - Math.PI / 2;
    var section = 360.0 / num / offsetNum;

    angle += Math.toRadians(section * offsetTime);

    var center = dc.getWidth() / 2;

    dc.setPenWidth(stroke);

    var x = center + Math.round(Math.cos(angle) * length);
    var y = center + Math.round(Math.sin(angle) * length);

    dc.drawLine(center, center, x, y);
  }

  function drawDate(dc, x, y) {
    // Get the current time
    var now = Time.now();
    // Extract the date info, the strings will be localized
    var date = Date.info(now, Time.FORMAT_MEDIUM); // Extract the date info
    // Format the date into "ddd D", for instance: "Tue  6"
    var dateString = Lang.format("$1$ $2$", [date.day_of_week, date.day]);

    dc.drawText(
    x, // The x coordinate
    y, // The y coordinate
    Graphics.FONT_SMALL, // Using the default font with medium size
    dateString , // The text to draw
    Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER // Justify to center both horizonatally and vertically using bitmap mask
    );
   }

    function drawTextBox(dc, text, x, y, width, height) {
		dc.setPenWidth(2);
    	
		var boxText = new WatchUi.Text({
            :text=>text,
            :color=>Graphics.COLOR_GREEN,
            :font=>Graphics.FONT_SMALL,
            :locX =>x ,
            :locY=>y,
			:justification=>Graphics.TEXT_JUSTIFY_LEFT
        });

		boxText.draw(dc);
	}

}
//! Receives watch face events
class McGillDelegate extends WatchUi.WatchFaceDelegate {
    private var _view as McGillFaceView;

    //! Constructor
    //! @param view The analog view
    public function initialize(view as McGillFaceView) {
        WatchFaceDelegate.initialize();
        _view = view;
    }

    //! @param powerInfo Information about the power budget
    public function onPowerBudgetExceeded(powerInfo as WatchFacePowerInfo) as Void {
   //     System.println("Average execution time: " + powerInfo.executionTimeAverage);
   //     System.println("Allowed execution time: " + powerInfo.executionTimeLimit);
   //     _view.turnPartialUpdatesOff();
    }
}